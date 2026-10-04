output "ssh_user" {
  value = "debian"
}

output "vm_id" {
  value = proxmox_virtual_environment_vm.labhost.vm_id
}

# First non-loopback IPv4 reported by the guest agent.
output "ip" {
  value = try([for ip in flatten(proxmox_virtual_environment_vm.labhost.ipv4_addresses) : ip if ip != "127.0.0.1"][0], null)
}

# Where the bootstrap reports "running: <step>", "ready" or "failed: <step>"; the
# launcher waits on it over SSH after apply.
output "ready_file" {
  value = "/var/lib/cyberctf/status"
}
