#!/bin/sh
# Web VM: the supplier portal API (Flask + gunicorn) on 3206, as a systemd service.
# An Isoloom VM step: runs as root from the project (/opt/isoloom); safe to re-run.
set -eu

LAB=/opt/isoloom

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq python3-venv curl >/dev/null

id portal >/dev/null 2>&1 || useradd --system --home /opt/portal --shell /usr/sbin/nologin portal
rm -rf /opt/portal/app && mkdir -p /opt/portal
cp -r "$LAB/build/web/src" /opt/portal/app
[ -x /opt/portal/venv/bin/pip ] || python3 -m venv /opt/portal/venv
/opt/portal/venv/bin/pip install -q --disable-pip-version-check -r /opt/portal/app/requirements.txt
chown -R portal:portal /opt/portal

cat > /etc/systemd/system/portal.service <<UNIT
[Unit]
Description=Globex supplier portal API
After=network-online.target
Wants=network-online.target

[Service]
User=portal
WorkingDirectory=/opt/portal/app
Environment=DB_HOST=database
Environment=DB_PORT=3207
Environment=DB_USER=portal
Environment=DB_PASSWORD=portal-pass
Environment=DB_NAME=portal
Environment=PORTAL_API_KEY=vendor-demo-key
ExecStart=/opt/portal/venv/bin/gunicorn --bind 0.0.0.0:3206 --workers 2 --timeout 60 app:app
Restart=on-failure

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable portal >/dev/null
systemctl restart portal

# Ready when the API answers and reaches the database (healthz checks both).
i=0
until curl -fsS --max-time 3 http://127.0.0.1:3206/healthz >/dev/null 2>&1; do
  i=$((i + 1))
  [ "$i" -lt 60 ] || { echo "web: the API never became healthy" >&2; journalctl -u portal --no-pager -n 30 >&2; exit 1; }
  sleep 2
done
echo "web: portal API ready on port 3206"
