# Review Full-Scope Assessment

Review must assess Docker, DB, UI, and pytest including evidence extraction; no code edits in this phase.

## Mandatory Checks
- Isoloom: `isoloom validate` and `isoloom check` pass; both editions (Docker and VM) come up and pass `checks:` (see `ISOLOOM-VALIDATION.md`).
- Docker: images build, machines healthy, services on their declared ports, non-root.
- Database: init order, user-before-GRANT, privilege separation, connection success.
- UI: design system compliance (shadcn-like, dark mode, professional), no warnings/disclaimers.
- Tests: run pytest and verify evidence extraction path; ensure coverage of core workflows.

## Outputs
- Record failures with explicit categories: Isoloom, Docker, VM, Database privilege/connection, UI, Tests/Evidence.
- Write `.ctf/REVIEW.md` and detailed logs in `.ctf/review_logs/`.
- Do not perform any code/config edits in review.

