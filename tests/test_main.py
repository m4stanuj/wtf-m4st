import os
import pytest
from fastapi.testclient import TestClient

# Mock environment variables
os.environ["M4ST_TOKEN"] = "test_token_123"
os.environ["M4ST_ALLOWED_COMMANDS"] = "git,python,pytest"

# Add parent directory to path so we can import openwork-mcp
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent / "openwork-mcp"))

from main import app

client = TestClient(app)

def test_system_info():
    response = client.get("/api/system-info")
    assert response.status_code == 200
    data = response.json()
    assert data["project"] == "M4ST"
    assert data["version"] == "v8.2-local"

def test_verify_token_missing():
    response = client.post("/execute", json={"task": "git status"})
    assert response.status_code == 401

def test_verify_token_invalid():
    response = client.post(
        "/execute", 
        json={"task": "git status"},
        headers={"X-M4ST-Token": "wrong_token"}
    )
    assert response.status_code == 401

def test_execute_disallowed_command():
    response = client.post(
        "/execute",
        json={"task": "rm -rf /"},
        headers={"X-M4ST-Token": "test_token_123"}
    )
    assert response.status_code == 403
    assert "not allowed" in response.json()["detail"]
