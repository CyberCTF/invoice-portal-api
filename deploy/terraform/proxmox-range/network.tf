# The lab's isolated network on Proxmox SDN: one simple zone per range, and one VNet per
# VLAN listed in the range. VNets are internal (no uplink): the only way in or out is the
# router VM (router.tf), which NATs to the node's bridge and firewalls between VLANs.
#
# Addressing follows Ludus's scheme so range configs port over: 10.<range>.<vlan>.0/24,
# gateway .254 (the router). range_number is 1..=250, unique per running range on the host.

locals {
  zone = "ctf${var.range_number}"
  # VLANs the range uses, from the VMs, always including the attacker VLAN.
  vlans = sort(distinct([for vm in var.vms : vm.vlan]))
  subnets = {
    for vlan in local.vlans : tostring(vlan) => {
      vlan    = vlan
      cidr    = "10.${var.range_number}.${vlan}.0/24"
      gateway = "10.${var.range_number}.${vlan}.254"
      vnet    = "ctf${var.range_number}v${vlan}"
    }
  }
}

# A simple zone: Proxmox manages an isolated bridge per VNet on this node, no VLAN tags
# needed on the physical NIC (works on a single-node host).
resource "proxmox_sdn_zone_simple" "range" {
  id    = local.zone
  nodes = [var.proxmox_node]
  mtu   = 1500
}

resource "proxmox_sdn_vnet" "vlan" {
  for_each = local.subnets
  id       = each.value.vnet
  zone     = proxmox_sdn_zone_simple.range.id
}

# A subnet per VNet, with the router's address as the gateway. The router VM holds that IP;
# Proxmox does not (no SNAT/DHCP at the zone level for a simple zone), so VMs use the router.
resource "proxmox_sdn_subnet" "vlan" {
  for_each = local.subnets
  cidr     = each.value.cidr
  vnet     = proxmox_sdn_vnet.vlan[each.key].id
  gateway  = each.value.gateway
  # The router does NAT itself; no SNAT at the SDN level (simple zone has no gateway host).
  snat = false
}

# Apply the SDN config once all VNets/subnets are declared (Proxmox stages then reloads).
resource "proxmox_sdn_applier" "range" {
  depends_on = [
    proxmox_sdn_subnet.vlan,
  ]
}
