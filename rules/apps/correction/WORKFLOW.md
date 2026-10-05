# Correction Workflow

Correction workflow: consume REVIEW.md, implement fixes, rerun tests with bounded retries, document outcomes.

## Steps
1. Ingest findings from `.ctf/REVIEW.md` and categorize (Isoloom, Docker, VM, DB, App/UI, Tests, Docs).
2. Implement fixes in `isoloom.yml`, `build/`, `provision/` and `tests/` according to development/run rules, then run `isoloom generate`.
3. Rerun tests with env-driven retries; log each attempt and status.
4. Update `.ctf/REVIEW.md` with corrections summary; if all pass, create `.ctf/GOOD.md`.

## Constraints
- No changes to `.ctf/` inputs except appending results.
- Respect `isoloom.yml`: declared service ports, both editions, never hand-edit `.isoloom/`.
- Enforce DB init order and GRANT separation.
- Maintain UI professionalism (no warnings), follow design system.

## Success Criteria
- All tests pass reliably.
- Both editions healthy, ports correct, `checks:` pass.
- Evidence extractable through the exploit and claimed into the machine volume and placed at startup on both editions.
- Documentation coherent and professional.
