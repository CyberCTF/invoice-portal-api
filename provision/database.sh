#!/bin/sh
# Database VM: MariaDB on 3207 with the invoices schema, reachable from the web VM only.
# Then claims this player's evidence and places it (invoice INV-20507's amount).
# An Isoloom VM step: runs as root from the project (/opt/isoloom), with this machine's
# inputs (CTF_API_URL, CTF_LAUNCH_TOKEN); safe to re-run.
set -eu

LAB=/opt/isoloom
# The web machine's address on the lab network (Isoloom writes every machine to /etc/hosts).
WEB_IP="$(getent hosts web | awk '{ print $1 }')"
[ -n "$WEB_IP" ] || { echo "database: can't resolve the web machine" >&2; exit 1; }

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq mariadb-server curl >/dev/null

# Listen on the lab network, on the same port as the Docker edition.
cat > /etc/mysql/mariadb.conf.d/60-lab.cnf <<CNF
[mysqld]
bind-address = 0.0.0.0
port = 3207
CNF
# Debian ships socket activation on 3306, which on boot overrides the port above: the
# service must own its sockets for 3207 to survive a restart of the VM.
systemctl disable --now mariadb.socket mariadb-extra.socket >/dev/null 2>&1 || true
systemctl enable mariadb >/dev/null
systemctl restart mariadb

# Root over the local socket (Debian default); the app user only from the web VM.
mysql <<SQL
CREATE DATABASE IF NOT EXISTS portal;
CREATE USER IF NOT EXISTS 'portal'@'${WEB_IP}' IDENTIFIED BY 'portal-pass';
GRANT SELECT ON portal.* TO 'portal'@'${WEB_IP}';
FLUSH PRIVILEGES;
SQL
# Schema + seed rows on the first run only (re-provisioning keeps the data).
if [ "$(mysql -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='portal' AND table_name='invoices'")" = "0" ]; then
  mysql portal < "$LAB/build/database/init/01-schema.sql"
fi

# Evidence: claimed once (single-use token), then kept on disk across re-provisions.
mkdir -p /var/lib/ctf
CTF_EVIDENCE_FILE=/var/lib/ctf/evidence CTF_DEV_EVIDENCE="15600.00" sh "$LAB/build/database/claim-evidence.sh"
chmod 600 /var/lib/ctf/evidence

# Place it: the amount of invoice INV-20507. Only a decimal number reaches the query.
AMOUNT="$(cat /var/lib/ctf/evidence)"
case "$AMOUNT" in
  ''|*[!0-9.]*) echo "database: unexpected evidence format" >&2; exit 1 ;;
esac
mysql portal -e "UPDATE invoices SET amount = ${AMOUNT} WHERE reference = 'INV-20507';"

echo "database: ready on port 3207"
