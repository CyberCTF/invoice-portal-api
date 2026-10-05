# Settings and environment variables

Where lab settings live (Dockerfile ENV, app defaults, systemd units), launcher inputs, and the variables tests use.

## Lab settings

- Docker: `ENV` in the machine's Dockerfile, or defaults in the app (`getenv('DB_PORT') ?: '3207'`).
  There is no `environment:` key in `isoloom.yml`.
- VM: the same values in the systemd unit (`Environment=`) or the service's config file.
- Common app settings: `DB_HOST` (the machine name, e.g. `database`), `DB_PORT`, `DB_NAME`,
  `DB_USER`, `DB_PASS`, `TZ`, `DB_CHARSET`, `DB_COLLATION`.
- No host port variables (`WEB_PORT`, `DB_HOST_PORT`): ports are declared in `isoloom.yml`.

## Launch-time inputs

Only values declared in `inputs:` arrive at runtime, and only on machines that list them:

- `CTF_API_URL`, `CTF_LAUNCH_TOKEN`: set by the CyberCTF launcher, used to claim the evidence
  (see `EVIDENCE-INJECTION.md`). Empty in local runs, CI and pytest.

## Test variables

- `APP_BASE_URL`: base URL of the published entry point (default `http://localhost:<publish port>`)
- `RETRY_DELAY`, `MAX_RETRIES`: retry policy
- `CLEANUP_BEFORE_TESTS`, `REMOVE_VOLUMES`: cleanup policy
- `ENABLE_TIMING`, `TIMING_LOG_LEVEL`, `TIMING_LOG_RETENTION_DAYS`: phase timing

See `apps/development/tests/test-env-vars.md`.
