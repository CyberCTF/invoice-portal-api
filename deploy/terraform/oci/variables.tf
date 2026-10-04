# Credentials come from ~/.oci/config (DEFAULT profile, API signing key), never from variables.
variable "region" {
  type        = string
  default     = "eu-frankfurt-1"
  description = "OCI region id, e.g. eu-frankfurt-1, us-ashburn-1."
}
variable "compartment_ocid" {
  type        = string
  description = "Compartment OCID to create the lab in (the tenancy root OCID works)."
}
variable "instance_type" {
  type        = string
  default     = "VM.Standard.E4.Flex"
  description = "OCI shape (a Flex shape; OCPUs/memory are sized from the lab's resources)."
}
variable "auto_stop_hours" {
  type        = number
  default     = 4
  description = "Power the instance off this many hours after boot (0 = never)"
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
