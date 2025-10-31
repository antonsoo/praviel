from __future__ import annotations

import pytest
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.testclient import TestClient

from app.core.config import settings
from app.middleware.csrf import csrf_middleware


def _build_app() -> FastAPI:
    app = FastAPI()
    app.middleware("http")(csrf_middleware)

    @app.get("/bootstrap")
    def bootstrap():
        return JSONResponse({"status": "ok"})

    @app.post("/update")
    def update():
        return JSONResponse({"status": "updated"})

    return app


@pytest.fixture()
def csrf_test_client(monkeypatch: pytest.MonkeyPatch):
    monkeypatch.setattr(settings, "ENVIRONMENT", "production", raising=False)
    app = _build_app()
    with TestClient(app, raise_server_exceptions=False, base_url="https://testserver") as test_client:
        yield test_client


def test_csrf_rejects_requests_without_token(csrf_test_client: TestClient):
    response = csrf_test_client.post("/update")
    assert response.status_code == 403
    assert "CSRF token" in response.json()["detail"]


def test_csrf_accepts_matching_token(csrf_test_client: TestClient):
    bootstrap = csrf_test_client.get("/bootstrap")
    csrf_token = bootstrap.headers.get("X-CSRF-Token")
    assert csrf_token

    missing_header = csrf_test_client.post("/update")
    assert missing_header.status_code == 403

    mismatch = csrf_test_client.post("/update", headers={"X-CSRF-Token": "invalid"})
    assert mismatch.status_code == 403

    ok = csrf_test_client.post("/update", headers={"X-CSRF-Token": csrf_token})
    assert ok.status_code == 200
    assert ok.json() == {"status": "updated"}
