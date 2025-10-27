import base64
import json
import os

os.environ.setdefault("LESSONS_ENABLED", "1")
os.environ.setdefault("TTS_ENABLED", "1")
# Respect DATABASE_URL from orchestrate scripts/CI, fallback to defaults for local dev
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://app:app@localhost:5433/app")
os.environ.setdefault("DATABASE_URL_SYNC", "postgresql+psycopg://app:app@localhost:5433/app")
# Enable echo fallback for contract tests (no real API keys required)
os.environ.setdefault("ECHO_FALLBACK_ENABLED", "1")
import importlib
from pathlib import Path
from typing import Any

import httpx
import pytest
import pytest_asyncio
from httpx import ASGITransport
from sqlalchemy import text
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

from app.core.config import settings
from app.db import session as db_session
from app.db.util import text_with_json
from app.ingestion.normalize import accent_fold, nfc
from app.lesson.providers.openai import AVAILABLE_MODEL_PRESETS

settings.LESSONS_ENABLED = True
settings.TTS_ENABLED = True
settings.DATABASE_URL = os.environ["DATABASE_URL"]
settings.ECHO_FALLBACK_ENABLED = True
importlib.reload(db_session)

from app.main import app as fastapi_app  # noqa: E402

STATE_PATH = os.environ.get("ORCHESTRATOR_STATE_PATH")
ARTIFACT_DIR = Path(STATE_PATH).parent if STATE_PATH else Path("artifacts")
ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)


_SEEDED_CONTRACT_DATA = False


