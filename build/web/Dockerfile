FROM python:3.12-slim

WORKDIR /app
COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ .
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

EXPOSE 3206
HEALTHCHECK --interval=10s --timeout=5s --start-period=40s --retries=5 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:3206/healthz').status==200 else 1)"
ENTRYPOINT ["/app/entrypoint.sh"]
