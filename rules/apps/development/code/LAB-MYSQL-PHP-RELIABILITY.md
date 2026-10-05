# PHP and MySQL lab reliability

Prevent "table missing", empty DB, UNION breakage, and mysqli fatals in PHP+MySQL labs (single rule).

## Purpose

- Keep DB schema and PHP code aligned.

- Ensure init scripts are re-runnable and always seed data.

- Make UNION-based SQLi labs consistently exploitable (proper comment handling).

- Avoid fatal errors at runtime and provide clear recovery steps.

## Mandatory

1) Database name alignment

- The app DB name MUST match everywhere:

  - `build/web/Dockerfile` `ENV DB_NAME=<db>` (or app default) and the VM unit `Environment=DB_NAME=<db>`

  - `build/database/init/01-create-database.sql`: `CREATE DATABASE IF NOT EXISTS <db>;` then `USE <db>;`

  - `web/src/config.php` default `db_name = '<db>'`

- CI-blocker: Fail if these differ.

2) Users and grants match

- `02-create-users.sql`: create `app_user` with the same password used by the web app.

- `03-grant-privileges.sql`: `GRANT SELECT, INSERT, UPDATE, DELETE ON <db>.* TO 'app_user'@'%';` then `FLUSH PRIVILEGES;`

- CI-blocker: Fail if user or password differ between SQL, Dockerfile ENV, the VM step and config.php.

3) Idempotent MySQL init (re-runnable)

- `01-create-database.sql`: `CREATE DATABASE IF NOT EXISTS <db>;` + `USE <db>;`

- `04-init-data.sql`:

  - `USE <db>;`

  - `CREATE TABLE IF NOT EXISTS ...` for all tables the PHP queries reference (e.g., `clients`, `portfolios`, `transactions`, `admin_credentials`)

  - Seed with `INSERT IGNORE` (or "insert-if-missing") so reruns never break.

- CI-blocker: Fail if a PHP-referenced table isn't created in `init/*.sql`.

4) Readiness and port standardization

- DB Dockerfile sets custom port and charset:

  - `/etc/mysql/conf.d/custom.cnf` includes `port=<port>`, UTF8MB4.

- `isoloom.yml` declares that port in the database machine's `services:`; the VM step configures the same port.

- Scripts that wait for the database use `mysqladmin ping -uroot -p"<rootpass>" -h 127.0.0.1 -P <port>` (host + `-P` for TCP) in a bounded loop.

5) Web runtime safety (no fatals)

- In `web/src/config.php`:

  - `mysqli_report(MYSQLI_REPORT_OFF);`

  - `set_charset('utf8mb4')`

  - On query failure: `error_log($conn->error)` and return gracefully (no crash).

- Optional but recommended "self-healing":

  - `initializeSchemaIfNeeded($conn)` to create minimal tables and seed if DB is empty (prevents "No results found"/"Table doesn't exist" on first boot).

6) UNION exploitability consistency (for SQLi labs)

- Vulnerable query should be UNION-friendly:

  - Prefer a single `LIKE` against a concatenation:  

    `WHERE CONCAT_WS(' ', p.portfolio_name, c.client_name, c.account_number) LIKE '%".$q."%'`

  - Do NOT append server-side conditions after user input that would invalidate trailing comments.

- Comments must be accepted:

  - Ensure payloads with `-- ` (note the space) and `#` both work.

- Rendering tolerant to UNION results:

  - If a numeric field receives a string via UNION, display the string (don't cast-only).

  - Use null-coalescing to avoid notices on missing columns.

7) Settings consistency

- `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASS` in the Dockerfile ENV and the VM step match:

  - the database port declared in `isoloom.yml`, SQL users/grants, and config defaults in `web/src/config.php`.

8) Reinit instructions (documented in README)

- To force init scripts to run:  

  `docker compose -f .isoloom/docker/compose.yml down -v && docker compose -f .isoloom/docker/compose.yml up -d --build --wait`

- Add a quick MySQL check command in README to verify data presence.

## Quick automated checks (CI-blockers)

- Fail if:

  - `DB_NAME` mismatch between Dockerfile ENV, VM step, `config.php`, and `01-create-database.sql`.

  - Any PHP `FROM <table>`/`JOIN <table>` has no matching `CREATE TABLE` in `init/*.sql`.

  - `04-init-data.sql` missing `USE <db>;` at top.

  - `02-create-users.sql` user/password differ from `web/src/config.php`, Dockerfile ENV or the VM step.

  - `03-grant-privileges.sql` not granting on `<db>.*` to the app user.

  - Vulnerable search query not using single `LIKE` with `CONCAT_WS` (or is followed by server-side SQL that would defeat `-- `/`#` comments).

## Troubleshooting playbook (developer)

- Empty results or missing tables:

  - `docker compose -f .isoloom/docker/compose.yml down -v && docker compose -f .isoloom/docker/compose.yml up -d --build --wait`

- UNION not working:

  - Ensure payload uses `' ... -- ` (with space) or `#`

  - Ensure the vulnerable query is a single `LIKE` on concatenated fields.

- Still failing:

  - Check logs: `docker compose -f .isoloom/docker/compose.yml logs web`

  - Sanity check DB: `SHOW TABLES; SELECT COUNT(*) FROM portfolios; SELECT * FROM admin_credentials;`
