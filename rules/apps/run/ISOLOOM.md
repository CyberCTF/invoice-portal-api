# The lab is `isoloom.yml`

The lab is its isoloom.yml. Machines, networks, services, inputs, checks; Docker and VM editions; generated .isoloom/ files.

A lab is described once, in `isoloom.yml` at the repo root ([Isoloom](https://www.isoloom.com),
schema `https://www.isoloom.com/schema/v1.json`). Isoloom turns it into every target the CyberCTF
launcher offers: this machine, a local VM, ESXi, Proxmox, the clouds, hosted.

The canonical example is `github.com/CyberCTF/invoice-portal-api`. Copy its layout.

Docs: https://www.isoloom.com/en/docs/spec-reference (and `/machines`, `/networks`,
`/provisioning`, `/checks`, `/images`, `/targets`).

## There is no compose file to write

- No root `docker-compose.yml`, no `build/docker-compose.dev.yml`, no `deploy/` folder
  (no Terraform, Vagrant, Ansible, cloud-init or `range.yaml` of your own).
- `isoloom generate` writes everything under `.isoloom/`:
  - `.isoloom/docker/compose.yml`: the containers
  - `.isoloom/vagrant/Vagrantfile`: one VM per machine
  - `.isoloom/docker-vm/`: Docker on one VM (`Vagrantfile`, `proxmox/main.tf`)
  - `.isoloom/proxmox/main.tf`: one VM per machine on Proxmox
  - `.isoloom/cloud-docker/<aws|azure|gcp|digitalocean|linode|oci>/main.tf`
- `.isoloom/` is committed and never edited by hand. Change `isoloom.yml`, run
  `isoloom generate`, commit both. CI runs `isoloom validate` and `isoloom check` (fails when
  `.isoloom/` is out of date).

## Spec essentials

```yaml
# yaml-language-server: $schema=https://www.isoloom.com/schema/v1.json
version: 1
name: invoice-portal-api            # kebab-case, the lab slug

networks:
  lab: { cidr: 10.20.0.0/24 }

inputs: [CTF_API_URL, CTF_LAUNCH_TOKEN]

machines:
  database:
    networks: { lab: 32 }
    services: [{ port: 3207, name: mysql }]
    inputs: [CTF_API_URL, CTF_LAUNCH_TOKEN]
    volumes: { evidence: /var/lib/ctf }
    resources: { cpus: 1, memory_mb: 1024 }
    docker:
      build: build/database
      init: [build/database/evidence.sh]
    vm:
      os: debian-12
      provision: [provision/database.sh]

  web:
    networks: { lab: 31 }
    services: [{ port: 3206, name: portal, http: true, publish: 3206 }]
    depends_on: [database]
    docker:
      build: build/web
    vm:
      os: debian-12
      provision: [provision/web.sh]

checks:
  - build/check/check.sh
```

- `version: 1` and `name` are required. Unknown fields are errors.
- `networks`: any RFC1918 range sized `/24` to `/29`. `.1` is the gateway, the last two usable
  addresses are reserved (router, controller). Pick machine octets from 2 up (e.g. 31, 32).
- `machines.<name>`: names are DNS labels. Machines reach each other **by name** on every
  target (`database`, never an IP).
  - `networks: {net: last-octet}`
  - `services: [{port, name, http, publish}]`: every port the machine answers on.
  - `inputs`: launch-time values this machine receives (declared at the top level too).
  - `volumes: {name: /abs/path}`: data that survives restarts.
  - `resources`: `cpus`, `memory_mb`, `disk_gb` (defaults 1, 1024, 20). Raise only when needed.
  - `depends_on`: machines that must answer first.
  - `access: true`: the machine the player lands on (at most one).
- `reach:` (top level): allowed traffic between networks. Everything else is blocked.
- `checks:`: scripts run from the player's side. Exit 0 = the lab is solvable.
- `provision:` (top level): Ansible playbooks run from a controller once every VM is up
  (multi-machine setups such as AD). VM targets only.

## Two editions of every machine

Give every machine **both** `docker:` and `vm:` when possible. The lab then runs on every target.

- `docker:` (the light option): `image: <published image>` or `build: <dir with a Dockerfile>`,
  plus `init: [scripts]` that run once in the machine's network namespace, with its volumes and
  inputs, before the machine counts as ready.
- `vm:` (sets the bar): `os:` from the image table (`debian-12`, `ubuntu-24.04`, `rocky-9`,
  `windows-server-2019`, ...) and `provision: [steps]` run as root from `/opt/isoloom` (the
  project copy): `.sh` or `.yml` on Linux, `.ps1` on Windows. See `VM-PROVISION.md`.
- VM-only features (Windows, kernel modules, real firewalls) make the lab VM-only. Then omit
  `docker:` and drop the Docker-only providers in metadata (see `deploy/targets/TARGETS.md`).
- Both editions must behave the same: same names, same ports, same data, same evidence
  placement, same checks passing.

## Ports

- Each machine declares its ports in `services:`. The service listens on that port inside the
  container and the VM (e.g. Apache `Listen 3206`, MySQL `port=3207`).
- Use non-default ports from 3206 up (3206 web, 3207 database, 3208 API, 3209 Redis, ...).
- `publish: <port>` exposes one service on the player's loopback (`127.0.0.1`). Use the same
  number as the service port. Publish only what the player opens (usually the web entry point).
- No env-driven host ports, no `ports:` mappings: the generated files handle it.
- Isoloom marks a Docker machine healthy when its service ports accept connections. Open the
  port only when the service is really ready.

## Docker edition rules

- No `environment:` key exists. Settings go in the image (`ENV` in the Dockerfile) or in app
  defaults. Only declared `inputs` arrive at runtime.
- The database machine uses `build: build/database` (its init SQL and evidence scripts are
  copied in), never a bare `image:`.
- One Dockerfile per machine, in `build/<machine>/`. See `apps/development/docker/`.

## Commands

```bash
isoloom generate                                     # after any change to isoloom.yml
docker compose -f .isoloom/docker/compose.yml up -d --build --wait
docker compose -f .isoloom/docker/compose.yml --profile check run --rm isoloom-check
docker compose -f .isoloom/docker/compose.yml down -v
cd .isoloom/vagrant && vagrant up                    # one VM per machine
```
