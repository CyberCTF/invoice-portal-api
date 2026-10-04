output "ssh_user" {
  value = "root"
}

output "instance_id" {
  value = linode_instance.labhost.id
}

output "auto_stop_hours" {
  value = var.auto_stop_hours
}

output "ip" {
  # A default Linode has one public IPv4; ipv4 is a set, so convert before indexing.
  value = tolist(linode_instance.labhost.ipv4)[0]
}

# Where the bootstrap reports "running: <step>", "ready" or "failed: <step>"; the
# launcher waits on it over SSH after apply.
output "ready_file" {
  value = "/var/lib/cyberctf/status"
}
