# Database-Specific Critical Errors

Database-specific critical errors in the points-based enforcement system.

**These database errors are ABSOLUTELY FORBIDDEN and result in massive point loss (-500 points each):**

1. **User Creation Before GRANT** (-500 points)
   - Granting privileges to users that don't exist
   - Missing `CREATE USER` statements before `GRANT` statements
   - **CORRECT**: Always create users BEFORE granting privileges, use `IF NOT EXISTS`

2. **MySQL Privilege Separation Errors** (-500 points)
   - Mixing database-specific and global privileges in single GRANT statement
   - Error: "Incorrect usage of DB GRANT and GLOBAL PRIVILEGES"
   - Using `CREATE FUNCTION` on database-specific grants (syntax error)
   - **CORRECT**: Separate database privileges (`ON database.*`) from global privileges (`ON *.*`), use `CREATE ROUTINE` instead of `CREATE FUNCTION`

3. **Database Initialization Order** (-500 points)
   - Scripts executed in wrong order (grants before user creation, data before tables)
   - Missing numbered prefixes (01-, 02-, 03-) for init scripts
   - **CORRECT**: Use numbered prefixes: 01-create-database.sql, 02-create-users.sql, 03-grant-privileges.sql, 04-init-data.sql

4. **Database Connection Failures** (-500 points)
   - "Database connection failed" errors in applications
   - Wrong connection parameters (host, port, credentials)
   - Missing `IF NOT EXISTS` causing duplicate user errors
   - **CORRECT**: Test connections, use proper credentials, include `IF NOT EXISTS` in user creation

5. **MySQL Port Configuration** (-500 points)
   - PHP/application using default port 3306 instead of custom port (3207)
   - Missing port parameter in connection strings
   - Database not listening on assigned port
   - **CORRECT**: Always use `DB_PORT` environment variable, default to 3207 (not 3306)

6. **MySQL Readiness Errors** (-500 points)
   - Database not listening on the port declared in `isoloom.yml` (Isoloom's health check connects to it)
   - Scripts pinging the database on the wrong port or with an unquoted password
   - **CORRECT**: Listen on 3207 on both editions; wait with `mysql -h127.0.0.1 -P3207 -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1"` in a bounded loop

7. **MySQL 5.6 Compatibility Errors** (-500 points)
   - Using `CREATE USER IF NOT EXISTS` on MySQL 5.6 (not supported before 5.7.3)
   - Index length exceeding 767 bytes with utf8mb4 on VARCHAR(255)
   - **CORRECT**: For MySQL 5.6, use the image's `MYSQL_USER`/`MYSQL_PASSWORD` (Dockerfile `ENV`) for user creation, use prefix indexes (191) for VARCHAR(255) with utf8mb4

8. **Database Name Alignment Errors** (-500 points)
   - `DB_NAME` (Dockerfile `ENV`, VM unit) or `config.php` default does not match database created in SQL init scripts
   - Application trying to connect to database that doesn't exist
   - Database name mismatch between PHP code and SQL init scripts
   - **CORRECT**: `DB_NAME` env/default MUST exactly match the database name created in `CREATE DATABASE IF NOT EXISTS <db>;` in init scripts

9. **Missing Idempotent MySQL Init** (-500 points)
   - Init scripts missing `CREATE DATABASE IF NOT EXISTS <db>;`
   - Init scripts missing `USE <db>;` after database creation
   - Tables created without `CREATE TABLE IF NOT EXISTS`
   - Seed data not using `INSERT IGNORE` or insert-if-missing patterns
   - **CORRECT**: Every init sequence MUST include `CREATE DATABASE IF NOT EXISTS <db>;` and `USE <db>;`, all tables use `IF NOT EXISTS`, seed data uses `INSERT IGNORE`

10. **Page-to-Table Parity Errors** (-500 points)
    - PHP pages querying tables that don't exist in SQL init scripts
    - Tables referenced in `FROM` or `JOIN` clauses without matching `CREATE TABLE` statements
    - "Table 'X.Y' doesn't exist" errors at runtime
    - Example: `items.php` queries `services` table but no `CREATE TABLE services` in init SQL
    - **CORRECT**: Every table referenced in PHP code MUST have a matching `CREATE TABLE` statement in `build/database/init/*.sql`

11. **Unsafe mysqli Usage (Fatal Exceptions)** (-500 points)
    - mysqli exception mode not disabled globally
    - Fetching rows without checking `$result !== false` first
    - Database errors causing fatal exceptions that crash pages
    - Raw database error messages shown to users
    - **CORRECT**: Disable exception mode with `mysqli_report(MYSQLI_REPORT_OFF);`, only fetch when `$result !== false`, log errors server-side (`error_log`), render neutral UI text

12. **Missing MySQL Root Password** (-500 points)
    - Skipping `MYSQL_ROOT_PASSWORD` or attempting root logins without a password
    - Healthchecks failing with `Access denied for user 'root'@'127.0.0.1' (using password: NO)` or Apache refusing to start because the DB never initializes
    - **CORRECT**: Define and quote `MYSQL_ROOT_PASSWORD` (Dockerfile `ENV`; the VM step uses the same value or the local socket), pass it in all root-level commands (`mysqladmin ping -uroot -p"$MYSQL_ROOT_PASSWORD"`), and never rely on anonymous root access
