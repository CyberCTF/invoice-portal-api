# Other Configurations

Non-functional requirements: TZ/UTF-8, structured logging, env-driven retries/cleanup, CI hints.

## Localization and Time

- Define `TZ` explicitly and ensure application/DB use expected charset/collation.
- Use UTF-8 encoding for all text data.

## Logging

- Structured logs (key=value/JSON) and levels configurable via environment variables.
- No error display in production (PHP). Errors must be logged.

## Tests and Robustness

- Before each test execution: perform cleanup (`docker compose -f .isoloom/docker/compose.yml down -v`), driven by environment variables (no hardcoding).
- Centralized retries/backoff 100% configurable via env (no hardcoded values).
- No hardcoded URLs in tests. Use `APP_BASE_URL` (defaults to the published port).
- Tests must wait for readiness (`up --wait`, then the health endpoint with backoff).

## CI/CD

- Validate presence of required environment variables/secrets, with explicit error messages.
- Consistent caching based on lockfiles; documented invalidation.
- Multi-platform builds enabled.

## Network Timeouts

- Critical network operations (pull/build/test) must support retries configurable via env.

## Phase Timing

- Track start/end/duration for each phase (Plan, Lab, Review, Metadata) in `.ctf/timing_logs/`. Behavior is enableable/disableable via env.
