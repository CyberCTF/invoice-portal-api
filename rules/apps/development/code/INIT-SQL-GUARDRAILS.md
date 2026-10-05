# Init SQL guardrails

Init SQL guardrails: order, indexes, where the files load (MySQL 5.6/5.7/8).

## Order
1) 01-create-database.sql
2) 02-create-users.sql (CREATE USER IF NOT EXISTS) → GRANT → FLUSH PRIVILEGES
3) 03-*.sql (tables, data)

## Indexes
- No prefix length > column length.
- For VARCHAR(100): use `INDEX idx_username (username)` (no `(191)`).
- For utf8mb4 + VARCHAR(255) on MySQL 5.6, only then consider 191 prefix.

## Loading
- Docker: `COPY init/ /docker-entrypoint-initdb.d/` in `build/database/Dockerfile`
- VM: `provision/database.sh` loads the same files from `/opt/isoloom/build/database/init/` on the first run