@pytest_asyncio.fixture(scope="session", loop_scope="session", autouse=True)
async def _seed_contract_dataset() -> None:
    global _SEEDED_CONTRACT_DATA
    if _SEEDED_CONTRACT_DATA:
        return

    engine = create_async_engine(os.environ["DATABASE_URL"], pool_pre_ping=True, future=True)
    session_factory = async_sessionmaker(bind=engine, expire_on_commit=False)

    try:
        async with session_factory() as session:
            try:
                result = await session.execute(
                    text("SELECT id FROM language WHERE code=:code"),
                    {"code": "grc-cls"},
                )
            except OSError as exc:
                pytest.skip(f"Contract seeds require local Postgres (error: {exc})")

            lang_id = result.scalar()
            if not lang_id:
                result = await session.execute(
                    text("INSERT INTO language (code, name) VALUES (:code, :name) RETURNING id"),
                    {"code": "grc-cls", "name": "Classical Greek"},
                )
                lang_id = result.scalar()

            source_params = {
                "slug": "contract-fixture",
                "title": "Contract Fixture Source",
                "license": {"name": "test"},
                "meta": {"language": "grc-cls"},
            }
            source_stmt = text_with_json(
                (
                    "INSERT INTO source_doc(slug, title, license, meta) "
                    "VALUES(:slug, :title, :license, :meta) "
                    "ON CONFLICT (slug) DO UPDATE SET title = EXCLUDED.title, "
                    "license = EXCLUDED.license, meta = EXCLUDED.meta RETURNING id"
                ),
                "license",
                "meta",
            )
            result = await session.execute(source_stmt, source_params)
            source_id = result.scalar()

            work_title = "Contract Fixture Work"
            result = await session.execute(
                text("SELECT id FROM text_work WHERE language_id=:language_id AND title=:title"),
                {"language_id": lang_id, "title": work_title},
            )
            work_id = result.scalar()
            if not work_id:
                work_params = {
                    "language_id": lang_id,
                    "source_id": source_id,
                    "author": "Homer",
                    "title": work_title,
                    "ref_scheme": "line",
                }
                result = await session.execute(
                    text(
                        "INSERT INTO text_work(language_id, source_id, author, title, ref_scheme) "
                        "VALUES (:language_id, :source_id, :author, :title, :ref_scheme) RETURNING id"
                    ),
                    work_params,
                )
                work_id = result.scalar()

            passage = "ἄειδε θεά"
            segment_params = {
                "work_id": work_id,
                "ref": "1.1",
                "text_raw": passage,
                "text_nfc": passage,
                "text_fold": accent_fold(passage),
                "meta": None,
            }
            segment_stmt = text_with_json(
                (
                    "INSERT INTO text_segment(work_id, ref, text_raw, text_nfc, text_fold, meta) "
                    "VALUES (:work_id, :ref, :text_raw, :text_nfc, :text_fold, :meta) "
                    "ON CONFLICT (work_id, ref) DO UPDATE SET text_raw = EXCLUDED.text_raw, "
                    "text_nfc = EXCLUDED.text_nfc, text_fold = EXCLUDED.text_fold, "
                    "meta = EXCLUDED.meta RETURNING id"
                ),
                "meta",
            )
            result = await session.execute(segment_stmt, segment_params)
            segment_id = result.scalar()

            await session.execute(
                text("DELETE FROM token WHERE segment_id=:segment_id"),
                {"segment_id": segment_id},
            )

            token_stmt = text_with_json(
                (
                    "INSERT INTO token(segment_id, idx, surface, surface_nfc, surface_fold, "
                    "lemma, lemma_fold, msd) "
                    "VALUES (:segment_id, :idx, :surface, :surface_nfc, :surface_fold, "
                    ":lemma, :lemma_fold, :msd)"
                ),
                "msd",
            )
            tokens = [
                ("ἄειδε", "ἀείδω", "v3spia---", 0),
                ("θεά", "θεά", "n-s---fn-", 1),
            ]
            for surface, lemma, tag, idx in tokens:
                params = {
                    "segment_id": segment_id,
                    "idx": idx,
                    "surface": surface,
                    "surface_nfc": nfc(surface),
                    "surface_fold": accent_fold(surface),
                    "lemma": lemma,
                    "lemma_fold": accent_fold(lemma),
                    "msd": {"perseus_tag": tag},
                }
                await session.execute(token_stmt, params)

            lexeme_stmt = text_with_json(
                (
                    "INSERT INTO lexeme(language_id, lemma, lemma_fold, pos, data) "
                    "VALUES (:language_id, :lemma, :lemma_fold, :pos, :data) "
                    "ON CONFLICT ON CONSTRAINT uq_lex_lang_lemma DO UPDATE SET pos = EXCLUDED.pos, "
                    "data = EXCLUDED.data"
                ),
                "data",
            )
            lexemes = [
                {"lemma": "ἀείδω", "pos": "verb", "gloss": "to sing", "citation": "LSJ s.v. ἀείδω"},
                {"lemma": "θεά", "pos": "noun", "gloss": "goddess", "citation": "LSJ s.v. θεά"},
            ]
            for entry in lexemes:
                await session.execute(
                    lexeme_stmt,
                    {
                        "language_id": lang_id,
                        "lemma": entry["lemma"],
                        "lemma_fold": accent_fold(entry["lemma"]),
                        "pos": entry["pos"],
                        "data": {
                            "lsj_gloss": entry["gloss"],
                            "citation": entry["citation"],
                        },
                    },
                )

            grammar_body = "Accusative of respect expresses the sphere affected."
            params = {
                "source_id": source_id,
                "anchor": "smyth-123",
                "title": "Accusative of Respect",
                "body": grammar_body,
                "body_fold": accent_fold(grammar_body),
            }
            existing = await session.execute(
                text("SELECT id FROM grammar_topic WHERE source_id=:source_id AND anchor=:anchor"),
                {"source_id": source_id, "anchor": "smyth-123"},
            )
            if existing.scalar():
                await session.execute(
                    text(
                        "UPDATE grammar_topic SET title=:title, body=:body, body_fold=:body_fold "
                        "WHERE source_id=:source_id AND anchor=:anchor"
                    ),
                    params,
                )
            else:
                await session.execute(
                    text(
                        "INSERT INTO grammar_topic(source_id, anchor, title, body, body_fold) "
                        "VALUES (:source_id, :anchor, :title, :body, :body_fold)"
                    ),
                    params,
                )

            await session.commit()
    except OSError as exc:
        pytest.skip(f"Contract seeds require local Postgres (error: {exc})")
    finally:
        await engine.dispose()

    _SEEDED_CONTRACT_DATA = True


_ALLOWED_TASK_TYPES = {"alphabet", "match", "cloze", "translate"}


def _write_json(name: str, payload: Any) -> None:
    path = ARTIFACT_DIR / name
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def _write_bytes(name: str, data: bytes) -> None:
    path = ARTIFACT_DIR / name
    path.write_bytes(data)


@pytest.fixture(scope="session")
def base_url() -> str:
    url = os.environ.get("API_BASE_URL")
    if not url:
        pytest.skip("API_BASE_URL not provided; contract tests require a live server")
    return url.rstrip("/")


@pytest_asyncio.fixture
async def api_client(base_url: str):
    async with httpx.AsyncClient(base_url=base_url, timeout=30.0) as client:
        yield client


@pytest.mark.asyncio
async def test_reader_analyze_contract(api_client: httpx.AsyncClient) -> None:
    params = {"include": json.dumps({"lsj": True, "smyth": True})}
    payload = {"text": "ἄειδε θεά"}
    response = await api_client.post("/reader/analyze", params=params, json=payload)
    response.raise_for_status()
    data = response.json()

    tokens = data.get("tokens")
    assert isinstance(tokens, list) and tokens, "Expected non-empty token list"
    for token in tokens:
        assert "lemma" in token, "Token missing lemma field"
        assert "morph" in token, "Token missing morph field"
    assert any(token.get("lemma") for token in tokens), "Expected at least one lemma value"
    assert any(token.get("morph") for token in tokens), "Expected at least one morph value"

    lexicon = data.get("lexicon") or []
    assert lexicon, "Expected LSJ entries"
    grammar = data.get("grammar") or []
    assert grammar, "Expected Smyth entries"


