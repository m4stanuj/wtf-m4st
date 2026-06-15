import importlib.util
import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient


ROOT = Path(__file__).resolve().parents[1]
MAIN_PATH = ROOT / "openwork-mcp" / "main.py"


def load_app():
    os.environ["M4ST_ADMIN_TOKENS"] = "admin-test-token"
    os.environ["M4ST_READ_TOKENS"] = "read-test-token"
    spec = importlib.util.spec_from_file_location("openwork_main_test", MAIN_PATH)
    module = importlib.util.module_from_spec(spec)
    sys.modules["openwork_main_test"] = module
    spec.loader.exec_module(module)
    return module.app


def test_read_endpoint_requires_token():
    client = TestClient(load_app())
    response = client.get("/api/logs")
    assert response.status_code == 401


def test_logs_returns_list_with_read_token():
    client = TestClient(load_app())
    response = client.get("/api/logs", headers={"X-M4ST-Token": "read-test-token"})
    assert response.status_code == 200
    assert isinstance(response.json(), list)


def test_execute_rejects_unlisted_command():
    client = TestClient(load_app())
    response = client.post(
        "/execute",
        headers={"X-M4ST-Token": "admin-test-token"},
        json={"task": "powershell Get-ChildItem"},
    )
    assert response.status_code == 403


def test_execute_allows_whitelisted_command():
    client = TestClient(load_app())
    response = client.post(
        "/execute",
        headers={"X-M4ST-Token": "admin-test-token"},
        json={"task": "python --version"},
    )
    assert response.status_code == 200
    assert response.json()["exit_code"] == 0
