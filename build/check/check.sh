#!/bin/sh
# The lab's self-check, run by the launcher (compose profile "check") on the lab network:
# asserts the intended path still works, so a learner whose box broke is told to reset it.
# Exit 0 = solvable. Never prints the invoice amount: that is the answer.
set -eu

API="http://web:3206/api/invoices/INV-20507"

# The lesson: the API refuses a request without the documented key.
code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$API" || true)
if [ "$code" != "401" ]; then
  echo "✗ a request without X-Portal-Key should get 401, got ${code:-no answer}"
  exit 1
fi

# The intended path: an authenticated lookup returns the target invoice with an amount.
if ! body=$(curl -fsS --max-time 10 -H "X-Portal-Key: ${PORTAL_API_KEY:-vendor-demo-key}" "$API"); then
  echo "✗ the authenticated lookup of INV-20507 failed"
  exit 1
fi
if ! echo "$body" | grep -q '"amount"'; then
  echo "✗ INV-20507 came back without an amount"
  exit 1
fi

echo "✓ supplier portal API: authenticated lookup works"
