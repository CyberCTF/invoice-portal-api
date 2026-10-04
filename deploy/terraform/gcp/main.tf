# Lab host on Google Cloud (cloud target): one Debian 12 VM in a network of its own, reached
# only over SSH from allowed_cidr. cloud-init (the GCE datasource reads the `user-data`
# metadata key) fetches the lab and runs deploy/ansible/site.yml, the same bootstrap as the
# AWS and Azure targets. Lab services live on the Docker network inside the VM, reached from
# the attack box next to them; only SSH is open.
#
# Credentials: the gcloud CLI's application-default login plus a project. The google provider
# reads the project from GOOGLE_PROJECT (the launcher sets it) and the credentials from the
# gcloud ADC file, so nothing secret lives in a variable.
#
# Auto-stop note: cloud-init powers the OS off after auto_stop_hours. A TERMINATED GCE instance
# stops compute billing (unlike Azure), but its disk and static IP still bill a little until
# Stop (terraform destroy) removes everything, which is the reliable way to end all billing.

terraform {
  required_version = ">= 1.6"
  # The launcher keeps state outside the lab folder: -backend-config=path=...
  backend "local" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  # project comes from GOOGLE_PROJECT; credentials from gcloud application-default login.
  region = var.region
  zone   = "${var.region}-b"
}

# A short random id per deployment, stable across re-applies, so two deployments of the same
# lab in one project never collide on names.
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
  machine_type = coalesce(
    var.instance_type,
    local.memory_mb <= 4096 ? "e2-medium" : local.memory_mb <= 8192 ? "e2-standard-2" : "e2-standard-4",
  )
  disk_gb = coalesce(var.disk_gb, try(local.resources.disk_gb, null), 30)
  labels = {
    "cyberctf-lab" = var.lab_slug
    "managed-by"   = "cyberctf"
  }
}

resource "google_compute_network" "lab" {
  name                    = local.name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "lab" {
  name          = local.name
  network       = google_compute_network.lab.id
  region        = var.region
  ip_cidr_range = "10.42.1.0/24"
}

# Only SSH, only from the player. Egress to the internet is allowed by GCP's default; the lab
# needs it to fetch images.
resource "google_compute_firewall" "ssh" {
  count         = var.allowed_cidr == "" ? 0 : 1
  name          = "${local.name}-ssh"
  network       = google_compute_network.lab.id
  direction     = "INGRESS"
  source_ranges = [var.allowed_cidr]
  target_tags   = ["cyberctf"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_address" "labhost" {
  name   = local.name
  region = var.region
}

resource "google_compute_instance" "labhost" {
  name         = local.name
  machine_type = local.machine_type
  zone         = "${var.region}-b"
  tags         = ["cyberctf"]
  labels       = local.labels

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = local.disk_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.lab.id
    access_config {
      nat_ip = google_compute_address.labhost.address
    }
  }

  metadata = {
    ssh-keys = "cyberctf:${var.ssh_public_key}"
    user-data = templatefile("${path.module}/../../cloud-init/user-data.yaml.tftpl", {
      lab_repository    = var.lab_repository
      lab_commit        = var.lab_commit
      ctf_api_url       = var.ctf_api_url
      ctf_launch_token  = var.ctf_launch_token
      attackbox_image   = var.attackbox_image
      ssh_public_key    = var.ssh_public_key
      auto_stop_minutes = var.auto_stop_hours * 60
    })
  }
}
