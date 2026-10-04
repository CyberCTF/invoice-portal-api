output "ssh_user" {
  value = "cyberctf"
}

output "instance_id" {
  value = google_compute_instance.labhost.id
}

output "auto_stop_hours" {
  value = var.auto_stop_hours
}

output "ip" {
  value = google_compute_address.labhost.address
}

# Where the bootstrap reports "running: <step>", "ready" or "failed: <step>"; the
# launcher waits on it over SSH after apply.
output "ready_file" {
  value = "/var/lib/cyberctf/status"
}
