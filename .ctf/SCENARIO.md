# Scenario

## Library Insight
A small REST API protected by a request header: the client must send a documented API key header, then calls `GET /api/invoices/<reference>` to read a record. This teaches HTTP methods, headers and reading a JSON response — no vulnerability.

## Business Persona
Globex Finance gives its suppliers a read-only portal API to check their invoice amounts and status without emailing the finance team.

## Technical Surface
- Python Flask API (internal port 3206) serving JSON.
- MySQL 8 backing store (internal port 3207) with an `invoices` table.
- Home page documents the API key header and the lookup endpoint.
- All database access is parameterised.

## Business Risk Chain
- Read the docs → send the API key header → the request is authorised.
- Call the lookup endpoint → receive the invoice JSON → report the amount.
- Using the documented API correctly is the skill being measured.

## Impact Snapshot
A vendor who can call the portal API reconciles their invoices themselves, which is exactly the self-service finance wants.
