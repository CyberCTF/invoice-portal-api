# Connection (from the launcher's server profile).
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
  type        = bool
  default     = false
  description = "Accept a self-signed API certificate"
}
variable "proxmox_ssh_address" {
  type        = string
  default     = ""
  description = "Node address for SSH (snippet upload); empty = the address the node reports"
}
variable "proxmox_node" {
  type    = string
  default = "pve"
}
variable "proxmox_storage" {
  type        = string
  default     = "local-lvm"
  description = "Storage for the VM disk"
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
variable "proxmox_bridge" {
  type    = string
  default = "vmbr0"
}

# The lab (from the launch spec).
variable "lab_slug" {
  type = string
}
variable "lab_repository" {
  type        = string
  description = "GitHub owner/name"
}
variable "lab_commit" {
  type = string
}
variable "ctf_api_url" {
  type    = string
  default = ""
}
variable "ctf_launch_token" {
  type      = string
  default   = ""
  sensitive = true
}
variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Public key allowed to SSH in as the image's default user (debian)"
}
variable "attackbox_image" {
  type    = string
  default = ""
}

# Size.
variable "cpu_type" {
  type        = string
  default     = "host"
  description = "host = fastest (needs KVM); x86-64-v2-AES for mixed-CPU clusters. Lab images need at least x86-64-v2."
}
# Size: empty = the lab's .ctf/metadata.json "resources", else 2 cores / 4096 MB / 20 GB.
variable "cores" {
  type    = number
  default = null
}
variable "memory_mb" {
  type    = number
  default = null
}
variable "disk_gb" {
  type    = number
  default = null
}
