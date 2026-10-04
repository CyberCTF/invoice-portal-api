#!/bin/sh
# Reads this player's evidence (an AMOUNT) from /run/ctf/evidence and sets it as
# the amount of invoice INV-20507. Idempotent.
set -eu

EVIDENCE_FILE="${CTF_EVIDENCE_FILE:-/run/ctf/evidence}"
[ -s "$EVIDENCE_FILE" ] || { echo "place-evidence: no evidence file" >&2; exit 1; }
AMOUNT="$(cat "$EVIDENCE_FILE")"
# Accept only a decimal number, so nothing else can reach the query.
case "$AMOUNT" in
  ''|*[!0-9.]*) echo "place-evidence: unexpected evidence format" >&2; exit 1 ;;
esac

until mysql -h"${DB_HOST:-database}" -P"${DB_PORT:-3207}" -uroot \
  -p"${MYSQL_ROOT_PASSWORD}" -e "SELECT 1" >/dev/null 2>&1; do
  sleep 2
done

mysql -h"${DB_HOST:-database}" -P"${DB_PORT:-3207}" -uroot \
  -p"${MYSQL_ROOT_PASSWORD}" "${DB_NAME:-portal}" \
  -e "UPDATE invoices SET amount = ${AMOUNT} WHERE reference = 'INV-20507';"
echo "place-evidence: invoice amount placed"
