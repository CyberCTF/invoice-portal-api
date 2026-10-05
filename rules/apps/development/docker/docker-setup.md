# Docker edition setup

Prescriptive Docker edition setup: one Dockerfile per machine, settings in ENV, ready when the port opens, security.

The Docker edition of each machine is `docker:` in `isoloom.yml`: `build: build/<machine>` (a
folder with a Dockerfile) or `image: <published image>`, plus optional `init:` scripts. Isoloom
writes `.isoloom/docker/compose.yml` from it. Never write a compose file by hand.

## Dockerfile requirements

- One Dockerfile per machine in `build/<machine>/`.
- Settings in `ENV` (quoted when needed, see `../../run/SYNTAX.md`) or app defaults. There is
  no `environment:` key; only declared `inputs` arrive at runtime.
- The service listens on its declared port, on `0.0.0.0` (e.g. Apache `Listen 3206`, MySQL
  `MYSQL_TCP_PORT=3207`). `EXPOSE` that port.
- The port opens only when the service is ready: Isoloom's health check is a TCP check on the
  declared ports.
- Configs as files under `build/<machine>/config/`, `COPY`'d in (the VM step reuses them).
- An optional `HEALTHCHECK` (e.g. curl `/healthz`) helps local debugging.

## Security

- Run the app as a non-root user (create it in the Dockerfile, `chown` writable dirs, `USER`).
- No secrets baked in beyond the lab's own fictional credentials. Never the evidence.
- Resource limits come from `resources:` in `isoloom.yml`.
- Networks come from `networks:` and `reach:` in `isoloom.yml`.

## Images

- Pin base image tags (`python:3.12-slim`, `mysql:8.0`).
- Prefer images that exist for amd64 and arm64: the publish workflow derives the lab's
  architectures from pulled images in `.isoloom/docker/compose.yml`.
- Multi-stage builds and clean layers to limit size.

## Context adaptation

- Detect the stack from the scenario and pick a fitting base image (Node.js, Python, PHP, Go,
  Java).
- Install dependencies with the stack's package manager (npm, pip, composer) and the base OS's
  package manager (see `PACKAGES.md`).
- Add a database machine only if the scenario needs data persistence.

## Run it

```bash
isoloom generate
docker compose -f .isoloom/docker/compose.yml up -d --build --wait
docker compose -f .isoloom/docker/compose.yml --profile check run --rm isoloom-check
docker compose -f .isoloom/docker/compose.yml down -v
```