@pytest.mark.asyncio
async def test_lessons_echo_contract(api_client: httpx.AsyncClient) -> None:
    payload = {
        "language": "grc-cls",
        "profile": "beginner",
        "sources": ["daily", "canon"],
        "exercise_types": ["alphabet", "match", "cloze", "translate"],
        "provider": "echo",
        "include_audio": False,
    }
    response = await api_client.post("/lesson/generate", json=payload)
    response.raise_for_status()
    data = response.json()
    _assert_lesson_schema(data)
    meta = data["meta"]
    assert meta["provider"] == "echo"
    _write_json("lesson_echo.json", data)


@pytest.mark.asyncio
async def test_lessons_openai_missing_byok_falls_back(api_client: httpx.AsyncClient) -> None:
    payload = {
        "language": "grc-cls",
        "profile": "beginner",
        "sources": ["daily", "canon"],
        "exercise_types": ["alphabet", "match"],
        "provider": "openai",
        "include_audio": False,
    }
    response = await api_client.post("/lesson/generate", json=payload)
    response.raise_for_status()
    data = response.json()
    _assert_lesson_schema(data)
    meta = data["meta"]
    assert meta["provider"] == "echo"
    note = meta.get("note")
    assert note in {"byok_missing_fell_back_to_echo", "byok_failed_fell_back_to_echo"}
    _write_json("lesson_openai_fallback.json", data)


@pytest.mark.asyncio
async def test_lessons_openai_fake_adapter(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("BYOK_FAKE", "1")
    try:
        transport = ASGITransport(app=fastapi_app)
        async with httpx.AsyncClient(
            transport=transport, base_url="http://testserver", timeout=30.0
        ) as client:
            headers = {"Authorization": "Bearer fake-test-token"}
            captured: dict[str, dict[str, Any]] = {}
            for model_id in AVAILABLE_MODEL_PRESETS:
                payload = {
                    "language": "grc-cls",
                    "profile": "beginner",
                    "sources": ["daily", "canon"],
                    "exercise_types": ["alphabet", "translate"],
                    "provider": "openai",
                    "include_audio": False,
                    "model": model_id,
                }
                response = await client.post("/lesson/generate", json=payload, headers=headers)
                if response.status_code >= 400:
                    sanitized = response.text.encode("ascii", "backslashreplace").decode("ascii")
                    pytest.fail(f"lesson endpoint returned {response.status_code}: {sanitized}")
                data = response.json()
                _assert_lesson_schema(data)
                meta = data["meta"]
                assert meta["provider"] == "openai"
                assert "note" not in meta
                captured[model_id] = data
    finally:
        monkeypatch.delenv("BYOK_FAKE", raising=False)

    default_model = AVAILABLE_MODEL_PRESETS[0]
    _write_json("lesson_openai_byok.json", captured[default_model])
    for model_id, payload in captured.items():
        filename = f"lesson_openai_byok_{model_id}.json"
        _write_json(filename, payload)


@pytest.mark.asyncio
async def test_tts_echo_contract(api_client: httpx.AsyncClient) -> None:
    payload = {"text": "χαῖρε", "provider": "echo", "format": "wav"}
    response = await api_client.post("/tts/speak", json=payload)
    response.raise_for_status()
    data = response.json()
    audio = data["audio"]
    assert audio["mime"] == "audio/wav"
    raw = base64.b64decode(audio["b64"])
    assert len(raw) > 16
    meta = data["meta"]
    assert meta["provider"] == "echo"
    _write_bytes("tts_echo.wav", raw)


@pytest.mark.asyncio
async def test_tts_openai_falls_back_to_echo(api_client: httpx.AsyncClient) -> None:
    payload = {"text": "χαῖρε", "provider": "openai", "format": "wav"}
    response = await api_client.post("/tts/speak", json=payload)
    response.raise_for_status()
    data = response.json()
    meta = data["meta"]
    assert meta["provider"] == "echo"


def _assert_lesson_schema(data: dict[str, Any]) -> None:
    assert "meta" in data and "tasks" in data
    meta = data["meta"]
    for key in ("language", "profile", "provider", "model"):
        assert key in meta and meta[key], f"meta missing {key}"
    tasks = data["tasks"]
    assert isinstance(tasks, list) and tasks, "Lesson tasks are missing"
    for task in tasks:
        assert task["type"] in _ALLOWED_TASK_TYPES
        if task["type"] == "cloze":
            assert task.get("ref"), "Cloze task missing canonical ref"
            blanks = task.get("blanks") or []
            assert blanks, "Cloze task missing blanks"
        if task["type"] == "alphabet":
            assert task.get("options"), "Alphabet task missing options"
