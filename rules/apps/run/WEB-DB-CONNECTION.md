# Web to DB connection contract

Web to DB connection contract for PHP apps (mysqli/PDO).

## PHP mysqli/PDO
- Always pass the port from the environment:
  - PHP: `$dbPort = getenv('DB_PORT') ?: '3207';`
- mysqli: `new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, (int)$dbPort)`
- PDO: `new PDO("mysql:host=$host;port=$dbPort;dbname=$db;charset=utf8mb4", ...)`

## Defaults
- Host default is the database machine's name in `isoloom.yml` (e.g. `database`), never an IP.
- Fallback port MUST be 3207 (not 3306), matching the database machine's `services:` port.
- The same values work on both editions: the Docker image defaults and the VM's systemd unit.
