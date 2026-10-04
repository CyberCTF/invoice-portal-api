#!/bin/sh
set -eu
exec gunicorn --bind "0.0.0.0:3206" --workers 2 --timeout 60 app:app
