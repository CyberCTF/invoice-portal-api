#!/bin/sh
# Database VM: MariaDB on 3207 with the invoices schema, reachable from the web VM only, and a
# local root login matching the Docker image's so the shared `setup` step places the evidence the
# same way on every target. An Isoloom VM step: runs as root from the project (/opt/isoloom).
# Safe to re-run.
set -eu

LAB=/opt/isoloom
# The web machine's address on the lab network (Isoloom writes every machine to /etc/hosts).
WEB_IP="$(getent hosts web | awk '{ print $1 }')"
[ -n "$WEB_IP" ] || { echo "database: can't resolve the web machine" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq mariadb-server curl >/dev/null

# Listen on the lab network, on the same port as the Docker edition. Match hosts by IP
# (skip-name-resolve) so the `setup` step's 127.0.0.1 TCP login lands on root@'127.0.0.1' instead of
# being resolved to 'localhost', which MariaDB authenticates by unix socket, not by password.
cat > /etc/mysql/mariadb.conf.d/60-lab.cnf <<CNF
[mysqld]
bind-address = 0.0.0.0
port = 3207
skip-name-resolve
CNF
# Debian ships socket activation on 3306, which on boot overrides the port above: the
# service must own its sockets for 3207 to survive a restart of the VM.
systemctl disable --now mariadb.socket mariadb-extra.socket >/dev/null 2>&1 || true
systemctl enable mariadb >/dev/null
systemctl restart mariadb

# Root over the local socket (Debian default); the app user only from the web VM. The `setup` step
# (build/database/evidence.sh) places the evidence as root over local TCP, the same way it does
# against the Docker image, so give the VM a matching root@127.0.0.1 login with the image's password
# (local-only: a remote root login from the web VM matches no account and is refused).
mysql <<SQL
CREATE DATABASE IF NOT EXISTS portal;
CREATE USER IF NOT EXISTS 'portal'@'${WEB_IP}' IDENTIFIED BY 'portal-pass';
GRANT SELECT ON portal.* TO 'portal'@'${WEB_IP}';
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY 'root-pass-9f2c';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
# Schema + seed rows on the first run only (re-provisioning keeps the data).
if [ "$(mysql -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='portal' AND table_name='invoices'")" = "0" ]; then
  mysql portal < "$LAB/build/database/init/01-schema.sql"
fi

# The evidence (invoice INV-20507's amount) is claimed and placed by the `setup` step
# (build/database/evidence.sh), which runs on every target once the database answers.
echo "database: ready on port 3207"
