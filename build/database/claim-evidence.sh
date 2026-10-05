#!/bin/sh
# Fetches this player's evidence for the lab and writes it to $CTF_EVIDENCE_FILE
# (default /run/ctf/evidence) for the lab's services to place in their data.
#
# Runs in the `evidence` service of docker-compose.yml (see
# .cursor/rules/apps/run/EVIDENCE-INJECTION.mdc). Environment, identical for
# every lab:
#   CTF_API_URL, CTF_LAUNCH_TOKEN  set by the CyberCTF launcher (single-use token)
#   CTF_DEV_EVIDENCE               this lab's fixed development value, used when
#                                  there is no token (local dev, CI, pytest)
set -eu

OUT="${CTF_EVIDENCE_FILE:-/run/ctf/evidence}"
mkdir -p "$(dirname "$OUT")"
umask 022

# Restarting the stack keeps the volume: the token has already been used, and the
# evidence is already in place.
if [ -s "$OUT" ]; then
  echo "evidence: already present"
  exit 0
fi

if [ -z "${CTF_LAUNCH_TOKEN:-}" ]; then
  : "${CTF_DEV_EVIDENCE:?CTF_DEV_EVIDENCE must be set when no launch token is given}"
  printf '%s' "$CTF_DEV_EVIDENCE" > "$OUT"
  echo "evidence: using the development value"
  exit 0
fi

: "${CTF_API_URL:?CTF_API_URL must be set with CTF_LAUNCH_TOKEN}"
case "$CTF_LAUNCH_TOKEN" in
  *[!A-Za-z0-9_.-]*) echo "evidence: malformed launch token" >&2; exit 1 ;;
esac

body='{"query":"mutation($t:String!){claimLabEvidence(launchToken:$t)}","variables":{"t":"'"$CTF_LAUNCH_TOKEN"'"}}'
response=$(curl -fsS --max-time 20 --retry 3 --retry-connrefused \
  -H 'content-type: application/json' --data "$body" "$CTF_API_URL")

# Evidence alphabets never contain quotes or backslashes, so a plain match is safe.
value=$(printf '%s' "$response" | sed -n 's/.*"claimLabEvidence":"\([^"\\]*\)".*/\1/p')
if [ -z "$value" ]; then
  echo "evidence: claim failed: $response" >&2
  exit 1
fi

printf '%s' "$value" > "$OUT"
echo "evidence: claimed"
