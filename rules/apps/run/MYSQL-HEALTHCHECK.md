# MySQL readiness and ports

MySQL machine readiness and port setup on containers and VMs, to avoid false health and wrong ports.

## Port

- Declare the port in `isoloom.yml`: `services: [{ port: 3207, name: mysql }]`.
- Docker: set it in the Dockerfile, `ENV MYSQL_TCP_PORT=3207` (official image) or a `COPY`'d
  `my.cnf` with `port = 3207`.
- VM: a config file with `port = 3207` and `bind-address = 0.0.0.0`. Disable socket activation
  that would keep 3306 (Debian `mariadb.socket`).
- The app reads `DB_PORT`, default 3207 (never 3306).

## Readiness

- Isoloom marks the machine healthy when 3207 accepts connections. The official MySQL image
  only opens TCP after its init scripts finish, so the generated check is enough.
- Machines that query the database list it in `depends_on`.
- Scripts that need the database (evidence placement, provisioning) wait with a bounded loop:

```sh
i=0
until mysql -h127.0.0.1 -P3207 -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
  i=$((i + 1)); [ "$i" -lt 90 ] || { echo "the database never answered" >&2; exit 1; }
  sleep 2
done
```

- Always quote the password (`-p"$MYSQL_ROOT_PASSWORD"`).
- A custom `HEALTHCHECK` in the Dockerfile is fine for local use, but the generated compose file
  uses its own port check.

## Initialization scripts

- Docker: `COPY init/ /docker-entrypoint-initdb.d/` in `build/database/Dockerfile`.
- VM: load the same `build/database/init/*.sql` from `/opt/isoloom` on the first run only.
- Scripts create the database first, then users, then grants (separate DB and global
  privileges), all with `IF NOT EXISTS`.
