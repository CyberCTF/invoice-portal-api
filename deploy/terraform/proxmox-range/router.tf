# The range router VM: one WAN NIC on the node bridge, one NIC per VLAN. Debian 12 cloud
# image. It is the gateway, NAT, DHCP/DNS and firewall for the whole range, and the SSH
# entry point for "Open shell".
#
# NICs are matched by MAC (not by guest interface name), and the cloud-config is built as
# an object and yamlencoded, so neither interface naming nor indentation can break setup.

locals {
  range_cidr = "10.${var.range_number}.0.0/16"
  # Deterministic, locally-administered MACs: 02:00:00:<range>:<kind>:<idx>.
  wan_mac = format("02:00:00:%02x:00:00", var.range_number)
  vlan_ifaces = {
    for idx, vlan in local.vlans : tostring(vlan) => {
      vlan    = vlan
      gateway = local.subnets[tostring(vlan)].gateway
      mac     = format("02:00:00:%02x:01:%02x", var.range_number, idx)
      vnet    = local.subnets[tostring(vlan)].vnet
    }
  }
  attacker_present = contains(local.vlans, var.attacker_vlan)

  # systemd-networkd, matched by MAC: WAN via DHCP; each VLAN NIC holds its .254 gateway.
  wan_network = join("\n", ["[Match]", "MACAddress=${local.wan_mac}", "", "[Network]", "DHCP=yes"])
  vlan_networks = {
    for vlan, i in local.vlan_ifaces : "/etc/systemd/network/20-vlan${vlan}.network" =>
    join("\n", ["[Match]", "MACAddress=${i.mac}", "", "[Network]", "Address=${i.gateway}/24", "ConfigureWithoutCarrier=yes"])
  }

  # dnsmasq: DHCP + DNS per VLAN, bound to each gateway address.
  dnsmasq_conf = join("\n", concat(
    ["bind-dynamic", "domain-needed", "bogus-priv", "server=1.1.1.1"],
    flatten([
      for vlan, i in local.vlan_ifaces : [
        "listen-address=${i.gateway}",
        "dhcp-range=set:v${vlan},10.${var.range_number}.${vlan}.100,10.${var.range_number}.${vlan}.200,12h",
        "dhcp-option=tag:v${vlan},option:router,${i.gateway}",
        "dhcp-option=tag:v${vlan},option:dns-server,${i.gateway}",
      ]
    ]),
  ))

  # nftables, all by subnet so no interface names are needed:
  #  - established/related: accept
  #  - any lab subnet -> the internet (not a lab subnet): accept  (so NAT works)
  #  - the attacker VLAN -> each target VLAN: accept
  #  - everything else between VLANs: dropped by policy
  nft_inter_vlan = local.attacker_present ? [
    for vlan, i in local.vlan_ifaces :
    "    ip saddr 10.${var.range_number}.${var.attacker_vlan}.0/24 ip daddr 10.${var.range_number}.${vlan}.0/24 accept"
    if vlan != var.attacker_vlan
  ] : []
  nft_conf = join("\n", concat(
    [
      "#!/usr/sbin/nft -f",
      "flush ruleset",
      "table inet filter {",
      "  chain input { type filter hook input priority 0; policy accept; }",
      "  chain forward {",
      "    type filter hook forward priority 0; policy drop;",
      "    ct state established,related accept",
      "    ip saddr ${local.range_cidr} ip daddr != ${local.range_cidr} accept",
    ],
    local.nft_inter_vlan,
    [
      "  }",
      "}",
      "table ip nat {",
      "  chain postrouting {",
      "    type nat hook postrouting priority 100; policy accept;",
      "    ip saddr ${local.range_cidr} ip daddr != ${local.range_cidr} masquerade",
      "  }",
      "}",
    ],
  ))

  router_cloud_config = merge(
    {
      hostname       = "ctf${var.range_number}-router"
      package_update = true
      packages       = ["nftables", "dnsmasq", "qemu-guest-agent"]
      write_files = concat(
        [{ path = "/etc/systemd/network/10-wan.network", content = local.wan_network }],
        [for p, c in local.vlan_networks : { path = p, content = c }],
        [
          { path = "/etc/dnsmasq.conf", content = local.dnsmasq_conf },
          { path = "/etc/nftables.conf", permissions = "0755", content = local.nft_conf },
        ],
      )
      runcmd = [
        ["systemctl", "enable", "--now", "qemu-guest-agent"],
        # enable, then restart: networkd is already running at this point (cloud-init boot),
        # so --now won't re-read the .network files we just wrote; a restart picks up the
        # VLAN interfaces (otherwise they stay "unmanaged" with no gateway IP).
        ["systemctl", "enable", "systemd-networkd"],
        ["systemctl", "restart", "systemd-networkd"],
        ["sh", "-c", "echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-ctf.conf && sysctl -w net.ipv4.ip_forward=1"],
        ["systemctl", "enable", "--now", "nftables"],
        # dnsmasq binds the VLAN gateway IPs, which only exist after networkd restarts.
        ["systemctl", "restart", "dnsmasq"],
        ["touch", "/var/lib/cyberctf-router-ready"],
      ]
    },
    var.ssh_public_key == "" ? {} : { ssh_authorized_keys = [var.ssh_public_key] },
  )
}

resource "proxmox_download_file" "debian" {
  node_name    = var.proxmox_node
  datastore_id = var.proxmox_image_storage
  content_type = "iso"
  url          = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
  # Per range: a shared file would be deleted by whichever range is destroyed first.
  file_name           = "ctf${var.range_number}-debian-12-amd64.img"
  overwrite           = false
  overwrite_unmanaged = true
}

resource "proxmox_virtual_environment_file" "router_user_data" {
  node_name    = var.proxmox_node
  datastore_id = var.proxmox_snippet_storage
  content_type = "snippets"
  source_raw {
    file_name = "ctf${var.range_number}-router.yaml"
    data      = "#cloud-config\n${yamlencode(local.router_cloud_config)}"
  }
}

resource "proxmox_virtual_environment_vm" "router" {
  name      = "ctf${var.range_number}-router"
  node_name = var.proxmox_node
  tags      = ["cyberctf", var.lab_slug, "router"]
  on_boot   = false

  agent { enabled = true }
  cpu {
    cores = 1
    type  = "host"
  }
  memory { dedicated = 1024 }

  disk {
    datastore_id = var.proxmox_storage
    file_id      = proxmox_download_file.debian.id
    interface    = "virtio0"
    size         = 8
    discard      = "on"
  }

  # net0 = WAN, then one NIC per VLAN VNet, each with a deterministic MAC.
  network_device {
    bridge      = var.proxmox_uplink_bridge
    mac_address = upper(local.wan_mac)
  }
  dynamic "network_device" {
    for_each = local.vlans
    content {
      bridge      = proxmox_sdn_vnet.vlan[tostring(network_device.value)].id
      mac_address = upper(local.vlan_ifaces[tostring(network_device.value)].mac)
    }
  }

  operating_system { type = "l26" }
  serial_device {}

  initialization {
    datastore_id      = var.proxmox_storage
    user_data_file_id = proxmox_virtual_environment_file.router_user_data.id
    # WAN DHCP; VLAN NIC addresses are set by cloud-init (matched by MAC).
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  depends_on = [proxmox_sdn_applier.range]
}
