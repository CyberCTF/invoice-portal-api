output "ssh_user" {
  value = "ubuntu"
}

output "instance_id" {
  value = oci_core_instance.labhost.id
}

output "auto_stop_hours" {
  value = var.auto_stop_hours
}

output "ip" {
  value = oci_core_instance.labhost.public_ip
}

# Where the bootstrap reports "running: <step>", "ready" or "failed: <step>"; the
# launcher waits on it over SSH after apply.
output "ready_file" {
  value = "/var/lib/cyberctf/status"
}
