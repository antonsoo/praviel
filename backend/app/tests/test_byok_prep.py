from __future__ import annotations

from fastapi import Depends, FastAPI, Request
from fastapi.testclient import TestClient

from app.core.config import settings
from app.security.byok import extract_byok_token, get_byok_token
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


def test_extract_byok_token_handles_headers():
    allowed = ("authorization", "x-model-key")
    headers = {"Authorization": "Bearer spaced"}
    assert extract_byok_token(headers, allowed=allowed) == "spaced"
    headers = {"authorization": "  Bearer  compact  "}
    assert extract_byok_token(headers, allowed=allowed) == "compact"
    headers = {"X-Model-Key": " raw "}
    assert extract_byok_token(headers, allowed=allowed) == "raw"
    headers = {"Authorization": "Token nope"}
    assert extract_byok_token(headers, allowed=allowed) is None
    assert extract_byok_token({}, allowed=allowed) is None


def test_get_byok_token_extracts_headers(monkeypatch):
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    client = TestClient(_build_test_app())

    resp = client.get("/token", headers={"Authorization": "Bearer abc"})
    assert resp.json() == {"token": "abc", "state": "abc"}

    resp = client.get("/token", headers={"authorization": "  Bearer   spaced   "})
    assert resp.json() == {"token": "spaced", "state": "spaced"}

    resp = client.get("/token", headers={"X-Model-Key": " raw "})
    assert resp.json() == {"token": "raw", "state": "raw"}

    resp = client.get("/token")
    assert resp.json() == {"token": None, "state": None}


def test_byok_openai_probe_metadata(monkeypatch):
    from app.api import diag

    class DummyTimeout:
        def __init__(self, *_args, **kwargs):
            self.connect = kwargs.get("connect")
            self.read = kwargs.get("read")
            self.write = kwargs.get("write")
            self.pool = kwargs.get("pool")

    class DummyResponse:
        status_code = 200

        def json(self):
            return {"data": [{"id": "gpt-4o-mini"}]}

    class FakeClient:
        def __init__(self, *args, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return False

        async def get(self, endpoint, headers):
            assert endpoint.endswith("/models")
            return DummyResponse()

    fake_httpx = type(
        "HttpxStub",
        (),
        {
            "AsyncClient": FakeClient,
            "Timeout": DummyTimeout,
            "TimeoutException": Exception,
            "HTTPError": Exception,
        },
    )

    monkeypatch.setattr(diag, "httpx", fake_httpx)
    app = FastAPI()
    app.include_router(diag.router)
    client = TestClient(app)

    resp = client.get("/diag/byok/openai")
    assert resp.status_code == 200
    body = resp.json()
    assert body["base_url"] == diag._resolve_openai_base()
    assert body["timeout"]["connect"] == 3.0
    assert body["timeout"]["read"] == 5.0
    assert body["model_hint"] == "gpt-4o-mini"
