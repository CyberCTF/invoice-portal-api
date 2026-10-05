# Rules Overview

Rules overview and workflow reference (informational).

## Phases
1. Context creation → outputs `.ctf/SCENARIO.md` + `.ctf/EVIDENCE.md`
2. Lab Generation → outputs `isoloom.yml` + `build/` + `provision/` + `tests/` + generated `.isoloom/`
3. Review (assessment-only) → outputs `.ctf/REVIEW.md` + `.ctf/review_logs/`
4. Correction (apply fixes) → consumes `.ctf/REVIEW.md`, updates `isoloom.yml` + `build/` + `provision/` + `tests/`, outputs `.ctf/correction_logs/` and optional `.ctf/GOOD.md`
5. Metadata → outputs `.ctf/metadata.json`

## Triggers
- Start Review after Lab Generation artifacts exist.
- Start Correction when `.ctf/REVIEW.md` exists and `.ctf/GOOD.md` is absent.
- Start Metadata after Correction is complete or when `.ctf/GOOD.md` is present.

See [`../AGENTS.md`](../AGENTS.md) for the lab model, the critical rules and the index of every rule file.
