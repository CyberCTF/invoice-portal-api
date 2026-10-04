# Supplier portal API (starter lab)

A gentle first CyberCTF lab: no vulnerability. You learn to read a small REST
API's docs and make an authenticated request.

**Task:** report the amount of invoice `INV-20507` from the portal API.

## Run it

```bash
docker compose up -d --build
```

Open http://localhost:3206 for the API docs, then:

```bash
curl -H "X-Portal-Key: vendor-demo-key" http://localhost:3206/api/invoices/INV-20507
```

The `amount` field is your evidence. Without the CyberCTF launcher the lab uses
its public development value; launched from CyberCTF you get your own value.

## Layout
- `build/web/` — Flask API (`src/app.py`) + Dockerfile
- `build/database/` — MySQL schema and the startup step that places the evidence
- `evidence/claim-evidence.sh` — fetches the player's evidence at launch
- `tests/` — pytest suite (runs against `build/docker-compose.dev.yml`)
