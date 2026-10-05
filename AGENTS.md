# AGENTS.md

Instructions for every AI coding agent (Claude Code, Codex, Copilot, Gemini, Cursor, ...) working
on a CyberCTF lab built from this template. The detailed rules live in [`rules/`](rules/); this
file is the entry point.

## The lab model

- **The lab is `isoloom.yml`** at the repo root ([Isoloom](https://www.isoloom.com), schema
  `https://www.isoloom.com/schema/v1.json`): networks, machines, their services (ports), inputs,
  volumes and checks. One description runs on every target the CyberCTF launcher offers: this
  machine, a local VM, ESXi, Proxmox, the clouds, hosted.
- **Each machine has two editions**: `docker:` (`build: build/<machine>` with a Dockerfile, plus
  optional `init:` jobs) and `vm:` (`os:` such as `debian-12`, plus `provision:` steps in
  `provision/<machine>.sh`). Containers are the light option; VMs set the bar.
- **`.isoloom/` is generated** by `isoloom generate` (Compose, Vagrant, Terraform), committed,
  never edited by hand. CI runs `isoloom check`.
- **Evidence**: the player's proof is a real business artefact, claimed per player at startup
  (`inputs: [CTF_API_URL, CTF_LAUNCH_TOKEN]`, `claim-evidence.sh`) into a machine volume and
  placed in the lab's data. Never hard-coded. Without a token the lab uses its public
  development value.
- **Checks**: `checks: [build/check/check.sh]` proves the lab is still solvable, from the
  player's side.
- Reference lab: `github.com/CyberCTF/invoice-portal-api`. Copy its layout.

```bash
isoloom generate
docker compose -f .isoloom/docker/compose.yml up -d --build --wait
docker compose -f .isoloom/docker/compose.yml --profile check run --rm isoloom-check
docker compose -f .isoloom/docker/compose.yml down -v
cd .isoloom/vagrant && vagrant up        # VM edition, one VM per machine
pytest tests/                            # runs against .isoloom/docker/compose.yml
```

## Critical rules

1. Never write `docker-compose.yml`, `build/docker-compose.dev.yml`, a `deploy/` folder,
   Vagrantfiles or Terraform. Change `isoloom.yml`, run `isoloom generate`, commit `.isoloom/`.
2. Give every machine both `docker:` and `vm:`, behaving the same (ports, data, evidence). Only
   VM-only features (Windows, kernel) justify a VM-only lab; then adjust metadata `providers`.
3. Services listen on the port declared in `services:` (non-default: 3206 web, 3207 database,
   ...), on both editions. Only the player's entry point has `publish:` (same number). No
   env-driven host ports.
4. Docker has no `environment:` key: settings go in the Dockerfile `ENV` (quote passwords) or
   app defaults; the VM step sets the same values in its systemd unit.
5. The database machine uses `build: build/database` (init SQL and evidence scripts copied in).
   Init SQL: numbered files, `CREATE DATABASE/TABLE IF NOT EXISTS`, `CREATE USER` before
   `GRANT`, DB and global privileges separate, `INSERT IGNORE` seeds. `DB_NAME` matches everywhere.
6. Package managers match the base image (Debian `apt-get`, Alpine `apk`, Oracle `microdnf`).
   Web servers listen on their port (Apache `Listen 3206` + VirtualHost). Configs are `COPY`'d
   files, not raw tags in `RUN`.
7. Evidence: never in the repo, image, logs or UI. Claimed into a `volumes:` path (e.g.
   `/var/lib/ctf`) by a `docker.init` script and by the `vm.provision` step. `CTF_DEV_EVIDENCE`
   equals `dev_evidence` in `.ctf/metadata.json` and `.ctf/EVIDENCE.md`.
8. No spoilers in player-facing content (README, UI, logs, image labels). No CTF flags or
   `CTF{...}`.
9. House style: plain, short sentences; never use em dashes.

## Workflow

1. **Context**: `.ctf/LIBRARY_PAGE.md` → `.ctf/SCENARIO.md` + `.ctf/EVIDENCE.md` (`rules/context/`).
2. **Development**: `isoloom.yml`, `build/`, `provision/`, `tests/`, `.isoloom/`
   (`rules/apps/development/`, `rules/apps/run/`).
3. **Review** (assessment only): `.ctf/REVIEW.md` or `.ctf/GOOD.md` (`rules/apps/review/`).
4. **Correction**: fix per `.ctf/REVIEW.md`, recheck both editions (`rules/apps/correction/`).
5. **Metadata**: `.ctf/metadata.json` (`rules/deploy/metadata/`).

Full phase details: [`rules/WORKFLOW.md`](rules/WORKFLOW.md).

## Rules index

### Always

- [rules/PHILOSOPHY.md](rules/PHILOSOPHY.md): realism, evidence as proof, no spoilers, one description for every target.
- [rules/WORKFLOW.md](rules/WORKFLOW.md): the five phases, their inputs and outputs.
- [rules/README.md](rules/README.md): short phase overview and triggers.
- [rules/ARTEFACTS.md](rules/ARTEFACTS.md): generation artefacts go in `.ctf/`.
- [rules/STRICT-ENFORCEMENT.md](rules/STRICT-ENFORCEMENT.md): the points system; zero violations.
- [rules/STRICT-ENFORCEMENT-DOCKER.md](rules/STRICT-ENFORCEMENT-DOCKER.md): Isoloom and Docker errors that fail a lab.
- [rules/STRICT-ENFORCEMENT-DATABASE.md](rules/STRICT-ENFORCEMENT-DATABASE.md): database errors that fail a lab.
- [rules/STRICT-ENFORCEMENT-SERVERS.md](rules/STRICT-ENFORCEMENT-SERVERS.md): Apache, Nginx, Go, Java, Node.js, PostgreSQL, Redis errors.
- [rules/STRICT-ENFORCEMENT-UI.md](rules/STRICT-ENFORCEMENT-UI.md): black UI and website structure errors.
- [rules/STRICT-ENFORCEMENT-DOCUMENTATION.md](rules/STRICT-ENFORCEMENT-DOCUMENTATION.md): README, metadata and evidence format errors.
- [rules/STRICT-ENFORCEMENT-REMINDERS.md](rules/STRICT-ENFORCEMENT-REMINDERS.md): the most common errors, as a list.
- [rules/STRICT-ENFORCEMENT-VERIFICATION.md](rules/STRICT-ENFORCEMENT-VERIFICATION.md): checklists to pass before declaring a task done.

### Context (phase 1)

- [rules/context/SCENARIO.md](rules/context/SCENARIO.md): turn the library page into a realistic company scenario.
- [rules/context/EVIDENCE.md](rules/context/EVIDENCE.md): choose the evidence kind, params, location and dev value.
- [rules/context/company-names.txt](rules/context/company-names.txt): fictional company names to use.

### Run: how a lab is described and started (phase 2)

- [rules/apps/run/ISOLOOM.md](rules/apps/run/ISOLOOM.md): read first. `isoloom.yml`, both editions, ports, generated files, commands.
- [rules/apps/run/VM-PROVISION.md](rules/apps/run/VM-PROVISION.md): writing `provision/<machine>.sh` for the VM edition.
- [rules/apps/run/EVIDENCE-INJECTION.md](rules/apps/run/EVIDENCE-INJECTION.md): claiming and placing the player's evidence on both editions.
- [rules/apps/run/ENV-VARS.md](rules/apps/run/ENV-VARS.md): where settings live, launcher inputs, test variables.
- [rules/apps/run/SYNTAX.md](rules/apps/run/SYNTAX.md): quoting passwords in Dockerfile `ENV`, systemd units, YAML.
- [rules/apps/run/MYSQL-HEALTHCHECK.md](rules/apps/run/MYSQL-HEALTHCHECK.md): MySQL port, readiness and init loading.
- [rules/apps/run/WEB-DB-CONNECTION.md](rules/apps/run/WEB-DB-CONNECTION.md): PHP to MySQL connection contract.

### Development (phase 2)

- [rules/apps/development/lab-development.md](rules/apps/development/lab-development.md): read first. Building the lab and the mandatory `.ctf/WALKTHROUGH.md`.
- [rules/apps/development/DIRECTORY.md](rules/apps/development/DIRECTORY.md): the canonical repo layout.
- Docker edition, when writing Dockerfiles:
  - [docker-setup.md](rules/apps/development/docker/docker-setup.md): Dockerfile requirements, security, images.
  - [WORKFLOW.md](rules/apps/development/docker/WORKFLOW.md): detect the base OS before installing.
  - [PACKAGES.md](rules/apps/development/docker/PACKAGES.md): package manager per base image.
  - [DOCKERFILE-SYNTAX.md](rules/apps/development/docker/DOCKERFILE-SYNTAX.md): no raw config tags in `RUN`.
  - [SERVERS.md](rules/apps/development/docker/SERVERS.md): Apache/Nginx on the declared port, `.htaccess`.
  - [RUNTIMES.md](rules/apps/development/docker/RUNTIMES.md): PHP extensions, Python, Node lockfiles.
  - [SCRIPTS.md](rules/apps/development/docker/SCRIPTS.md): shell script hygiene.
  - [MYSQL-UDF-PLUGIN-DIR.md](rules/apps/development/docker/MYSQL-UDF-PLUGIN-DIR.md): MySQL UDF labs only.
- Code, when writing the app and its database:
  - [CRITICAL-ERRORS.md](rules/apps/development/code/CRITICAL-ERRORS.md): top errors quick reference.
  - [DATABASE.md](rules/apps/development/code/DATABASE.md): init order and MySQL privileges.
  - [INIT-SQL-GUARDRAILS.md](rules/apps/development/code/INIT-SQL-GUARDRAILS.md): init SQL order, indexes, loading.
  - [DATABASE-CONSISTENCY.md](rules/apps/development/code/DATABASE-CONSISTENCY.md): every queried table exists.
  - [DATABASE-SCHEMA-CONSISTENCY.md](rules/apps/development/code/DATABASE-SCHEMA-CONSISTENCY.md): safe init and mysqli usage.
  - [DATABASE-SCHEMA-RELIABILITY.md](rules/apps/development/code/DATABASE-SCHEMA-RELIABILITY.md): no missing tables or empty DB.
  - [LAB-MYSQL-PHP-RELIABILITY.md](rules/apps/development/code/LAB-MYSQL-PHP-RELIABILITY.md): PHP + MySQL labs, UNION SQLi reliability.
  - [PHP-MYSQLI-SAFE-RESULTS.md](rules/apps/development/code/PHP-MYSQLI-SAFE-RESULTS.md): guard mysqli results.
  - [SQL-GROUP-BY.md](rules/apps/development/code/SQL-GROUP-BY.md): `ONLY_FULL_GROUP_BY`-safe SQL.
  - [MYSQL56-COMPAT.md](rules/apps/development/code/MYSQL56-COMPAT.md): MySQL 5.6 labs only.
  - [HTACCESS-ROUTING.md](rules/apps/development/code/HTACCESS-ROUTING.md): Apache routing.
  - [OTHER.md](rules/apps/development/code/OTHER.md): time zone, logging, retries, CI hints.
  - Per stack, in [rules/apps/development/code/stack/](rules/apps/development/code/stack/): GO, JAVA, JAVASCRIPT, NGINX, NODEJS, PHP, POSTGRESQL, PYTHON, REDIS rules.
- UI, when writing pages:
  - [UI-BLACK.md](rules/apps/development/ui/UI-BLACK.md): black-only UI.
  - [TAILWIND-DARK-MODE.md](rules/apps/development/ui/TAILWIND-DARK-MODE.md): Tailwind dark mode.
  - [WEBSITE-PAGES-ESSENTIALS.md](rules/apps/development/ui/WEBSITE-PAGES-ESSENTIALS.md): the multi-page site skeleton.
- Tests, when writing `tests/`:
  - [testing.md](rules/apps/development/tests/testing.md): overview.
  - [test-requirements.md](rules/apps/development/tests/test-requirements.md): required coverage.
  - [test-execution.md](rules/apps/development/tests/test-execution.md): pytest against `.isoloom/docker/compose.yml`, cleanup.
  - [test-retry.md](rules/apps/development/tests/test-retry.md): retry policy.
  - [test-env-vars.md](rules/apps/development/tests/test-env-vars.md): test variables.
  - [phase-timing.md](rules/apps/development/tests/phase-timing.md): phase timing logs.
  - [review-phase.md](rules/apps/development/tests/review-phase.md): review checklist.

### Review (phase 3, assessment only)

- [rules/apps/review/FULL-SCOPE.md](rules/apps/review/FULL-SCOPE.md): what the review covers.
- [rules/apps/review/ISOLOOM-VALIDATION.md](rules/apps/review/ISOLOOM-VALIDATION.md): validate the spec and both editions.
- [rules/apps/review/VALIDATION.md](rules/apps/review/VALIDATION.md): end-to-end validation.
- [rules/apps/review/TEST-RESULTS.md](rules/apps/review/TEST-RESULTS.md): `.ctf/test_results/` format.
- [rules/apps/review/HELP-CONTENT.md](rules/apps/review/HELP-CONTENT.md): no hints in player-facing content.
- [rules/apps/review/WARNINGS.md](rules/apps/review/WARNINGS.md): remove educational disclaimers.
- [rules/apps/review/QUALITY.md](rules/apps/review/QUALITY.md): QA checklist.
- [rules/apps/review/UI-CHECKLIST.md](rules/apps/review/UI-CHECKLIST.md): black UI gate.

### Correction (phase 4)

- [rules/apps/correction/OVERVIEW.md](rules/apps/correction/OVERVIEW.md): purpose and scope.
- [rules/apps/correction/WORKFLOW.md](rules/apps/correction/WORKFLOW.md): steps and success criteria.
- [rules/apps/correction/STRICT-COMPLIANCE.md](rules/apps/correction/STRICT-COMPLIANCE.md): full re-validation, no ad-hoc scripts.
- [rules/apps/correction/RECHECK-BOTH.md](rules/apps/correction/RECHECK-BOTH.md): recheck the Docker and the VM edition.
- [rules/apps/correction/DB-SCHEMA-SELF-HEAL.md](rules/apps/correction/DB-SCHEMA-SELF-HEAL.md): schema self-heal hardening.
- [rules/apps/correction/RETRY-AND-LOGS.md](rules/apps/correction/RETRY-AND-LOGS.md): retries and logs.
- [rules/apps/correction/OUTPUTS.md](rules/apps/correction/OUTPUTS.md): what to produce after fixes.

### Deploy and metadata (phase 5)

- [rules/deploy/targets/TARGETS.md](rules/deploy/targets/TARGETS.md): every target and which edition it needs.
- [rules/deploy/metadata/metadata.md](rules/deploy/metadata/metadata.md): `.ctf/metadata.json` fields, `providers`.
- [rules/deploy/github/github-publishing.md](rules/deploy/github/github-publishing.md): the validate and publish workflows, the README template.
