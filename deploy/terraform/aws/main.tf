# Lab host on AWS (cloud target): one Debian 12 EC2 instance in a small VPC of its own
# (so it works in accounts without a default VPC, and the intentionally vulnerable lab
# sits apart from anything else in the account). cloud-init fetches the lab and runs
# deploy/ansible/site.yml. Lab services are not exposed: they live on the Docker network
# inside the instance, reached from the attack box running next to them. Only SSH is
# open, and only from allowed_cidr.

terraform {
  required_version = ">= 1.6"
  # The launcher keeps state outside the lab folder: -backend-config=path=...
  backend "local" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "cyberctf:lab" = var.lab_slug
      "managed-by"   = "cyberctf"
    }
  }
}

# A short random id per deployment, stable across re-applies, so two deployments of the
# same lab in one account (two machines, two players) never collide on names.
resource "terraform_data" "deployment" {
  input = substr(replace(uuid(), "-", ""), 0, 8)
  lifecycle {
    ignore_changes = [input]
  }
}

locals {
  name = "cyberctf-${var.lab_slug}-${terraform_data.deployment.output}"
  # Sizing the lab asks for in .ctf/metadata.json ("resources"), when the lab ships it.
  resources = try(jsondecode(file("${path.module}/../../../.ctf/metadata.json")).resources, {})
  memory_mb = try(local.resources.memory_mb, 4096)
  instance_type = coalesce(
    var.instance_type,
    local.memory_mb <= 4096 ? "t3.medium" : local.memory_mb <= 8192 ? "t3.large" : "t3.xlarge",
  )
  disk_gb = coalesce(var.disk_gb, try(local.resources.disk_gb, null), 20)
}

# The first zone of the region that offers the instance type.
data "aws_ec2_instance_type_offerings" "zones" {
  location_type = "availability-zone"
  filter {
    name   = "instance-type"
    values = [local.instance_type]
  }
}

resource "aws_vpc" "lab" {
  cidr_block           = "10.42.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = local.name
  }
}

resource "aws_internet_gateway" "lab" {
  vpc_id = aws_vpc.lab.id
  tags = {
    Name = local.name
  }
}

resource "aws_subnet" "lab" {
  vpc_id                  = aws_vpc.lab.id
  cidr_block              = "10.42.1.0/24"
  availability_zone       = sort(data.aws_ec2_instance_type_offerings.zones.locations)[0]
  map_public_ip_on_launch = true
  tags = {
    Name = local.name
  }
}

resource "aws_route_table" "lab" {
  vpc_id = aws_vpc.lab.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab.id
  }
  tags = {
    Name = local.name
  }
}

resource "aws_route_table_association" "lab" {
  subnet_id      = aws_subnet.lab.id
  route_table_id = aws_route_table.lab.id
}

# Debian's official account.
data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"]
  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_key_pair" "player" {
  count      = var.ssh_public_key == "" ? 0 : 1
  key_name   = local.name
  public_key = var.ssh_public_key
}

resource "aws_security_group" "labhost" {
  name        = local.name
  description = "CyberCTF lab host ${var.lab_slug}"
  vpc_id      = aws_vpc.lab.id

  dynamic "ingress" {
    for_each = var.allowed_cidr == "" ? [] : [var.allowed_cidr]
    content {
      description = "SSH from the player"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "labhost" {
  ami                    = data.aws_ami.debian.id
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.lab.id
  key_name               = var.ssh_public_key == "" ? null : aws_key_pair.player[0].key_name
  vpc_security_group_ids = [aws_security_group.labhost.id]

  user_data = templatefile("${path.module}/../../cloud-init/user-data.yaml.tftpl", {
    lab_repository    = var.lab_repository
    lab_commit        = var.lab_commit
    ctf_api_url       = var.ctf_api_url
    ctf_launch_token  = var.ctf_launch_token
    attackbox_image   = var.attackbox_image
    ssh_public_key    = var.ssh_public_key
    auto_stop_minutes = var.auto_stop_hours * 60
  })
  # A new launch token means a new instance (cloud-init only runs on first boot).
  user_data_replace_on_change = true
  # Auto-stop powers the instance off; terminate rather than keep a stopped instance.
  instance_initiated_shutdown_behavior = "terminate"

  root_block_device {
    volume_size = local.disk_gb
    volume_type = "gp3"
    encrypted   = true
  }

  # IMDSv2 only, one hop: containers (the lab, the attack box) can't reach the metadata
  # service, so an SSRF lab can't be turned on the instance itself.
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  # The public route must exist before cloud-init starts downloading.
  depends_on = [aws_route_table_association.lab]

  tags = {
    Name = local.name
  }
}
