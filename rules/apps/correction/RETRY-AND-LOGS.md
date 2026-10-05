# Correction Retries and Logging

Correction retries and logging: env-driven retry policy, progress display, and logs location.

## Retry Policy
- Use `MAX_RETRIES` and `RETRY_DELAY`; no hardcoded values and no infinite loops.
- Exponential or linear backoff allowed; must be configurable via env.

## Live Logging
- Display attempts with timestamps and statuses: `[TIMESTAMP] [ATTEMPT X/Y] [STATUS] [DETAILS]`.
- Write detailed logs under `.ctf/correction_logs/`.

## Artifacts
- Append retry summary to `.ctf/REVIEW.md`.
- If success, create `.ctf/GOOD.md`.
