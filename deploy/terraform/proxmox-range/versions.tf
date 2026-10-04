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
