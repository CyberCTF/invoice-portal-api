# deploy/

Runs this lab somewhere other than plain Docker on the player's machine. Every target
builds a **lab host** (Debian 12 VM) and runs the lab's `docker-compose.yml` on it with
`ansible/site.yml`. The CyberCTF launcher drives this; you can also run it by hand.

```
deploy/
  ansible/site.yml                 # lab host: Docker + compose up (+ optional attack box)
  cloud-init/user-data.yaml.tftpl  # Terraform targets: fetch lab @commit, run site.yml
  vagrant/Vagrantfile              # local VM (virtualbox, vmware_desktop, parallels, hyperv, libvirt) + ESXi
  terraform/proxmox/               # server: Proxmox VE (bpg/proxmox)
  terraform/aws/                   # cloud: AWS EC2
```

## By hand

Local VM:

```sh
cd deploy/vagrant && vagrant up --provider virtualbox
vagrant ssh -c "sudo docker compose -p lab -f /opt/lab/docker-compose.yml ps"
```

Proxmox (the node's `local` storage needs `iso` and `snippets` content):

```sh
cd deploy/terraform/proxmox
docker run --rm -it -v "$PWD/../..:/deploy" -w /deploy/terraform/proxmox \
  -e TF_VAR_proxmox_endpoint=https://pve.lan:8006/ -e TF_VAR_proxmox_username=root@pam \
  -e TF_VAR_proxmox_password -e TF_VAR_proxmox_insecure=true \
  -e TF_VAR_lab_slug=<slug> -e TF_VAR_lab_repository=CyberCTF/<repo> -e TF_VAR_lab_commit=<sha> \
  hashicorp/terraform:1.16.5 apply
```

AWS: same with `deploy/terraform/aws`, AWS credentials in the environment
(`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` or `AWS_PROFILE`), and `TF_VAR_region`.

## What a target guarantees

- **A clear outcome.** On Proxmox and AWS, cloud-init runs `/usr/local/sbin/cyberctf-bootstrap`,
  which writes `/var/lib/cyberctf/status` (`running: <step>`, `ready` or `failed: <step>`) and
  logs to `/var/log/cyberctf-lab.log`. The modules output `ready_file`; the launcher waits on
  it over SSH after `apply`, so "running" means the lab is up. Vagrant targets fail `vagrant up`
  instead.
- **Retries** on every network step (apt, the lab download, the attack box image).
- **No collisions.** Resource names carry a random id per deployment
  (`cyberctf-<slug>-<id>`), so the same lab can run twice in one account or on one node.
- **Early, actionable errors.** Proxmox checks that the image storage accepts ISO images and
  the snippet storage accepts snippets before uploading anything. AWS builds its own small
  VPC, so it doesn't depend on the account's default VPC.
- **API tokens on Proxmox.** `proxmox_api_token` (`user@realm!name=secret`) replaces user +
  password for the API; the snippet upload then uses `proxmox_ssh_private_key_file` (SSH as
  `proxmox_ssh_username`, default the token's user). A token for root without privilege
  separation: `pveum user token add root@pam cyberctf --privsep 0`.
- **Sizing from the lab.** `resources` in `.ctf/metadata.json` (`cpus`, `memory_mb`,
  `disk_gb`) sizes the lab host on every target.
- **The attack box joins every network** of the lab, not just the default one.

## Variables passed to every target

| | Vagrant (env) | Terraform (`TF_VAR_*`) |
| --- | --- | --- |
| Evidence claim | `CTF_API_URL`, `CTF_LAUNCH_TOKEN` | `ctf_api_url`, `ctf_launch_token` |
| Attack box | `CYBERCTF_ATTACKBOX_IMAGE` | `attackbox_image` |
| Lab source | copied from this folder | `lab_repository`, `lab_commit`, `lab_slug` |
| Server connection | `CYBERCTF_ESXI_*` | `proxmox_*` |
| Cloud | | `region`, `instance_type`, `allowed_cidr`; AWS keys as `AWS_*` env |
| Launcher SSH key ("Open shell") | Vagrant's own key | `ssh_public_key` (user from the `ssh_user` output) |
