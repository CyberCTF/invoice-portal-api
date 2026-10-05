# VM provisioning (`vm.provision`)

VM edition of a lab machine. vm.os and vm.provision steps that rebuild the same machine as the Docker edition.

Each machine's `vm:` rebuilds the same machine as its Docker edition, on a real OS. The VM
edition sets the bar: a lab that only works in containers is not finished.

## Layout

- One script per machine: `provision/<machine>.sh` (or `.yml` for an Ansible playbook run inside
  the VM, `.ps1` on Windows).
- Steps run as root, in order, from `/opt/isoloom` (a copy of the project). Reuse the project's
  files from there: `"$LAB/build/database/init/01-schema.sql"`, `"$LAB/build/web/src"`, the
  evidence scripts.
- The machine's declared `inputs` are in the environment.

## Rules

- `#!/bin/sh` and `set -eu`. LF line endings.
- **Idempotent**: re-running a step must not fail or duplicate data. Seed the schema only when
  the table is missing. Create users with `IF NOT EXISTS`.
- Install with the OS's package manager (`apt-get` on Debian/Ubuntu with
  `DEBIAN_FRONTEND=noninteractive`, `dnf` on Rocky).
- Listen on the **same port** as the Docker edition and on the lab network (`bind-address = 0.0.0.0`).
- Run the app as a systemd service under its own system user, `Restart=on-failure`, enabled at
  boot. App settings go in the unit (`Environment=`), matching the Dockerfile `ENV` and app defaults.
- Survive a VM reboot: disable socket activation or defaults that override your port (e.g.
  Debian's `mariadb.socket`).
- Reach other machines by name (Isoloom writes them to `/etc/hosts`): `getent hosts web`.
  Grant database access to the app machine's address only, not `%`.
- End by waiting until the service answers (curl the health endpoint, or ping the database),
  with a bounded loop. On failure, print the last logs (`journalctl -u <unit> -n 30`) and exit 1.
- The evidence claim and placement run here too. See `EVIDENCE-INJECTION.md`.

## Database engine

The VM may use the distribution's package (e.g. MariaDB for `mysql:8.0` in Docker) when the lab
behaves the same. If the vulnerability depends on an exact engine or version, install that exact
version, or make the lab Docker-only and say so in the review.

## Test it

```bash
isoloom generate
cd .isoloom/vagrant && vagrant up
vagrant ssh web -c 'cd /opt/isoloom && sh build/check/check.sh'
vagrant destroy -f
```
