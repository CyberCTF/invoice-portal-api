# proxmox-range: multi-VM labs on Proxmox (foundation)

An isolated network and a router for a multi-VM lab ("range") on a player's Proxmox server,
plus the lab VMs as linked clones on their VLANs. The model follows Ludus (AGPL); none of
its code is used. See `../../../.cursor/rules/deploy/targets/TARGETS.mdc` and, in the
launcher, `docs/server.md`.

## What it builds

- **One SDN simple zone per range** (`ctf<N>`) and **one internal VNet per VLAN**
  (`ctf<N>v<vlan>`), addressing `10.<range>.<vlan>.0/24`, gateway `.254`. The VNets have no
  uplink, so the only way in or out is the router.
- **A router VM** (`router.tf`, Debian 12 cloud image): WAN NIC on the node bridge, one NIC
  per VLAN holding `.254`. Its cloud-init (`router-cloud-init.yaml.tftpl`) sets IP
  forwarding, NAT out the WAN, per-VLAN DHCP/DNS (dnsmasq), and an nftables forward policy
  of `drop` with inter-VLAN rules appended. It is the range's gateway and the SSH entry
  point for "Open shell".
- **The lab VMs** (`vms.tf`): a linked clone of each template on its VLAN, Linux VMs get a
  static IP via cloud-init.

## Status

Foundation only, and validated with `terraform validate` (not yet applied to a real
Proxmox). Deliberately **not** here yet, each its own layer:

- target-VM provisioning from the router (Ansible roles, AD domain create/join);
- Windows template provisioning (sysprep, static IP, WinRM, domain join);
- the launcher reading `deploy/range.yaml` and resolving templates to Proxmox VMIDs;
- snapshots / "testing mode".

## Inputs

See `variables.tf`. The launcher supplies the connection (same as `../proxmox`), a unique
`range_number` (1..=250), `lab_slug` / `lab_repository` / `lab_commit`, and `vms` resolved
from `deploy/range.yaml`. `ip` outputs the router's WAN address for "Open shell".
