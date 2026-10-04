# Lab host on DigitalOcean (cloud target): one Debian 12 droplet in a VPC of its own, reached
# only over SSH from allowed_cidr. cloud-init (DO droplets read user_data) fetches the lab and
# runs deploy/ansible/site.yml, the same bootstrap as the other cloud targets. Lab services live
# on the Docker network inside the droplet, reached from the attack box; only SSH is open.
#
# Credentials: a DigitalOcean API token. The provider reads it from DIGITALOCEAN_TOKEN, which the
# launcher sets from the token stored in the OS keychain.
#
# Auto-stop note: cloud-init powers the droplet off after auto_stop_hours, but DigitalOcean keeps
# billing a powered-off droplet until it is DESTROYED. The launcher's timed `terraform destroy`
# (and Stop) removes everything and is the reliable way to end billing.

terraform {
  required_version = ">= 1.6"
  # The launcher keeps state outside the lab folder: -backend-config=path=...
  backend "local" {}
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

# The provider reads the API token from DIGITALOCEAN_TOKEN (set by the launcher).
provider "digitalocean" {}

# A short random id per deployment, stable across re-applies, so two deployments of the same lab
# never collide on names.
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
  size = coalesce(
    var.instance_type,
    local.memory_mb <= 4096 ? "s-2vcpu-4gb" : local.memory_mb <= 8192 ? "s-2vcpu-8gb" : "s-4vcpu-16gb",
  )
  tags = ["cyberctf"]
}

# The launcher's SSH key, so "Open shell" can reach the droplet (root).
resource "digitalocean_ssh_key" "lab" {
  name       = local.name
  public_key = var.ssh_public_key
}

# A VPC of its own, so the lab is isolated from other droplets in the account.
resource "digitalocean_vpc" "lab" {
  name     = local.name
  region   = var.region
  ip_range = "10.42.1.0/24"
}

resource "digitalocean_droplet" "labhost" {
  name     = local.name
  region   = var.region
  size     = local.size
  image    = "debian-12-x64"
  vpc_uuid = digitalocean_vpc.lab.id
  ssh_keys = [digitalocean_ssh_key.lab.fingerprint]
  tags     = local.tags
  user_data = templatefile("${path.module}/../../cloud-init/user-data.yaml.tftpl", {
    lab_repository    = var.lab_repository
    lab_commit        = var.lab_commit
    ctf_api_url       = var.ctf_api_url
    ctf_launch_token  = var.ctf_launch_token
    attackbox_image   = var.attackbox_image
    ssh_public_key    = var.ssh_public_key
    auto_stop_minutes = var.auto_stop_hours * 60
  })
}

# Only SSH, only from the player. Egress is open so the lab can fetch its images.
resource "digitalocean_firewall" "lab" {
  count       = var.allowed_cidr == "" ? 0 : 1
  name        = local.name
  droplet_ids = [digitalocean_droplet.labhost.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.allowed_cidr]
  }
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}
