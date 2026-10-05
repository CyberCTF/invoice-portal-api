# Correction Phase Overview

Correction phase: purpose, scope, and alignment with review findings.

## Purpose
- Apply fixes based on `.ctf/REVIEW.md` findings to produce a high-quality lab.
- Keep changes scoped to `isoloom.yml`, `build/`, `provision/`, `tests/` and the regenerated `.isoloom/`; do not alter `.ctf/` except to append outcomes.

## Scope
- `isoloom.yml` (machines, ports, inputs, checks), Dockerfiles, VM provision steps
- Database init scripts and privileges
- Application code and UI
- Tests and test configuration

## Coordination
- Use outputs from Review (`.ctf/REVIEW.md`, `.ctf/review_logs/`) to drive corrections.
- When complete, run tests and produce final outputs per the correction outputs spec.
