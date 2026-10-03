# Lab host on AWS (cloud target): one Debian 12 EC2 instance in the default VPC.
# cloud-init fetches the lab and runs deploy/ansible/site.yml. Lab services are not
# exposed: they live on the Docker network inside the instance, reached from the attack
# box running next to them. Only SSH is open, and only from allowed_cidr.

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

locals {
  name = "cyberctf-${var.lab_slug}"
}

data "aws_vpc" "default" {
  default = true
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
  vpc_id      = data.aws_vpc.default.id

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
  instance_type          = var.instance_type
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
    volume_size = var.disk_gb
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  tags = {
    Name = local.name
  }
}
