#!/bin/sh
# The database's `setup` step (isoloom.yml `setup: [build/database/evidence.sh]`): claims this
# player's evidence (kept in the machine's `evidence` volume, the token is single-use) and places
# it as the amount of invoice INV-20507 once the database answers. It runs on every target with the
# project mounted at /opt/isoloom, and reaches the database over local TCP as root. The launch
# token is read from its delivered file (/run/lab/launch-token), never from the environment.
set -eu
export CTF_EVIDENCE_FILE=/var/lib/ctf/evidence CTF_DEV_EVIDENCE="15600.00"
export CTF_LAUNCH_TOKEN_FILE="${CTF_LAUNCH_TOKEN_FILE:-/run/lab/launch-token}"
# The helpers live in the project, which Isoloom mounts at /opt/isoloom on every target.
DB=/opt/isoloom/build/database
sh "$DB/claim-evidence.sh"
DB_HOST=127.0.0.1 DB_PORT=3207 DB_NAME=portal MYSQL_ROOT_PASSWORD=root-pass-9f2c sh "$DB/place-evidence.sh"
