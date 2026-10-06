#!/bin/sh
set -eu
exec gunicorn --bind "0.0.0.0:80" --user appuser --group appuser --workers 2 --timeout 60 app:app
