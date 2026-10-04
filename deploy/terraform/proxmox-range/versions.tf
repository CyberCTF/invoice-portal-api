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
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = var.proxmox_insecure
  ssh {
    agent    = false
    username = split("@", var.proxmox_username)[0]
    password = var.proxmox_password
    dynamic "node" {
      for_each = var.proxmox_ssh_address == "" ? [] : [var.proxmox_ssh_address]
      content {
        name    = var.proxmox_node
        address = node.value
      }
    }
  }
}
