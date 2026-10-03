# Lab host on the player's Proxmox VE (home lab), with the bpg/proxmox provider.
# A Debian 12 cloud image VM; cloud-init fetches the lab and runs deploy/ansible/site.yml.
# The launcher runs this in the hashicorp/terraform container with TF_VAR_* set.

terraform {
  required_version = ">= 1.6"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.115"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
  # Uploading the cloud-init snippet goes over SSH to the node.
  ssh {
    agent    = false
    username = split("@", var.proxmox_username)[0]
    password = var.proxmox_password
  }
}

locals {
  name = "cyberctf-${var.lab_slug}"
}

resource "proxmox_download_file" "debian" {
  node_name           = var.proxmox_node
  datastore_id        = var.proxmox_image_storage
  content_type        = "iso"
  url                 = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  file_name           = "cyberctf-debian-12-genericcloud-amd64.img"
  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_file" "user_data" {
  node_name    = var.proxmox_node
  datastore_id = var.proxmox_snippet_storage
  content_type = "snippets"
  source_raw {
    file_name = "${local.name}-user-data.yaml"
    data = templatefile("${path.module}/../../cloud-init/user-data.yaml.tftpl", {
      lab_repository   = var.lab_repository
      lab_commit       = var.lab_commit
      ctf_api_url      = var.ctf_api_url
      ctf_launch_token = var.ctf_launch_token
      attackbox_image  = var.attackbox_image
    })
  }
}

resource "proxmox_virtual_environment_vm" "labhost" {
  name      = local.name
  node_name = var.proxmox_node
  tags      = ["cyberctf", var.lab_slug]
  on_boot   = false

  agent {
    enabled = true
  }
  cpu {
    cores = var.cores
    type  = "host"
  }
  memory {
    dedicated = var.memory_mb
  }
  disk {
    datastore_id = var.proxmox_storage
    file_id      = proxmox_download_file.debian.id
    interface    = "virtio0"
    size         = var.disk_gb
    discard      = "on"
  }
  network_device {
    bridge = var.proxmox_bridge
  }
  operating_system {
    type = "l26"
  }
  serial_device {}
  initialization {
    datastore_id      = var.proxmox_storage
    user_data_file_id = proxmox_virtual_environment_file.user_data.id
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}
