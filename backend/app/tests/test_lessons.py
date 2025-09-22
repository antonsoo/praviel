from __future__ import annotations

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from app.core.config import settings
from app.db.session import get_db
from app.lesson import router as lesson_module
from app.lesson.models import LessonGenerateRequest
from app.lesson.providers import DailyLine, LessonContext, LessonProviderError
from app.lesson.providers.echo import EchoLessonProvider
from app.lesson.service import PROVIDERS


class _FailingProvider:
    name = "openai"

    async def generate(self, **kwargs):  # type: ignore[override]
        raise LessonProviderError("boom")


@pytest.mark.asyncio
async def test_echo_cloze_strips_punctuation():
    provider = EchoLessonProvider()
    context = LessonContext(
        daily_lines=(
            DailyLine(grc="νοῦσον, κακήν, ἔλαβεν", en="took"),
        ),
        canonical_lines=tuple(),
        seed=4,
    )
    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily"],
        exercise_types=["cloze"],
        provider="echo",
    )
    response = await provider.generate(
        request=request,
        session=None,
        token=None,
        context=context,
    )
    cloze = response.tasks[0]
    surfaces = [blank.surface for blank in cloze.blanks]
    assert surfaces == ["νοῦσον", "κακήν"]
    assert any(option == "νοῦσον" for option in cloze.options or [])
    assert any(option == "κακήν" for option in cloze.options or [])
    assert "____," in cloze.text


async def _fake_db():
    yield None


def _lesson_app() -> FastAPI:
    app = FastAPI()
    app.include_router(lesson_module.router)
    app.dependency_overrides[get_db] = _fake_db
    return app


def test_lesson_request_requires_grc():
    try:
        LessonGenerateRequest(language="lat", profile="beginner")
    except ValueError as exc:
        assert "Only 'grc' lessons" in str(exc)
    else:  # pragma: no cover - defensive
        raise AssertionError("Expected validation error for non-grc language")


def test_lessons_disabled(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", False, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", False, raising=False)
    client = TestClient(_lesson_app())
    resp = client.post(
        "/lesson/generate",
        json={"language": "grc", "sources": ["daily"], "exercise_types": ["alphabet"], "provider": "echo"},
    )
    assert resp.status_code == 404


def test_lessons_echo_default_success(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", False, raising=False)
    client = TestClient(_lesson_app())
    payload = {
        "language": "grc",
        "profile": "beginner",
        "sources": ["daily"],
        "exercise_types": ["alphabet", "match", "translate"],
        "provider": "echo",
    }
    resp = client.post("/lesson/generate", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["meta"]["provider"] == "echo"
    types = {task["type"] for task in body["tasks"]}
    assert types == {"alphabet", "match", "translate"}


def test_lessons_requires_byok_for_openai(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    client = TestClient(_lesson_app())
    resp = client.post(
        "/lesson/generate",
        json={
            "language": "grc",
            "sources": ["daily"],
            "exercise_types": ["alphabet"],
            "provider": "openai",
        },
    )
    assert resp.status_code == 400
    assert resp.json()["detail"] == "BYOK token required for provider"


def test_lessons_openai_fallback_to_echo(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    # Replace the OpenAI provider with a failing stub
    original = PROVIDERS["openai"]
    PROVIDERS["openai"] = _FailingProvider()
    try:
        client = TestClient(_lesson_app())
        resp = client.post(
            "/lesson/generate",
            json={
                "language": "grc",
                "profile": "beginner",
                "sources": ["daily"],
                "exercise_types": ["alphabet", "match"],
                "provider": "openai",
            },
            headers={"Authorization": "Bearer sk-test"},
        )
        assert resp.status_code == 200
        body = resp.json()
        assert body["meta"]["provider"] == "echo"
        assert {task["type"] for task in body["tasks"]} == {"alphabet", "match"}
    finally:
        PROVIDERS["openai"] = original
