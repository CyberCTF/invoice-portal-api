FROM python:3.12-slim

WORKDIR /app
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
# No USER here: gunicorn starts as root to bind the privileged port 80, then runs its
# workers as appuser (entrypoint.sh passes --user/--group), so the app itself never runs as root.

EXPOSE 80
HEALTHCHECK --interval=10s --timeout=5s --start-period=40s --retries=5 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:80/healthz').status==200 else 1)"
ENTRYPOINT ["/app/entrypoint.sh"]
