# The lab VMs: a linked clone of each template, on its VLAN VNet, with a static IP
# (10.<range>.<vlan>.<ip_last_octet>) and the router as gateway/DNS. Linux VMs get their IP
# from cloud-init; Windows template provisioning (sysprep, static IP, domain) is a later
# layer run from the router, so Windows VMs here just boot on the right VNet.

resource "proxmox_virtual_environment_vm" "lab" {
  for_each = { for vm in var.vms : vm.name => vm }

  name      = "ctf${var.range_number}-${each.value.name}"
  node_name = var.proxmox_node
  tags      = ["cyberctf", var.lab_slug]
  on_boot   = false

  # IPs are discovered from the router's DHCP leases, so don't block apply on the agent
  # (a template may not ship qemu-guest-agent).
  agent { enabled = false }

  clone {
    vm_id = each.value.template_id
    full  = false
  }

  cpu {
    cores = each.value.cpus
    type  = "host"
  }
  memory { dedicated = each.value.ram_gb * 1024 }

  network_device {
    bridge = proxmox_sdn_vnet.vlan[tostring(each.value.vlan)].id
  }

  # cloud-init only applies to the Linux cloud-image templates; harmless if the template
  # has no cloud-init datastore, and Windows provisioning is handled later from the router.
  dynamic "initialization" {
    for_each = each.value.os == "linux" ? [1] : []
    content {
      datastore_id = var.proxmox_storage
      dns {
        servers = [local.subnets[tostring(each.value.vlan)].gateway]
      }
      ip_config {
        ipv4 {
          address = "10.${var.range_number}.${each.value.vlan}.${each.value.ip_last_octet}/24"
          gateway = local.subnets[tostring(each.value.vlan)].gateway
        }
      }
    }
  }

  depends_on = [proxmox_virtual_environment_vm.router]
}
