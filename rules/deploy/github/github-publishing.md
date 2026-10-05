# GitHub workflows and README

The lab's GitHub Actions workflows (validate, publish) and the mandated player-facing README.

## Workflows (from the template, unchanged per lab)

- `.github/workflows/validate.yml`, on every PR and push to `main`:
  - installs Isoloom at a pinned commit, runs `isoloom validate` and `isoloom check`
    (fails when `.isoloom/` is out of date: run `isoloom generate` and commit);
  - brings the Docker edition up (`docker compose -f .isoloom/docker/compose.yml up -d --build --wait`)
    with the development evidence and runs the checks (`--profile check run --rm isoloom-check`);
  - runs `terraform validate` on every generated `main.tf` and parses every generated Vagrantfile.
- `.github/workflows/publish.yml`, on push to `main`: registers the lab with CyberCTF
  (CyberBackend `publishLab`) from `.ctf/metadata.json` at the pushed commit. It derives the CPU
  architectures from the pulled images in `.isoloom/docker/compose.yml` (built machines build
  anywhere).

Rules:
- Never put evidence or secrets inline: only `${{ secrets.* }}` and `${{ vars.* }}`.
- No Docker Hub publishing: the launcher builds `build:` machines from the repository.
- The lab repository is public (targets fetch it at the pinned commit).

## Repository README requirement

Every lab README follows this template. Only substitute the lab's title, scenario paragraph,
slug and published port. Keep the structure and length: no extra sections, no hints.

````
# <Lab title>

## Scenario

<One paragraph of business context: who runs the system, what it does, what the player must
bring back. No vulnerability name, no hint.>

## How to run

```bash
git clone https://github.com/CyberCTF/<slug>
cd <slug>
docker compose -f .isoloom/docker/compose.yml up -d --build --wait
```

With VMs: `cd .isoloom/vagrant && vagrant up`. The lab is described in `isoloom.yml`
([Isoloom](https://www.isoloom.com)).

**Access**: http://localhost:<publish port>
````

- The access port is the `publish:` port of the entry point in `isoloom.yml`.
- Do **not** add troubleshooting or multi-step guidance.
