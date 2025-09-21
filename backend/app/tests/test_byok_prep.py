from __future__ import annotations

from fastapi import Depends, FastAPI, Request
from fastapi.testclient import TestClient

from app.core.config import settings
from app.security.byok import get_byok_token
from app.security.middleware import redact_api_keys_middleware


def _build_test_app():
    app = FastAPI()
    app.middleware("http")(redact_api_keys_middleware)

    @app.post("/echo")
    async def echo(request: Request):
        return {
            "headers": getattr(request.state, "redacted_headers", {}),
            "body": getattr(request.state, "redacted_body", {}),
        }

    @app.get("/token")
    async def token_endpoint(request: Request, token: str | None = Depends(get_byok_token)):
        return {
            "token": token,
            "state": getattr(request.state, "byok", None),
        }

    return app


def test_header_redaction(monkeypatch):
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    client = TestClient(_build_test_app())
    response = client.post(
        "/echo",
        json={"openai_api_key": "super-secret", "safe": "value"},
        headers={
            "Authorization": "Bearer top-secret",
            "X-Model-Key": "raw-key",
            "X-Other": "fine",
        },
    )
    payload = response.json()
    redacted_headers = {k.lower(): v for k, v in payload["headers"].items()}
    assert redacted_headers["authorization"] == "***"
    assert redacted_headers["x-model-key"] == "***"
    assert redacted_headers["x-other"] == "fine"
    assert payload["body"]["openai_api_key"] == "***"
    assert payload["body"]["safe"] == "value"


def test_get_byok_token_disabled(monkeypatch):
    monkeypatch.setattr(settings, "BYOK_ENABLED", False, raising=False)
    client = TestClient(_build_test_app())
    resp = client.get("/token", headers={"Authorization": "Bearer abc"})
    data = resp.json()
    assert data == {"token": None, "state": None}


def test_get_byok_token_extracts_headers(monkeypatch):
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    client = TestClient(_build_test_app())

    resp = client.get("/token", headers={"Authorization": "Bearer abc"})
    assert resp.json() == {"token": "abc", "state": "abc"}

    resp = client.get("/token", headers={"X-Model-Key": "raw"})
    assert resp.json() == {"token": "raw", "state": "raw"}

    resp = client.get("/token")
    assert resp.json() == {"token": None, "state": None}
