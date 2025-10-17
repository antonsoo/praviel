from __future__ import annotations

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.exc import SQLAlchemyError

from app.core.config import settings
from app.db.session import get_db
from app.lesson import router as lesson_module
from app.lesson import service as lesson_service
from app.lesson.models import LessonGenerateRequest
from app.lesson.providers import CanonicalLine, DailyLine, LessonContext, LessonProviderError
from app.lesson.providers.echo import EchoLessonProvider
from app.lesson.providers.openai import OpenAILessonProvider
from app.lesson.service import PROVIDERS


class _FailingProvider:
    name = "openai"

    async def generate(self, **kwargs):  # type: ignore[override]
        raise LessonProviderError("boom")


class _UnauthorizedProvider:
    name = "openai"

    async def generate(self, **kwargs):  # type: ignore[override]
        raise LessonProviderError("unauthorized", note="openai_401")


@pytest.mark.asyncio
async def test_echo_cloze_strips_punctuation():
    provider = EchoLessonProvider()
    context = LessonContext(
        daily_lines=(DailyLine(text="νοῦσον, κακήν, ἔλαβεν", en="took"),),
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


@pytest.mark.asyncio
async def test_echo_canonical_line_includes_ref():
    provider = EchoLessonProvider()
    context = LessonContext(
        daily_lines=(DailyLine(text="Χαῖρε!", en="Hello!"),),
        canonical_lines=(CanonicalLine(ref="Il.1.1", text="ἄειδε θεά"),),
        seed=2,
    )
    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily", "canon"],
        exercise_types=["cloze"],
        provider="echo",
    )
    response = await provider.generate(
        request=request,
        session=None,
        token=None,
        context=context,
    )
    cloze_task = response.tasks[0]
    assert getattr(cloze_task, "ref", None) == "Il.1.1"
    assert cloze_task.blanks and cloze_task.blanks[0].surface == "ἄειδε"
    assert "ἄειδε" in (cloze_task.options or [])


async def _fake_db():
    yield None


def _lesson_app() -> FastAPI:
    app = FastAPI()
    app.include_router(lesson_module.router)
    app.dependency_overrides[get_db] = _fake_db
    return app


@pytest.mark.asyncio
async def test_build_context_skips_canon_on_db_error(monkeypatch: pytest.MonkeyPatch):
    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily", "canon"],
        exercise_types=["alphabet"],
        k_canon=1,
    )

    async def _raise_sqlalchemy_error(*_args, **_kwargs):
        raise SQLAlchemyError("database unavailable")  # type: ignore[arg-type]

    monkeypatch.setattr(lesson_service, "_fetch_canonical_lines", _raise_sqlalchemy_error)

    context = await lesson_service._build_context(session=None, request=request)
    assert context.canonical_lines == tuple()


def test_lesson_request_requires_grc():
    # All languages (grc, lat, hbo, san) are now supported
    # This test is outdated - Latin is now valid
    request = LessonGenerateRequest(language="lat", profile="beginner")
    assert request.language == "lat"

    # Test that invalid languages still fail
    try:
        LessonGenerateRequest(language="invalid", profile="beginner")
    except ValueError as exc:
        assert "language" in str(exc).lower()
    else:  # pragma: no cover - defensive
        raise AssertionError("Expected validation error for invalid language")


