import os
import subprocess
import time

import pytest
import requests

COMPOSE = ["docker", "compose", "-f", ".isoloom/docker/compose.yml"]
BASE = os.environ.get("APP_BASE_URL", "http://localhost:3206")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


@pytest.fixture(scope="session", autouse=True)
def stack():
    """Bring the lab up (dev evidence), wait for health, tear it down after."""
    subprocess.run(COMPOSE + ["up", "-d", "--build", "--wait", "--wait-timeout", "300"], cwd=ROOT, check=True)
    try:
        deadline = time.time() + 180
        while time.time() < deadline:
            try:
                if requests.get(f"{BASE}/healthz", timeout=3).status_code == 200:
                    break
            except requests.RequestException:
                pass
            time.sleep(3)
        else:
            logs = subprocess.run(COMPOSE + ["logs"], cwd=ROOT, capture_output=True, text=True)
            raise RuntimeError(f"web service never became healthy\n{logs.stdout}\n{logs.stderr}")
        yield
    finally:
        subprocess.run(COMPOSE + ["down", "-v"], cwd=ROOT, check=False)
