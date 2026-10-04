# Lab host on Linode (cloud target): one Debian 12 Linode, reached only over SSH from
# allowed_cidr (a cloud firewall; Linode has no per-lab VPC we need here). cloud-init runs from
# the instance metadata user_data: it fetches the lab and runs deploy/ansible/site.yml, the same
# bootstrap as the other cloud targets. Lab services live on the Docker network inside the VM.
#
# Credentials: a Linode API token. The provider reads it from LINODE_TOKEN, which the launcher
# sets from the token stored in the OS keychain.
#
# Auto-stop note: cloud-init powers the Linode off after auto_stop_hours, but Linode keeps billing
# a powered-off instance until it is DELETED. The launcher's timed `terraform destroy` (and Stop)
# removes everything and is the reliable way to end billing.

terraform {
  required_version = ">= 1.6"
  # The launcher keeps state outside the lab folder: -backend-config=path=...
  backend "local" {}
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# The provider reads the API token from LINODE_TOKEN (set by the launcher).
provider "linode" {}

# A short random id per deployment, stable across re-applies, so two deployments of the same lab
# never collide on names.
resource "terraform_data" "deployment" {
  input = substr(replace(uuid(), "-", ""), 0, 8)
  lifecycle {
    ignore_changes = [input]
  }
}

# Linode requires a root password even when SSH keys are used; a random one is fine since login
# is key-only over SSH.
resource "random_password" "root" {
  length  = 24
  special = true
}

locals {
  name = "cyberctf-${var.lab_slug}-${terraform_data.deployment.output}"
  # Sizing the lab asks for in .ctf/metadata.json ("resources"), when the lab ships it.
  resources = try(jsondecode(file("${path.module}/../../../.ctf/metadata.json")).resources, {})
  memory_mb = try(local.resources.memory_mb, 4096)
  type = coalesce(
    var.instance_type,
    local.memory_mb <= 4096 ? "g6-standard-2" : local.memory_mb <= 8192 ? "g6-standard-4" : "g6-standard-6",
  )
  tags = ["cyberctf"]
}

resource "linode_instance" "labhost" {
  label           = local.name
  region          = var.region
  type            = local.type
  image           = "linode/debian12"
  root_pass       = random_password.root.result
  authorized_keys = var.ssh_public_key != "" ? [trimspace(var.ssh_public_key)] : []
  tags            = local.tags

  metadata {
    user_data = base64encode(templatefile("${path.module}/../../cloud-init/user-data.yaml.tftpl", {
      lab_repository    = var.lab_repository
      lab_commit        = var.lab_commit
      ctf_api_url       = var.ctf_api_url
      ctf_launch_token  = var.ctf_launch_token
      attackbox_image   = var.attackbox_image
      ssh_public_key    = var.ssh_public_key
      auto_stop_minutes = var.auto_stop_hours * 60
    }))
  }
}

# Only SSH, only from the player. Egress is open so the lab can fetch its images.
resource "linode_firewall" "lab" {
  count           = var.allowed_cidr == "" ? 0 : 1
  label           = substr(local.name, 0, 32)
  linodes         = [linode_instance.labhost.id]
  inbound_policy  = "DROP"
  outbound_policy = "ACCEPT"

  inbound {
    label    = "ssh"
    action   = "ACCEPT"
    protocol = "TCP"
    ports    = "22"
    ipv4     = [var.allowed_cidr]
  }
}
