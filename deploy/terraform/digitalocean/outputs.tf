output "ssh_user" {
  value = "root"
}

output "instance_id" {
  value = digitalocean_droplet.labhost.id
}

output "auto_stop_hours" {
  value = var.auto_stop_hours
}

output "ip" {
  value = digitalocean_droplet.labhost.ipv4_address
}

# Where the bootstrap reports "running: <step>", "ready" or "failed: <step>"; the
# launcher waits on it over SSH after apply.
output "ready_file" {
  value = "/var/lib/cyberctf/status"
}
