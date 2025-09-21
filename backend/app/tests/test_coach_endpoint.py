from __future__ import annotations

from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.api.routers import coach as coach_module
from app.core.config import settings
from app.security.middleware import redact_api_keys_middleware


class _FakeProvider:
    def __init__(self) -> None:
        self.calls: int = 0
        self.last_token: str | None = None

    async def chat(self, *, messages, model, token):  # type: ignore[override]
        self.calls += 1
        self.last_token = token
        answer = f"[fake] {messages[-1]['content']}"
        return answer, {"calls": self.calls}


async def _fake_context(question: str, *, k: int = 3):
    return ["Iliad 1.1"], "[1] Iliad 1.1: μῆνιν"


def _app() -> FastAPI:
    application = FastAPI()
    application.state.last_byok = None

    @application.middleware("http")
    async def _capture_byok(request, call_next):
        response = await call_next(request)
        application.state.last_byok = getattr(request.state, "byok", None)
        return response

    application.middleware("http")(redact_api_keys_middleware)
    application.include_router(coach_module.router)
    return application


def test_coach_disabled(monkeypatch):
    monkeypatch.setattr(settings, "COACH_ENABLED", False, raising=False)
    client = TestClient(_app())
    resp = client.post("/coach/chat", json={"q": "χαῖρε"})
    assert resp.status_code == 404


def test_coach_requires_byok(monkeypatch):
    monkeypatch.setattr(settings, "COACH_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    client = TestClient(_app())
    resp = client.post("/coach/chat", json={"q": "χαῖρε", "provider": "openai"})
    assert resp.status_code == 400
    assert resp.json()["detail"] == "BYOK token required"


def test_coach_echo_success(monkeypatch):
    monkeypatch.setattr(settings, "COACH_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", False, raising=False)
    monkeypatch.setattr(coach_module, "build_context", _fake_context)
    client = TestClient(_app())
    resp = client.post(
        "/coach/chat",
        json={"q": "Τί ἐστιν ἀρετή;", "provider": "echo"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["answer"] == "[echo] Τί ἐστιν ἀρετή;"
    assert body["citations"] == ["Iliad 1.1"]
    assert body["usage"] is None


def test_coach_openai_with_fake_provider(monkeypatch):
    monkeypatch.setattr(settings, "COACH_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    monkeypatch.setattr(coach_module, "build_context", _fake_context)

    fake = _FakeProvider()
    monkeypatch.setitem(coach_module.PROVIDERS, "openai", fake)

    client = TestClient(_app())
    resp = client.post(
        "/coach/chat",
        json={"history": [{"role": "user", "content": "Δίδαξόν με."}], "provider": "openai"},
        headers={"Authorization": "Bearer sk-test-123"},
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["answer"] == "[fake] Δίδαξόν με."
    assert body["citations"] == ["Iliad 1.1"]
    assert body["usage"] == {"calls": 1}
    assert fake.last_token == "sk-test-123"
    assert client.app.state.last_byok == "sk-test-123"
