# Correction Strict Compliance

Correction must consume REVIEW.md and re-validate the entire lab (Docker, DB, UI, pytest/evidence) with no ad-hoc scripts.

## Core Contract
- Consume `.ctf/REVIEW.md` as the single source of truth for what to fix.
- Apply fixes only within `isoloom.yml`, `build/`, `provision/` and `tests/`, then run `isoloom generate`; do not add orchestration scripts.
- After fixes, MUST re-run the full lab validation (same scope as review):
  - Isoloom: `isoloom validate` and `isoloom check` pass; Docker and VM editions both come up and pass `checks:`.
  - Docker: machines healthy, correct ports, non-root.
  - Database: initialization order, user creation before GRANT, privilege separation, connection OK.
  - UI: shadcn-like constraints, dark mode, no warnings/disclaimers, professional layout.
  - Tests: run pytest including evidence extraction path; all must pass.

## Required Validations (map to common findings)
- Database connection must succeed (no "Database connection failed").
- Docker engine compatibility respected (no "Docker version" issues).
- MySQL privileges correct (no mixed global/db GRANT, no CREATE FUNCTION on DB scope).
- UI meets quality checklist (no UI rule violations).

## Process Requirements
- Use env-driven retries and cleanup only via existing tests and the generated `.isoloom/docker/compose.yml`; zero hardcoded timeouts.
- Respect previously established configuration (ports, env var names, healthchecks, DB scripts ordering).
- Document changes by appending a concise summary to `.ctf/REVIEW.md`; produce `.ctf/GOOD.md` only when tests pass.

## Prohibited
- Introducing new ad-hoc runner scripts or custom orchestrators.
- Skipping any validation area (Docker, DB, UI, pytest/evidence extraction).

