# The router's WAN address, for "Open shell" (ssh to the router, then into the range). First
# non-loopback IPv4 the guest agent reports.
output "ip" {
  value = try([for ip in flatten(proxmox_virtual_environment_vm.router.ipv4_addresses) : ip if ip != "127.0.0.1" && !startswith(ip, "10.${var.range_number}.")][0], null)
}

output "ssh_user" {
  value = "debian"
}

output "range_number" {
  value = var.range_number
}

output "vms" {
  value = { for name, vm in proxmox_virtual_environment_vm.lab : name => vm.vm_id }
}
