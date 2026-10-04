# The API token comes from LINODE_TOKEN (set by the launcher from the keychain), never from a
# variable.
variable "region" {
  type        = string
  default     = "eu-central"
  description = "Linode region slug, e.g. eu-central, us-east, ap-south."
}
variable "instance_type" {
  type        = string
  default     = null
  description = "Linode type. Empty = sized from the lab's resources (g6-standard-2 up to 4 GB, g6-standard-4 up to 8 GB, else g6-standard-6)."
}
variable "auto_stop_hours" {
  type        = number
  default     = 4
  description = "Power the Linode off this many hours after boot (0 = never)"
  validation {
    condition     = var.auto_stop_hours >= 0 && var.auto_stop_hours <= 72
    error_message = "auto_stop_hours must be between 0 and 72."
  }
}
variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Public key for SSH into the lab host (added to the Linode)"
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
