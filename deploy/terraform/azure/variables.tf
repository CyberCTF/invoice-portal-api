# Credentials come from the Azure CLI (`az login`) / the standard ARM_* environment, never
# from variables. The subscription is the CLI's default or ARM_SUBSCRIPTION_ID.
variable "region" {
  type        = string
  default     = "westeurope"
  description = "Azure location (kept named `region` to match the launcher's contract)."
}
variable "instance_type" {
  type        = string
  default     = null
  description = "Azure VM size. Empty = sized from the lab's resources (B2s up to 4 GB, B2ms up to 8 GB, else B4ms)."
}
variable "disk_gb" {
  type        = number
  default     = null
  description = "Empty = the lab's resources.disk_gb, else 20"
}
variable "auto_stop_hours" {
  type        = number
  default     = 4
  description = "Power the VM off this many hours after boot (0 = never)"
  validation {
    condition     = var.auto_stop_hours >= 0 && var.auto_stop_hours <= 72
    error_message = "auto_stop_hours must be between 0 and 72."
  }
}
variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Public key for SSH into the lab host (Azure Linux VMs require one)"
}
variable "allowed_cidr" {
  type        = string
  default     = ""
  description = "CIDR allowed to SSH in, e.g. the player's public IP/32 (empty = no SSH)"
}

# The lab (from the launch spec).
variable "lab_slug" {
  type = string
}
variable "lab_repository" {
  type = string
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
variable "attackbox_image" {
  type    = string
  default = ""
}
