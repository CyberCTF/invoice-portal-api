output "ssh_user" {
  value = "cyberctf"
}

output "instance_id" {
  value = azurerm_linux_virtual_machine.labhost.id
}

output "auto_stop_hours" {
  value = var.auto_stop_hours
}

output "ip" {
  value = azurerm_public_ip.labhost.ip_address
}

# Where the bootstrap reports "running: <step>", "ready" or "failed: <step>"; the
# launcher waits on it over SSH after apply.
output "ready_file" {
  value = "/var/lib/cyberctf/status"
}
