# Lab host on the player's Proxmox VE (server), with the bpg/proxmox provider.
# A Debian 12 cloud image VM; cloud-init fetches the lab and runs deploy/ansible/site.yml.
# The launcher runs this in the hashicorp/terraform container with TF_VAR_* set.

terraform {
  required_version = ">= 1.6"
  # The launcher keeps state outside the lab folder: -backend-config=path=...
  backend "local" {}
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.115"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_endpoint
  # An API token (user@realm!name=secret) when given, else user + password.
  api_token = var.proxmox_api_token != "" ? var.proxmox_api_token : null
  username  = var.proxmox_api_token != "" ? null : var.proxmox_username
  password  = var.proxmox_api_token != "" ? null : var.proxmox_password
  insecure  = var.proxmox_insecure
  # Uploading the cloud-init snippet goes over SSH to the node (the API can't upload
  # snippets): with a private key when given (token setups), else the password.
  ssh {
    agent       = false
    username    = coalesce(var.proxmox_ssh_username, split("@", var.proxmox_username)[0])
    password    = var.proxmox_ssh_private_key_file != "" ? null : var.proxmox_password
    private_key = var.proxmox_ssh_private_key_file != "" ? file(var.proxmox_ssh_private_key_file) : null
    # Reach the node at the address the player entered, not the one it reports.
    dynamic "node" {
      for_each = var.proxmox_ssh_address == "" ? [] : [var.proxmox_ssh_address]
      content {
        name    = var.proxmox_node
        address = node.value
      }
    }
  }
}

# A short random id per deployment, stable across re-applies, so two deployments of the
# same lab on one node never collide (VM name, snippet, image file).
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
  cores     = coalesce(var.cores, try(local.resources.cpus, null), 2)
  memory_mb = coalesce(var.memory_mb, try(local.resources.memory_mb, null), 4096)
  disk_gb   = coalesce(var.disk_gb, try(local.resources.disk_gb, null), 20)

  stores      = { for d in data.proxmox_datastores.node.datastores : d.id => d.content_types }
  image_ok    = contains(try(local.stores[var.proxmox_image_storage], []), "iso")
  snippets_ok = contains(try(local.stores[var.proxmox_snippet_storage], []), "snippets")
  enable_hint = "In the Proxmox web UI: Datacenter > Storage > select it > Edit > Content"
}

# What each storage on the node accepts, to fail early with a fix instead of mid-upload.
data "proxmox_datastores" "node" {
  node_name = var.proxmox_node
}

resource "proxmox_download_file" "debian" {
  node_name    = var.proxmox_node
  datastore_id = var.proxmox_image_storage
  content_type = "iso"
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  # Per deployment: a shared file would be deleted by whichever lab is destroyed first,
  # and two launches at once would race on it.
  file_name           = "${local.name}-debian-12-amd64.img"
  overwrite           = false
  overwrite_unmanaged = true
  upload_timeout      = 1800

  lifecycle {
    precondition {
      condition     = local.image_ok
      error_message = "Storage '${var.proxmox_image_storage}' on ${var.proxmox_node} doesn't accept ISO images. ${local.enable_hint}, add 'ISO image'."
    }
  }
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
      ssh_public_key   = var.ssh_public_key
      # Your own hardware: no time limit.
      auto_stop_minutes = 0
    })
  }

  lifecycle {
    precondition {
      condition     = local.snippets_ok
      error_message = "Storage '${var.proxmox_snippet_storage}' on ${var.proxmox_node} doesn't accept snippets, which carry the lab host's cloud-init. ${local.enable_hint}, add 'Snippets'."
    }
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
    cores = local.cores
    type  = var.cpu_type
  }
  memory {
    dedicated = local.memory_mb
  }
  disk {
    datastore_id = var.proxmox_storage
    file_id      = proxmox_download_file.debian.id
    interface    = "virtio0"
    size         = local.disk_gb
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
