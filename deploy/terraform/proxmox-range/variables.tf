# Connection (from the launcher's server profile), same as deploy/terraform/proxmox.
variable "proxmox_endpoint" {
  type        = string
  description = "https://<host>:8006/"
}
variable "proxmox_username" {
  type        = string
  description = "user@realm, e.g. root@pam"
}
variable "proxmox_password" {
  type      = string
  sensitive = true
}
variable "proxmox_insecure" {
  type    = bool
  default = false
}
variable "proxmox_ssh_address" {
  type    = string
  default = ""
}
variable "proxmox_node" {
  type    = string
  default = "pve"
}
variable "proxmox_storage" {
  type        = string
  default     = "local-lvm"
  description = "Storage for VM disks"
}
variable "proxmox_image_storage" {
  type        = string
  default     = "local"
  description = "Storage with 'iso' content for the Debian cloud image"
}
variable "proxmox_snippet_storage" {
  type        = string
  default     = "local"
  description = "Storage with 'snippets' content for cloud-init"
}
variable "proxmox_uplink_bridge" {
  type        = string
  default     = "vmbr0"
  description = "The node bridge the router's WAN attaches to (reaches the LAN / internet)"
}

# The range.
variable "range_number" {
  type        = number
  description = "1..=250, unique per running range on the host; sets 10.<n>.x and the SDN zone"
  validation {
    condition     = var.range_number >= 1 && var.range_number <= 250
    error_message = "range_number must be between 1 and 250."
  }
}
variable "lab_slug" {
  type = string
}
variable "lab_repository" {
  type        = string
  description = "GitHub owner/name (the router fetches the lab from here)"
}
variable "lab_commit" {
  type = string
}

# The VMs, from deploy/range.yaml (the launcher resolves templates to Proxmox template ids).
variable "vms" {
  type = list(object({
    name          = string
    hostname      = string
    template_id   = number # a Proxmox template VMID to linked-clone
    vlan          = number
    ip_last_octet = number
    cpus          = optional(number, 2)
    ram_gb        = optional(number, 4)
    os            = optional(string, "linux") # linux | windows
  }))
}

variable "attacker_vlan" {
  type        = number
  default     = 99
  description = "VLAN the attack box sits on (for the default router rules)"
}

# Evidence claim + attack box, as for single-VM labs.
variable "ctf_api_url" {
  type    = string
  default = ""
}
variable "ctf_launch_token" {
  type      = string
  default   = ""
  sensitive = true
}
variable "attackbox_image" {
  type    = string
  default = ""
}
variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Public key installed on the router for 'Open shell'"
}
