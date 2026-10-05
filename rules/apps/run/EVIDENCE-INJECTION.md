# Evidence Injection (mandatory for every lab)

How every lab claims the player's evidence at runtime and places it in its data, on containers and VMs.

The evidence is never in the repository or the image. At startup, the machine that holds it
claims this player's value and places it where it belongs in its data. The input names are the
same for every lab. Only the public development value is lab-specific.

## 1. Inputs in `isoloom.yml`

```yaml
inputs: [CTF_API_URL, CTF_LAUNCH_TOKEN]

machines:
  database:
    inputs: [CTF_API_URL, CTF_LAUNCH_TOKEN]
    # The launch token is single-use: the claimed value must survive restarts.
    volumes: { evidence: /var/lib/ctf }
    docker:
      build: build/database
      init: [build/database/evidence.sh]
    vm:
      os: debian-12
      provision: [provision/database.sh]
```

- Declare the inputs at the top level **and** on the one machine that claims.
- Give that machine a `volumes:` path for the claimed value (e.g. `/var/lib/ctf`).

## 2. The scripts (in `build/<machine>/`)

- `claim-evidence.sh`: copy the template's script unchanged. It reads `CTF_API_URL` and
  `CTF_LAUNCH_TOKEN`, claims the value once (single-use token), and writes it to
  `$CTF_EVIDENCE_FILE`. Without a token it writes `CTF_DEV_EVIDENCE` (local dev, CI, pytest).
  If the file already has a value, it keeps it (restarts).
- `place-evidence.sh`: lab-specific. Reads the file, validates its format, places it
  idempotently. Waits (bounded) for the service it writes to.
- `evidence.sh`: the Docker `init` job. Sets `CTF_EVIDENCE_FILE=/var/lib/ctf/evidence` and
  `CTF_DEV_EVIDENCE="<dev_evidence>"`, runs the claim, then the placement against `127.0.0.1`
  (init jobs share the machine's network namespace).
- The Dockerfile `COPY`s `claim-evidence.sh` and `place-evidence.sh` into the image
  (e.g. `/opt/ctf/`). The init job runs in that image.

## 3. VM edition

The machine's `vm.provision` step does the same, from `/opt/isoloom`:

```sh
mkdir -p /var/lib/ctf
CTF_EVIDENCE_FILE=/var/lib/ctf/evidence CTF_DEV_EVIDENCE="15600.00" \
  sh "$LAB/build/database/claim-evidence.sh"
chmod 600 /var/lib/ctf/evidence
# then place it, exactly as place-evidence.sh does
```

## 4. Placing the value

Seed a placeholder in `init/*.sql`, fixtures or config, then set the real value at startup:

- **Database row**: `UPDATE` the row (the analyst's password hash in the app's own format, the
  invoice total, the IBAN on the customer record).
- **File or vault**: write it into the internal service's config or secret store.
- **API response**: the service reads the value at startup and serves it from the privileged
  endpoint.
- **`CREDENTIALS`**: split on the first `:`. The username is fixed by the lab; only the password
  comes from the evidence.

Validate the format before use (e.g. only digits and `.` for an `AMOUNT`), so nothing else
reaches a query.

The value must end up **only** in its legitimate business location. Do not log it, echo it, or
serve the evidence file on any path. Never hard-code it in SQL, source or images.

## 5. Tests and checks

- pytest runs against `.isoloom/docker/compose.yml` with no token, so the lab uses
  `CTF_DEV_EVIDENCE`.
- The exploit test must extract exactly `dev_evidence` through the vulnerability.
- Add a test that the evidence is **not** reachable without the exploit (unauthenticated page,
  logs, public files).
- `CTF_DEV_EVIDENCE` in `evidence.sh` and in `provision/<machine>.sh` equals `dev_evidence` in
  `.ctf/metadata.json` and `.ctf/EVIDENCE.md`.
- `build/check/check.sh` never prints the evidence.
