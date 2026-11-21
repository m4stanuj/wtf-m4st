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


def test_dashboard_starts_without_service_dependencies():
    client = TestClient(load_app())
    assert client.get("/ready").json() == {"status": "ready"}

def test_retired_routes_do_not_exist_even_with_legacy_admin_token():
    client = TestClient(load_app())
    for route in ("/execute", "/agent/run", "/graphiti/write"):
        response = client.post(route, headers={"X-M4ST-Token": "admin-test-token"}, json={})
        assert response.status_code == 404

def test_logs_reject_url_tokens_and_unbounded_limits():
    client = TestClient(load_app())
    assert client.get("/api/logs/stream?token=read-test-token").status_code == 404
    assert client.get("/api/logs?token=read-test-token").status_code == 401
    for limit in (0, 201):
        response = client.get(f"/api/logs?limit={limit}", headers={"X-M4ST-Token": "read-test-token"})
        assert response.status_code == 422