def test_lessons_disabled(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", False, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", False, raising=False)
    client = TestClient(_lesson_app())
    resp = client.post(
        "/lesson/generate",
        json={
            "language": "grc",
            "sources": ["daily"],
            "exercise_types": ["alphabet"],
            "provider": "echo",
        },
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
    assert "note" not in body["meta"]
    types = {task["type"] for task in body["tasks"]}
    assert types == {"alphabet", "match", "translate"}


def test_lessons_echo_all_10_types(monkeypatch):
    """Test that all 10 exercise types generate successfully"""
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", False, raising=False)
    client = TestClient(_lesson_app())
    all_types = [
        "alphabet",
        "match",
        "cloze",
        "translate",
        "grammar",
        "listening",
        "speaking",
        "wordbank",
        "truefalse",
        "multiplechoice",
    ]
    payload = {
        "language": "grc",
        "profile": "beginner",
        "sources": ["daily"],
        "exercise_types": all_types,
        "provider": "echo",
    }
    resp = client.post("/lesson/generate", json=payload)
    assert resp.status_code == 200
    body = resp.json()
    assert body["meta"]["provider"] == "echo"
    types = {task["type"] for task in body["tasks"]}
    assert types == set(all_types), f"Expected all 10 types, got: {types}"

    # Verify each type has required fields
    for task in body["tasks"]:
        task_type = task["type"]
        if task_type == "wordbank":
            assert "words" in task
            assert "correct_order" in task
            assert "translation" in task
            assert len(task["correct_order"]) == len(task["words"])
        elif task_type == "listening":
            assert "audio_text" in task
            assert "options" in task
            assert "answer" in task
            assert len(task["options"]) >= 1
        elif task_type == "grammar":
            assert "sentence" in task
            assert "is_correct" in task
        elif task_type == "truefalse":
            assert "statement" in task
            assert "is_true" in task
            assert "explanation" in task
        elif task_type == "multiplechoice":
            assert "question" in task
            assert "options" in task
            assert "answer_index" in task
        elif task_type == "speaking":
            assert "prompt" in task
            assert "target_text" in task


def test_lessons_openai_missing_token_falls_back(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "ECHO_FALLBACK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "OPENAI_API_KEY", None, raising=False)
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
    assert resp.status_code == 200
    body = resp.json()
    assert body["meta"]["provider"] == "echo"
    assert body["meta"]["note"] == "byok_missing_fell_back_to_echo"
    assert {task["type"] for task in body["tasks"]} == {"alphabet"}


def test_lessons_openai_fake_success(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "ECHO_FALLBACK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "OPENAI_API_KEY", None, raising=False)
    monkeypatch.setenv("BYOK_FAKE", "1")
    client = TestClient(_lesson_app())
    resp = client.post(
        "/lesson/generate",
        json={
            "language": "grc",
            "sources": ["daily"],
            "exercise_types": ["translate"],
            "provider": "openai",
        },
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["meta"]["provider"] == "openai"
    assert body["meta"].get("note") is None
    assert {task["type"] for task in body["tasks"]} == {"translate"}
    monkeypatch.delenv("BYOK_FAKE", raising=False)


def test_lessons_openai_fallback_to_echo(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "ECHO_FALLBACK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "OPENAI_API_KEY", None, raising=False)
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
        assert body["meta"]["note"] == "byok_failed_fell_back_to_echo"
        assert {task["type"] for task in body["tasks"]} == {"alphabet", "match"}
    finally:
        PROVIDERS["openai"] = original


def test_lessons_openai_401_fallback_propagates_note(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "ECHO_FALLBACK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "OPENAI_API_KEY", None, raising=False)
    original = PROVIDERS["openai"]
    PROVIDERS["openai"] = _UnauthorizedProvider()
    try:
        client = TestClient(_lesson_app())
        resp = client.post(
            "/lesson/generate",
            json={
                "language": "grc",
                "profile": "beginner",
                "sources": ["daily"],
                "exercise_types": ["alphabet"],
                "provider": "openai",
            },
            headers={"Authorization": "Bearer sk-test"},
        )
        assert resp.status_code == 200
        body = resp.json()
        assert body["meta"]["provider"] == "echo"
        assert body["meta"].get("note") == "openai_401"
    finally:
        PROVIDERS["openai"] = original


def test_lessons_openai_respects_x_model_key(monkeypatch):
    monkeypatch.setattr(settings, "LESSONS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "BYOK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "ECHO_FALLBACK_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "OPENAI_API_KEY", None, raising=False)
    monkeypatch.setenv("BYOK_FAKE", "1")

    captured_token: dict[str, str | None] = {}

    class _CapturingOpenAI(OpenAILessonProvider):
        async def generate(  # type: ignore[override]
            self,
            *,
            request,
            session,
            token,
            context,
        ):
            captured_token["value"] = token
            return await super().generate(
                request=request,
                session=session,
                token=token,
                context=context,
            )

    original = PROVIDERS["openai"]
    PROVIDERS["openai"] = _CapturingOpenAI()
    try:
        client = TestClient(_lesson_app())
        resp = client.post(
            "/lesson/generate",
            json={
                "language": "grc",
                "sources": ["daily"],
                "exercise_types": ["alphabet"],
                "provider": "openai",
            },
            headers={"X-Model-Key": "sk-test"},
        )
        assert resp.status_code == 200
        body = resp.json()
        assert body["meta"]["provider"] == "openai"
        assert body["meta"].get("note") is None
        assert body["tasks"]
        assert captured_token.get("value") == "sk-test"
    finally:
        PROVIDERS["openai"] = original
        monkeypatch.delenv("BYOK_FAKE", raising=False)


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("status", "expected_note"),
    [
        (401, "openai_401"),
        (403, "openai_403"),
        (404, "openai_404_model"),
    ],
)
async def test_openai_provider_http_status_notes(monkeypatch, status, expected_note):
    provider = OpenAILessonProvider()
    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily"],
        exercise_types=["alphabet"],
        provider="openai",
    )
    context = LessonContext(daily_lines=tuple(), canonical_lines=tuple(), seed=0)

    import httpx

    class FakeClient:
        def __init__(self, *args, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return False

        async def post(self, url, **kwargs):
            request_obj = httpx.Request("POST", url)
            response_obj = httpx.Response(status, request=request_obj)
            raise httpx.HTTPStatusError("boom", request=request_obj, response=response_obj)

    monkeypatch.setattr(
        OpenAILessonProvider,
        "_resolve_base_url",
        lambda self: "https://api.example.com/v1",
    )
    monkeypatch.setattr(httpx, "AsyncClient", FakeClient)

    with pytest.raises(LessonProviderError) as exc_info:
        await provider.generate(request=request, session=None, token="sk-test", context=context)

    assert exc_info.value.note == expected_note


@pytest.mark.asyncio
async def test_openai_provider_timeout_note(monkeypatch):
    provider = OpenAILessonProvider()
    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily"],
        exercise_types=["alphabet"],
        provider="openai",
    )
    context = LessonContext(daily_lines=tuple(), canonical_lines=tuple(), seed=0)

    import httpx

    class TimeoutClient:
        def __init__(self, *args, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return False

        async def post(self, url, **kwargs):
            raise httpx.TimeoutException("timeout")

    monkeypatch.setattr(
        OpenAILessonProvider,
        "_resolve_base_url",
        lambda self: "https://api.example.com/v1",
    )
    monkeypatch.setattr(httpx, "AsyncClient", TimeoutClient)

    with pytest.raises(LessonProviderError) as exc_info:
        await provider.generate(request=request, session=None, token="sk-test", context=context)

    assert exc_info.value.note == "openai_timeout"


@pytest.mark.asyncio
async def test_openai_provider_network_note(monkeypatch):
    provider = OpenAILessonProvider()
    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily"],
        exercise_types=["alphabet"],
        provider="openai",
    )
    context = LessonContext(daily_lines=tuple(), canonical_lines=tuple(), seed=0)

    import httpx

    class NetworkClient:
        def __init__(self, *args, **kwargs):
            pass

        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return False

        async def post(self, url, **kwargs):
            raise httpx.HTTPError("network")

    monkeypatch.setattr(
        OpenAILessonProvider,
        "_resolve_base_url",
        lambda self: "https://api.example.com/v1",
    )
    monkeypatch.setattr(httpx, "AsyncClient", NetworkClient)

    with pytest.raises(LessonProviderError) as exc_info:
        await provider.generate(request=request, session=None, token="sk-test", context=context)

    assert exc_info.value.note == "openai_network"


@pytest.mark.asyncio
async def test_openai_provider_fake_adapter(monkeypatch):
    monkeypatch.setenv("BYOK_FAKE", "1")
    provider = OpenAILessonProvider()
    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily"],
        exercise_types=["translate"],
        provider="openai",
    )
    context = LessonContext(
        daily_lines=(DailyLine(text="χαῖρε", en="greetings"),),
        canonical_lines=tuple(),
        seed=0,
    )
    response = await provider.generate(
        request=request,
        session=None,
        token=None,
        context=context,
    )
    assert response.meta.provider == "openai"
    assert response.meta.note is None
    assert response.tasks
    monkeypatch.delenv("BYOK_FAKE", raising=False)
