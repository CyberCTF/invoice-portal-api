# Critical Errors Quick Reference

High-signal guardrails: package manager mismatch, obsolete packages, quoting in Dockerfile ENV, ports, MySQL grants.

## Top 7 Docker Errors to AVOID

1. **Wrong Package Manager** (`apt-get` on Oracle Linux)
   - Error: `apt-get: command not found`
   - Solution: Use `microdnf` for MySQL/Oracle Linux images
   - See: [../docker/PACKAGES.md](../docker/PACKAGES.md#base-images-and-package-managers)

2. **Obsolete Package** (`libmysqlclient-dev`)
   - Error: `Package 'libmysqlclient-dev' has no installation candidate`
   - Solution: Use `libmariadb-dev` on recent Debian
   - See: [../docker/PACKAGES.md](../docker/PACKAGES.md#common-dockerfile-errors)

3. **Special Characters in Passwords** (#, @)
   - Error: value cut or expanded, `#` or `$` misread
   - Solution: Quote it: `ENV MYSQL_PASS="value#with@chars"`, `Environment="MYSQL_PASS=value#with@chars"`
   - See: [../run/SYNTAX.md](../../run/SYNTAX.md#special-characters-in-passwords)

4. **Apache Not Listening on Custom Port**
   - Error: machine never healthy, connection refused
   - Solution: Add `Listen 3206` in ports.conf and VirtualHost config
   - See: [../docker/SERVERS.md](../docker/SERVERS.md#apache-configuration-for-custom-ports)

5. **Database User Not Created**
   - Error: `Access denied for user 'app_user'@'localhost'`
   - Solution: Always CREATE USER before GRANT privileges
   - See: [DATABASE.md](DATABASE.md#database-user-creation)

6. **MySQL CREATE FUNCTION Privilege Error**
   - Error: MySQL syntax error with `CREATE FUNCTION` on database-specific grants
   - Solution: Use `CREATE ROUTINE` instead of `CREATE FUNCTION` for database-level privileges
   - See: [DATABASE.md](DATABASE.md#mysql-create-function-error)

7. **MySQL Privilege Mixing Error**
   - Error: `ERROR 1221 (HY000): Incorrect usage of DB GRANT and GLOBAL PRIVILEGES`
   - Solution: Separate database-specific and global privileges into different GRANT statements
   - See: [DATABASE.md](DATABASE.md#mysql-privilege-separation-error)

8. **Missing MySQL Root Password**
   - Error: `Access denied for user 'root'@'127.0.0.1' (using password: NO)` and Apache startup failures
   - Solution: Always set `MYSQL_ROOT_PASSWORD`, quote it in the Dockerfile ENV and the VM step, and ensure every root-level connection passes the same secret
   - See: [DATABASE.md](DATABASE.md#root-password-enforcement)
