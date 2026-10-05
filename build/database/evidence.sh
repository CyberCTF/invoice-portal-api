#!/bin/sh
# Containers: claims this player's evidence (kept in the machine's volume, the token is
# single-use) and places it once the database answers. Runs as an Isoloom init job, in the
# database's network namespace.
set -eu
export CTF_EVIDENCE_FILE=/var/lib/ctf/evidence CTF_DEV_EVIDENCE="15600.00"
sh /opt/ctf/claim-evidence.sh
DB_HOST=127.0.0.1 DB_PORT=3207 DB_NAME=portal MYSQL_ROOT_PASSWORD=root-pass-9f2c sh /opt/ctf/place-evidence.sh
