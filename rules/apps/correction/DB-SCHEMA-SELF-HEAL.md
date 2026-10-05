# DB Schema Self-Heal and Init Reliability

Prevent missing-table runtime errors by ensuring schema existence at app start and reliable init scripts.

## Goal

Avoid runtime errors like: SQLSTATE[42S02]: Base table or view not found: 1146 Table 'client_repos.repositories' doesn't exist.

## Requirements

Init SQL MUST create all required tables in the target database (client_repos) using numbered files (01-, 02-, 03-, 04-...).

Web apps SHOULD defensively ensure critical tables exist on startup (idempotent CREATE TABLE IF NOT EXISTS ...).

The database Dockerfile MUST copy init scripts to /docker-entrypoint-initdb.d, and the VM provision step MUST load the same files. MySQL listens on 3207, as declared in isoloom.yml.

The app machine MUST list the database in depends_on, and handle a database that is not ready yet.

## Implementation

In web startup/DB bootstrap, execute minimal idempotent DDL for critical tables after obtaining a connection.

Example (PDO): CREATE TABLE IF NOT EXISTS repositories (...) matching the init script schema.

Keep the canonical schema in init SQL (e.g., 04-init-data.sql), and ensure the web bootstrap only mirrors essential structure.

## Init

Docker: COPY init/ /docker-entrypoint-initdb.d/ in build/database/Dockerfile. VM: load build/database/init/*.sql from /opt/isoloom on the first run.

DB port: 3207 (not 3306). Ensure PHP uses DB_PORT env var.

Use MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD (Dockerfile ENV) for base provisioning, plus explicit SQL for tables and data.

## Validation

Running the app from a fresh or reused DB volume must not produce 42S02 errors.

Tables exist after first request even if init scripts were skipped due to an existing data directory.

## Notes

This rule is additive hardening; it does not replace proper init SQL. Always keep schema in versioned SQL and mirror only what is necessary at runtime.
