# METADATA

Define lab metadata fields and required values for publishing; enforce examples and accepted formats.

## Purpose
- Standardize lab metadata for publishing to the CyberCTF platform (CyberBackend).
- Authored as `.ctf/metadata.json` and committed. The publish workflow (`.github/workflows/publish.yml`) reads it and derives the lab's CPU architectures from `.isoloom/docker/compose.yml`. It is **public**: it must contain nothing secret (the development evidence is public by design).

## Required Fields

- project_name
  - Short identifier for Git/registry publishing.
  - Example: `cyberlabs-swaggerapi-prototype-pollution`

- slug
  - URL-safe unique identifier for the lab (kebab-case).
  - Example: `swaggerapi-prototype-pollution`

- title
  - Human-readable lab title.
  - Example: `SwaggerApi prototype pollution`

- description
  - **CRITICAL**: at most 320 characters, 1 to 2 short sentences summarizing the objective in business terms. No repetition.
  - Example: `Exploit a prototype pollution flaw in the partner API to reach the finance team's payout approvals.`

- category
  - Allowed: `web`, `pwn`, `rev`, `crypto`, `forensics`, `network`, `osint`, `misc`
  - Example: `web`

- difficulty
  - Easy = 1, Medium = 2, Hard = 3

- evidence_kind
  - The business form of the evidence, from `.ctf/EVIDENCE.md`: `CREDENTIALS`, `PASSWORD`, `API_KEY`, `IBAN`, `AMOUNT`, `EMAIL` or `SECRET`.

- evidence_params
  - JSON object of generator params, from `.ctf/EVIDENCE.md` (e.g. `{"username": "analyst2686"}` for `CREDENTIALS`, `{"domain": "globex-finance.fr"}` for `EMAIL`, `{}` if none).

- dev_evidence
  - The fixed development value used without a launcher (dev, CI, pytest). Bare value in the declared form, no prose.
  - Example: `analyst2686:Dev-Only-Pa55!`

- capabilities
  - Capability ids from the skills graph that exploiting this lab **exercises** (1 to 4, most specific first). A capability is a skill on a product (the lab's real technology), e.g. `union-sql-injection-exploit-postgresql`. Copy them from the `**Capabilities**` line of `.ctf/EVIDENCE.md`. Publishing rejects unknown ids.
  - Example: `["union-sql-injection-exploit-postgresql", "sql-injection-detect-postgresql"]`

- question
  - Player-facing prompt saying what evidence to bring back and in which form, without hinting at the exploit.
  - Example: `Recover the finance analyst's credentials (username:password).`

- providers
  - Where the lab can run besides Docker on the player's machine. The launcher runs the matching output of `isoloom.yml` (see `deploy/targets/TARGETS.md`).
  - Allowed: `virtualbox`, `vmware_desktop`, `parallels`, `hyperv`, `libvirt` (local VM), `vmware_esxi`, `proxmox` (server), `aws`, `azure`, `gcp`, `digitalocean`, `linode`, `oci` (cloud), `hosted`.
  - Default for a lab whose machines all have `docker:` and `vm:`: all of them.
  - A VM-only lab (some machine without `docker:`) drops `hosted` and the clouds.
  - Example: `["virtualbox", "vmware_desktop", "parallels", "hyperv", "libvirt", "vmware_esxi", "proxmox", "aws", "azure", "gcp", "digitalocean", "linode", "oci", "hosted"]`

- Machine sizes are not metadata: set `resources:` per machine in `isoloom.yml` (defaults 1 CPU, 1024 MB, 20 GB). Only raise them when the stack needs it: bigger hosts cost players money in the cloud.

## Example JSON

```json
{
  "project_name": "cyberlabs-invoice-portal-sqli",
  "slug": "invoice-portal-sqli",
  "title": "Invoice portal SQL injection",
  "description": "Abuse the invoice search of a supplier portal to take over the finance analyst's account.",
  "category": "web",
  "difficulty": 2,
  "evidence_kind": "CREDENTIALS",
  "evidence_params": { "username": "analyst2686" },
  "dev_evidence": "analyst2686:Dev-Only-Pa55!",
  "capabilities": ["union-sql-injection-exploit-postgresql", "sql-injection-detect-postgresql"],
  "question": "Recover the finance analyst's credentials (username:password).",
  "providers": ["virtualbox", "vmware_desktop", "parallels", "hyperv", "libvirt", "vmware_esxi", "proxmox", "aws", "azure", "gcp", "digitalocean", "linode", "oci", "hosted"]
}
```

## Strict Schema (no extra fields)
- MUST contain ONLY: `project_name`, `slug`, `title`, `description`, `category`, `difficulty`, `evidence_kind`, `evidence_params`, `dev_evidence`, `capabilities`, `question`, `providers`.
- Reject legacy or unknown keys, in particular `flag`, `flag_format`, `flag_type`, `points`, `id`, `services`, `questions`, `estimated_time`, `resources`.

## Validation Failures (Block Merge)
- Missing key, extra key, or empty/placeholder value (`""`, `TBD`, `to-fill`).
- `slug` not kebab-case; `difficulty` not in {1, 2, 3}; `category` not in the allowed list.
- `evidence_kind` not in the allowed list, or `evidence_params` missing a required param (`username` for `CREDENTIALS`, `domain` for `EMAIL`).
- `capabilities` empty, or containing ids that are not kebab-case capability ids from the skills graph.
- `dev_evidence` does not match the declared kind and params, or differs from `CTF_DEV_EVIDENCE` in the Docker `init` script and the VM provision step.
