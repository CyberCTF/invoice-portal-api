"""Globex Finance supplier portal — read-only invoices API.

A starter lab: no vulnerability. The player learns to read the API docs on the
home page and make an authenticated GET request (a documented API key header)
to look up an invoice amount. Everything is parameterised and benign.
"""
import os
import time

import mysql.connector
from flask import Flask, jsonify, render_template, request

app = Flask(__name__)

# Documented, public demo key — shown on the home page. It is not a secret;
# it only teaches sending a request header.
API_KEY = os.environ.get("PORTAL_API_KEY", "vendor-demo-key")

DB = {
    "host": os.environ.get("DB_HOST", "database"),
    "port": int(os.environ.get("DB_PORT", "3207")),
    "user": os.environ.get("DB_USER", "portal"),
    "password": os.environ.get("DB_PASSWORD", "portal-pass"),
    "database": os.environ.get("DB_NAME", "portal"),
}


def connect(retries: int = 30):
    last = None
    for _ in range(retries):
        try:
            return mysql.connector.connect(**DB)
        except mysql.connector.Error as exc:  # pragma: no cover - startup only
            last = exc
            time.sleep(2)
    raise last


@app.route("/")
def home():
    return render_template("index.html", api_key=API_KEY)


@app.route("/api/invoices/<reference>")
def invoice(reference: str):
    """Return one invoice. Requires the documented X-Portal-Key header."""
    if request.headers.get("X-Portal-Key") != API_KEY:
        return jsonify({"error": "Missing or invalid X-Portal-Key header"}), 401
    conn = connect()
    try:
        cur = conn.cursor(dictionary=True)
        # Parameterised query: input is bound, never concatenated.
        cur.execute(
            "SELECT reference, vendor, amount, status FROM invoices WHERE reference = %s",
            (reference,),
        )
        row = cur.fetchone()
    finally:
        conn.close()
    if not row:
        return jsonify({"error": "Invoice not found"}), 404
    row["amount"] = float(row["amount"])
    return jsonify(row)


@app.route("/healthz")
def healthz():
    return {"status": "ok"}


if __name__ == "__main__":  # pragma: no cover
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "3206")))
