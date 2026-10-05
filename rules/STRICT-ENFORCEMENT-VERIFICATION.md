# Compliance Verification Checklists

Compliance verification checklists for the points-based enforcement system.

Before declaring ANY task complete, you MUST verify:

- [ ] All syntax checks passed (0 errors)
- [ ] All linting checks passed (0 errors)
- [ ] All tests executed and passed
- [ ] All required files created/updated correctly
- [ ] All directory rules followed
- [ ] All workflow phases completed
- [ ] All validation steps executed
- [ ] All documentation updated
- [ ] Repository README matches the mandated template (structure, wording, and length)
- [ ] `.ctf/metadata.json` description limited to 1–2 short sentences and overall length ≤ 320 characters
- [ ] `dev_evidence` (metadata + `.ctf/EVIDENCE.md` + `CTF_DEV_EVIDENCE` in the Docker `init` script and the VM provision step) is the same bare value with no extra prose
- [ ] The evidence is claimed into the machine's `volumes:` path and placed at startup on both editions, never hard-coded in SQL, source or images
- [ ] All configuration correct
- [ ] Zero point deductions incurred

## ISOLOOM VERIFICATION CHECKLIST

- [ ] `isoloom validate` passes
- [ ] `isoloom check` passes (`.isoloom/` regenerated and committed, never hand-edited)
- [ ] No root `docker-compose.yml`, no `build/docker-compose.dev.yml`, no `deploy/` folder
- [ ] Every machine has `docker:` and `vm:` (or a recorded reason for one edition only)
- [ ] `inputs: [CTF_API_URL, CTF_LAUNCH_TOKEN]` at the top and on the claiming machine, with a `volumes:` path for the evidence
- [ ] Only the entry point has `publish:`, on the same port as its service
- [ ] `checks: [build/check/check.sh]` passes on Docker (`--profile check run --rm isoloom-check`)
- [ ] VM edition provisions (`cd .isoloom/vagrant && vagrant up`) and the check passes from a machine

## DOCKER VERIFICATION CHECKLIST

- [ ] Dockerfile syntax valid (no "unknown instruction" errors)
- [ ] No raw `<VirtualHost>` or `<Directory>` tags in RUN commands (properly escaped or using COPY)
- [ ] No `environment:` key; settings in Dockerfile `ENV` or app defaults, passwords quoted
- [ ] Database machine uses `docker: { build: build/database }` (NEVER a bare `image:`)
- [ ] Services listen on their declared `services:` ports
- [ ] `depends_on` lists the machines each machine needs
- [ ] Apache/Nginx configured to listen on custom port (not just 80)
- [ ] `docker compose -f .isoloom/docker/compose.yml up -d --build --wait` comes up healthy

## VM VERIFICATION CHECKLIST

- [ ] One idempotent step per machine in `provision/` (`#!/bin/sh`, `set -eu`)
- [ ] Same ports, data, users and evidence placement as the Docker edition
- [ ] Services run under systemd, enabled at boot, as non-root users
- [ ] Each step waits (bounded) until its service answers

## DATABASE VERIFICATION CHECKLIST

