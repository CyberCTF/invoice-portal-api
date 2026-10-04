"""Validates the supplier portal API lab against the development evidence."""
import os

import requests

BASE = os.environ.get("APP_BASE_URL", "http://localhost:3206")
KEY = "vendor-demo-key"
DEV_EVIDENCE = "15600.00"
TARGET = "INV-20507"


def test_home_documents_the_api():
    r = requests.get(f"{BASE}/", timeout=10)
    assert r.status_code == 200
    assert "X-Portal-Key" in r.text and "/api/invoices/" in r.text


def test_api_requires_the_key():
    r = requests.get(f"{BASE}/api/invoices/{TARGET}", timeout=10)
    assert r.status_code == 401


def test_intended_path_returns_the_evidence():
    r = requests.get(f"{BASE}/api/invoices/{TARGET}", headers={"X-Portal-Key": KEY}, timeout=10)
    assert r.status_code == 200
    body = r.json()
    assert body["reference"] == TARGET
    # The amount is this environment's evidence (dev value in CI).
    assert f"{body['amount']:.2f}" == DEV_EVIDENCE


def test_evidence_not_exposed_without_the_api():
    # The amount must not leak on the public home page.
    assert DEV_EVIDENCE not in requests.get(f"{BASE}/", timeout=10).text


def test_unknown_invoice_is_404():
    r = requests.get(f"{BASE}/api/invoices/INV-00000", headers={"X-Portal-Key": KEY}, timeout=10)
    assert r.status_code == 404
