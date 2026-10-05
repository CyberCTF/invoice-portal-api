# Correction recheck on both editions

Correction must re-run validations on both editions (Docker and VM) after fixes.

## Mandatory behavior
- After applying fixes per `.ctf/REVIEW.md`, run `isoloom generate`, then re-run the full
  validation on BOTH editions:
  - Docker: `docker compose -f .isoloom/docker/compose.yml up -d --build --wait`, then
    `docker compose -f .isoloom/docker/compose.yml --profile check run --rm isoloom-check`
  - VM: `cd .isoloom/vagrant && vagrant up`, then run `build/check/check.sh` from a machine
- `isoloom check` must pass (the committed `.isoloom/` matches `isoloom.yml`).
- Parity: same machines, ports, data and evidence placement on both editions.
- Only when both pass and pytest (including evidence extraction) passes, append success to
  `.ctf/REVIEW.md`; otherwise record failures with precise categories.