- [ ] All database users created BEFORE granting privileges
- [ ] `CREATE USER IF NOT EXISTS` used (or the image's `MYSQL_USER` ENV for MySQL 5.6)
- [ ] Database and global privileges separated into different GRANT statements
- [ ] `CREATE ROUTINE` used instead of `CREATE FUNCTION` for database grants
- [ ] Init scripts use numbered prefixes (01-, 02-, 03-) for correct order
- [ ] Database connection tested and working
- [ ] PHP/application uses `DB_PORT` environment variable (defaults to 3207, not 3306)
- [ ] Scripts that ping MySQL use the correct port (`-P 3207`) with a quoted password
- [ ] MySQL 5.6 compatibility checked (no `CREATE USER IF NOT EXISTS` if using 5.6)
- [ ] `DB_NAME` (Dockerfile `ENV`, VM unit, app default) matches database created in SQL init scripts
- [ ] All init scripts include `CREATE DATABASE IF NOT EXISTS <db>;` and `USE <db>;`
- [ ] All tables use `CREATE TABLE IF NOT EXISTS`
- [ ] Seed data uses `INSERT IGNORE` or insert-if-missing patterns
- [ ] All tables referenced in PHP code (FROM/JOIN) have matching `CREATE TABLE` in init SQL
- [ ] No "Table 'X.Y' doesn't exist" errors (verified by checking all PHP queries against init SQL)
- [ ] `mysqli_report(MYSQLI_REPORT_OFF);` is set globally or in DB wrapper
- [ ] All mysqli queries check `$result !== false` before fetching rows
- [ ] Database errors logged server-side (`error_log`) and not shown to users
- [ ] Neutral UI text rendered when database errors occur (no fatal exceptions)

## APACHE VERIFICATION CHECKLIST

- [ ] Apache `Listen` directive includes custom port (not just 80)
- [ ] VirtualHost configured for custom port
- [ ] Apache configuration in Dockerfile properly escaped (no raw tags)
- [ ] `.htaccess` file exists at web root with proper rewrite rules
- [ ] Required Apache modules enabled (`a2enmod rewrite`)
- [ ] `ServerName` configured in Apache
- [ ] Apache answers on the assigned port on both editions

## NGINX VERIFICATION CHECKLIST

- [ ] Nginx `listen` directive includes custom port (not just 80)
- [ ] `server` blocks properly configured
- [ ] `location` blocks properly configured with `try_files`
- [ ] Nginx configuration syntax valid (`nginx -t` passes)
- [ ] Security headers configured
- [ ] Nginx answers on the assigned port on both editions

## GO VERIFICATION CHECKLIST

- [ ] `go.mod` file exists with correct module path
- [ ] All Go files compile successfully (`go build` passes)
- [ ] `go vet` passes without errors
- [ ] Code is properly formatted (`gofmt` compliant)
- [ ] Package declarations match directory structure
- [ ] All dependencies declared in `go.mod`
- [ ] No undefined variables, functions, or types

## JAVA VERIFICATION CHECKLIST

- [ ] `pom.xml` (Maven) or `build.gradle` (Gradle) exists
- [ ] All Java files compile successfully
- [ ] Package declarations match directory structure
- [ ] All dependencies declared in build configuration
- [ ] No undefined classes, methods, or variables
- [ ] Proper exception handling implemented

## NODEJS VERIFICATION CHECKLIST

- [ ] `package.json` exists and is valid JSON
- [ ] All dependencies declared in `package.json`
- [ ] All `require()` or `import` statements resolve correctly
- [ ] No circular dependencies
- [ ] Express routes have proper error handling (if Express is used)
- [ ] Security middleware configured (if Express is used)

## POSTGRESQL VERIFICATION CHECKLIST

- [ ] Init scripts use numbered prefixes (01-, 02-, 03-)
- [ ] All users created BEFORE granting privileges
- [ ] `IF NOT EXISTS` used in user creation
- [ ] No hardcoded passwords in scripts
- [ ] Proper privilege separation
- [ ] Scripts in correct initialization directory

## REDIS VERIFICATION CHECKLIST

- [ ] Password authentication enabled (`requirepass` configured)
- [ ] Redis bound to specific IP (not 0.0.0.0 without protection)
- [ ] Custom port configured if required
- [ ] Dangerous commands disabled or renamed
- [ ] Persistence configured if needed
- [ ] Redis answers on the declared port

## UI BLACK TAILWIND VERIFICATION CHECKLIST

- [ ] Tailwind CDN script included in all HTML/PHP pages
- [ ] Tailwind configuration includes only black/white/gray colors
- [ ] `<html class="dark">` present on all pages
- [ ] `<body class="min-h-screen bg-black text-white">` present on all pages
- [ ] No chromatic colors (red, blue, green, etc.) in any styles
- [ ] No `linear-gradient` or `radial-gradient` with colors
- [ ] No inline styles with non-monochrome colors
- [ ] All components use only black/white/gray Tailwind utilities
- [ ] Focus rings use white/gray only (not colors)
- [ ] Hover states use opacity/grayscale (not colors)
- [ ] Links use white text (not colored)
- [ ] Validation passed: no color hex codes except #000000, #FFFFFF, or grayscale
- [ ] Validation passed: regex check for `linear-gradient` returns no matches
- [ ] Background is black (#000000) on all pages
- [ ] Primary text is white (#FFFFFF) on all pages

## WEBSITE-PAGES-ESSENTIALS VERIFICATION CHECKLIST

- [ ] `layout.php` exists with HTML head, Tailwind CDN, and body structure
- [ ] `partials/nav.php` exists with main navigation
- [ ] `partials/footer.php` exists
- [ ] Core pages exist: `index.php`, `items.php`, `item.php`, `search.php`
- [ ] Support pages exist: `contact.php`, `about.php`, `privacy.php`, `terms.php`
- [ ] Admin pages exist: `admin/index.php`, `admin/users.php`
- [ ] Error pages exist: `errors/404.php`, `errors/500.php`
- [ ] `health.php` exists and returns 200 without DB dependency
- [ ] `.htaccess` file exists at web root with rewrite rules
- [ ] All navigation links resolve to real pages (return 200)
- [ ] 404 routes render `errors/404.php`
- [ ] All pages use shared `layout.php` (no duplicated `<head>`)
- [ ] Navigation included via `partials/nav.php` on all pages
- [ ] Footer included via `partials/footer.php` on all pages
- [ ] Auth pages included ONLY when lab requires auth (per-lab dynamic)
- [ ] Registration form minimal (username/password only, no email)
- [ ] Registration uses local/temporary storage (no external services)
- [ ] `dashboard.php` and `profile.php` exist when auth is required
- [ ] Auth pages omitted when lab doesn't require auth
- [ ] Home page (`index.php`) has realistic content (hero/intro + 1–2 sections)
- [ ] Home page is not just lorem-only stub
- [ ] Navigation contains required links: Home, Items, Search, About, Contact
- [ ] Auth links (Login/Register/Logout/Dashboard) shown only when auth required
- [ ] Auth links hidden when auth not needed
- [ ] No raw database error messages shown to users
- [ ] Database errors logged server-side (error_log)
- [ ] Safe mysqli patterns used (no fatal exceptions)
- [ ] Health endpoint returns 200 quickly without database queries
- [ ] SEO files present if applicable: `sitemap.xml`, `robots.txt`
