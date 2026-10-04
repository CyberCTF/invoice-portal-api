# Credentials come from the standard AWS environment (AWS_ACCESS_KEY_ID /
# AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN or AWS_PROFILE), never from variables.
variable "region" {
  type    = string
  default = "eu-west-3"
}
variable "instance_type" {
  type        = string
  default     = null
  description = "Empty = sized from the lab's resources (t3.medium up to 4 GB, t3.large up to 8 GB, else t3.xlarge)"
}
variable "disk_gb" {
  type        = number
  default     = null
  description = "Empty = the lab's resources.disk_gb, else 20"
}
variable "auto_stop_hours" {
  type        = number
  default     = 4
  description = "Terminate the instance this many hours after boot (0 = never)"
  validation {
    condition     = var.auto_stop_hours >= 0 && var.auto_stop_hours <= 72
    error_message = "auto_stop_hours must be between 0 and 72."
  }
}
variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "Public key for SSH into the lab host (empty = no key pair)"
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
