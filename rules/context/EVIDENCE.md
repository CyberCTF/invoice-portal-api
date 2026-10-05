# Evidence Authoring Rules (Generation)

Authoring rules for a lab's evidence, the realistic business artefact a player extracts by exploiting the lab.

CyberCTF is about doing the pentest, not collecting flags. A player proves they exploited the lab by extracting its **evidence**: the crown-jewel artefact a pentester would put in a report to convince stakeholders (an analyst's credentials, a customer's IBAN, an invoice total, a production API key). There are no points, and there is no `CTF{...}` format.

## One kind, many values

Lab repositories are public, so **a lab never contains a player's evidence**. It declares:

1. **The kind**, i.e. the business form of the evidence. One of:

| Kind | Example value | Params |
|------|---------------|--------|
| `CREDENTIALS` | `analyst2686:q7#Rk2!mWz9pLx4e` | `username` (required): the account that holds the crown jewels |
| `PASSWORD` | `q7#Rk2!mWz9pLx4e` | `length` (default 16) |
| `API_KEY` | `sk_live_4fGh…` | `prefix` (default `sk_live_`), `length` (default 32) |
| `IBAN` | `FR7630004000031234567890143` | none (valid French IBAN) |
| `AMOUNT` | `184233.07` | `min`, `max` (defaults 10000 to 250000) |
| `EMAIL` | `camille.moreau42@globex-finance.fr` | `domain` (required) |
| `SECRET` | `Zq81…` (base62) | `length` (default 24), only when no business form fits |

2. **Where it lives in the lab**: the table/row, file, vault entry or API response that legitimately holds it, and which access level should normally protect it.

3. **A development value** (`dev_evidence`) in exactly that form, e.g. `analyst2686:Dev-Only-Pa55!`. It is public and used only without a launcher (local dev, CI, pytest).

Each player gets their own value of the declared kind at launch. The lab receives it at runtime and places it in its data (see `apps/run/EVIDENCE-INJECTION.md`). Never hard-code the evidence in init SQL, fixtures, source or images: seed a placeholder and let the lab's startup logic set the real value.

## `.ctf/EVIDENCE.md` (created during Phase 2)

Start with this block, in this exact order, so scripts can parse it:

```
**Kind**: CREDENTIALS
**Params**: {"username": "analyst2686"}
**Dev evidence**: analyst2686:Dev-Only-Pa55!
**Capabilities**: union-sql-injection-exploit-postgresql, sql-injection-detect-postgresql
```

`Capabilities` lists the capability ids from the skills graph that the exploit path exercises (1 to 4, most specific first). A capability is a skill applied to a product, e.g. `boolean-blind-sql-injection-exploit-sqlite`: name the technology the lab really runs. They become `capabilities` in `.ctf/metadata.json`; publishing rejects ids that are not in the graph.

Then, in at most 15 lines:
- **Location**: where the artefact lives and who should normally be able to read it.
- **Business impact**: 2 to 3 sentences on why this artefact proves the risk (financial loss, regulatory breach, fraud).
- **Acquisition**: 1 to 2 sentences on the exploit path, with no payloads.

## Guardrails

- Exactly one evidence per lab.
- The evidence must be reachable **only by exploiting the lab's vulnerability**, never through a non-exploit path, logs, README, UI text, error messages or image labels.
- The submitted string must be the bare value (for `CREDENTIALS`: `username:password`), with no prose.
- Use only fictional names and domains (e.g. `@cyberctf.fr`), per PHILOSOPHY.
- `dev_evidence` must match the declared kind and params (same username, same domain, amount within range).
