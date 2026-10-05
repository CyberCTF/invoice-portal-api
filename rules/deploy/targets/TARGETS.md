# DEPLOY TARGETS

Where a lab runs (Docker, local VM, server, cloud, hosted) and how isoloom.yml reaches every target.

One lab, every target. `isoloom.yml` is the single definition of the lab. `isoloom generate`
writes one runnable output per target under `.isoloom/`, and the CyberCTF launcher regenerates
and runs the one for the player's choice.

| Player picks | Isoloom target | Needs | Generated file |
| --- | --- | --- | --- |
| This machine (Docker) | `docker` | `docker:` | `.isoloom/docker/compose.yml` |
| Hosted | `hosted` | `docker:` | `.isoloom/docker/compose.yml` |
| This machine (VM), ESXi | `docker-vm` | `docker:` | `.isoloom/docker-vm/Vagrantfile` |
| Proxmox (Docker on one VM) | `docker-vm` | `docker:` | `.isoloom/docker-vm/proxmox/main.tf` |
| This machine, ESXi (one VM per machine) | `vagrant` | `vm:` | `.isoloom/vagrant/Vagrantfile` |
| Proxmox (one VM per machine) | `proxmox` | `vm:` | `.isoloom/proxmox/main.tf` |
| AWS, Azure, GCP, DigitalOcean, Linode, Oracle | `cloud-docker` | `docker:` | `.isoloom/cloud-docker/<cloud>/main.tf` |

Docs: https://www.isoloom.com/en/docs/targets

## Rules

- No `deploy/` folder, no hand-written Vagrantfile, Terraform, Ansible or cloud-init. Lab work
  stays in `isoloom.yml`, `build/`, `provision/`.
- `.isoloom/` is committed and never edited. CI (`validate.yml`) runs `isoloom check`,
  `terraform validate` on every `main.tf` and parses every Vagrantfile.
- Give every machine `docker:` and `vm:` so every target is available. A lab without `docker:`
  on some machine is VM-only: no hosted, no cloud (cloud VMs per machine are planned). A lab
  without `vm:` still runs everywhere through Docker on one VM.
- Match `providers` in `.ctf/metadata.json` to what the lab supports (see
  `../metadata/metadata.md`).
- Services are reached from the attack box on the lab network. Only the player's entry point
  is `publish:`ed, and only on loopback.
- Secrets: the launch token reaches the lab only as the `CTF_LAUNCH_TOKEN` input. Never commit
  `.env`, `*.tfvars`, `.terraform/`, `.vagrant/` or state.
- Labs that need several machines (pfSense, AD) describe them all in `isoloom.yml`
  (`networks`, `reach`, `vm:`, top-level `provision:` for Ansible).
