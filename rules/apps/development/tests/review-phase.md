# Review Phase (Assessment-Only)

Review Phase: assessment-only checklist and outputs for lab validation.

Follow this checklist to validate the lab without making code/config changes. Document all findings; do not fix in this phase.

## Scope
- Validate `isoloom.yml` and both editions (Docker and VM: health, ports, non-root, checks)
- Validate Database (init order, grants, connectivity)
- Validate UI (dark-only PHP UI, professionalism, accessibility)
- Validate Tests (pytest coverage per requirements)

## Inputs
- `build/` services and configs (web, database, etc.)
- `isoloom.yml`, `provision/`, and the generated `.isoloom/`
- `tests/` pytest suite
- `.ctf/` existing artefacts

## Required Checks
1) Isoloom and Docker
   - `isoloom validate` and `isoloom check` pass (`.isoloom/` current, never hand-edited)
   - No root `docker-compose.yml`, no `build/docker-compose.dev.yml`, no `deploy/`
   - Every machine has `docker:` and `vm:` (or a recorded reason for one edition only)
   - Services listen on their declared ports; only the entry point is `publish:`ed
   - Docker edition comes up with `--wait` and `isoloom-check` passes
   - VM edition provisions with `vagrant up` and `build/check/check.sh` passes
   - Non-root users where applicable
   - See `../../review/ISOLOOM-VALIDATION.md`

2) Database
   - Init order: create DB → create users → grants → data
   - No mixing global and DB privileges; use `CREATE ROUTINE` instead of `CREATE FUNCTION` for DB-level
   - `IF NOT EXISTS` where supported; connection succeeds

3) UI (PHP Dark-Only)
   - Root `<html class="theme-dark">`; no light mode or toggles
   - Uses tokens from `COLORS`, `TYPOGRAPHY`, `SPACING`
   - Professional, minimalist; WCAG AA contrast; keyboard/accessibility basics

4) Tests
   - Coverage per `TEST-REQUIREMENTS.md`
   - Retry behavior per `TEST-RETRY.md` (env-driven; no hardcoded values)
   - Cleanup per `TEST-EXECUTION.md` (`docker compose -f .isoloom/docker/compose.yml down -v` via env)
   - Phase timing logs per `PHASE-TIMING.md`

## Outputs
- `.ctf/REVIEW.md` with categorized findings (Isoloom, Docker, VM, Database, UI, Tests)
- `.ctf/review_logs/` detailed logs if available
- Do not edit code/config; only record findings

## Pass/Fail Criteria
- PASS: No critical findings; all checks satisfied → produce `.ctf/GOOD.md` (empty file)
- FAIL: Document precise issues and remediation hints in `.ctf/REVIEW.md`

## Notes
- This phase is assessment-only. Corrections occur in the Correction phase and must re-validate both editions (Docker and VM).
 
