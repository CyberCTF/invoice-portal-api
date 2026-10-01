**Kind**: AMOUNT
**Params**: {"min": 1000, "max": 99999}
**Dev evidence**: 15600.00
**Capabilities**: rest-api-read-http, http-request-headers

- **Location**: the `amount` field of invoice `INV-20507` in the supplier portal, returned by the read-only invoices API.
- **Business impact**: the invoice total is the figure finance reconciles against the supplier's statement; reading it from the API is the everyday vendor task this lab teaches.
- **Acquisition**: read the API docs on the home page, then `GET /api/invoices/INV-20507` with the documented `X-Portal-Key` header and report the `amount`.
