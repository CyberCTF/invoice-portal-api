# Credentials come from the gcloud CLI (`gcloud auth application-default login`) and the
# project in GOOGLE_PROJECT, never from variables.
variable "region" {
  type        = string
  default     = "europe-west1"
  description = "GCP region. The lab host lands in its `-b` zone."
}
variable "instance_type" {
  type        = string
  default     = null
  description = "GCP machine type. Empty = sized from the lab's resources (e2-medium up to 4 GB, e2-standard-2 up to 8 GB, else e2-standard-4)."
}
variable "disk_gb" {
  type        = number
  default     = null
  description = "Empty = the lab's resources.disk_gb, else 30"
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
  description = "Public key for SSH into the lab host"
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
