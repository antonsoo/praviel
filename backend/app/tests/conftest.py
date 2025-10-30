from __future__ import annotations

import asyncio
import os
from pathlib import Path

import pytest
import pytest_asyncio
from sqlalchemy import text

if os.name == "nt":  # psycopg async requires selector loop on Windows
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

RUN_DB_TESTS = os.getenv("RUN_DB_TESTS") == "1"
DB_SKIP_REASON = (
    "PostgreSQL-dependent tests disabled. Set RUN_DB_TESTS=1 and start the dev database to enable."
)

os.environ.setdefault(
    "DATABASE_URL",
    "postgresql+asyncpg://placeholder:placeholder@localhost:5432/placeholder",
)
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")
os.environ.setdefault("TESTING", "1")


def run_async(coro):
    """Backward-compatible helper for tests that expect a synchronous runner."""
    return asyncio.run(coro)


if RUN_DB_TESTS:
    from httpx import ASGITransport, AsyncClient

    from app.core.config import settings
    from app.db.init_db import initialize_database
    from app.db.util import SessionLocal, text_with_json
    from app.db.util import engine as _engine
    from app.ingestion.jobs import ingest_iliad_sample
    from app.ingestion.normalize import accent_fold
    from app.main import app

    @pytest_asyncio.fixture(scope="session", loop_scope="session", autouse=True)
    async def _dispose_engine_at_end():
        try:
            yield
        finally:
            try:
                await _engine.dispose()
            except Exception:
                pass

    @pytest_asyncio.fixture(scope="session", loop_scope="session", autouse=True)
    async def _ensure_pg_extensions():
        async with SessionLocal() as db:
            try:
                await db.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
                await db.commit()
            except Exception:
                await db.rollback()

            try:
                await db.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
                await db.commit()
            except Exception:
                await db.rollback()

    @pytest_asyncio.fixture(scope="session", loop_scope="session", autouse=True)
    async def _init_db_once(_ensure_pg_extensions):
        async with SessionLocal() as db:
            await initialize_database(db)

    @pytest.fixture(scope="function")
    async def ensure_iliad_sample():
        tei = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1.xml"
        if not tei.exists():
            pytest.skip("Perseus Iliad TEI sample missing")
        tokenized = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1_tokens.xml"

        async def _ingest() -> None:
            async with SessionLocal() as db:
                await ingest_iliad_sample(db, tei, tokenized if tokenized.exists() else tei)

        async def _seed_reference_data() -> None:
            async with SessionLocal() as db:
                lang_result = await db.execute(
                    text("SELECT id FROM language WHERE code=:code"),
                    {"code": "grc-cls"},  # noqa: E501
                )
                lang_id = lang_result.scalar() if lang_result else None
                if not lang_id:
                    return

                lexemes = [
                    {"lemma": "μῆνις", "gloss": "wrath; rage", "citation": "LSJ s.v. μῆνις"},
                    {"lemma": "ἀείδω", "gloss": "sing; chant", "citation": "LSJ s.v. ἀείδω"},
                ]

                for entry in lexemes:
                    await db.execute(
                        text_with_json(
                            "INSERT INTO lexeme(language_id, lemma, lemma_fold, data) "
                            "VALUES(:language_id, :lemma, :lemma_fold, :data) "
                            "ON CONFLICT (language_id, lemma) DO UPDATE SET data = EXCLUDED.data",
                            "data",
                        ),
                        {
                            "language_id": lang_id,
                            "lemma": entry["lemma"],
                            "lemma_fold": accent_fold(entry["lemma"]),
                            "data": {"lsj_gloss": entry["gloss"], "citation": entry["citation"]},
                        },
                    )

                source_result = await db.execute(
                    text_with_json(
                        "INSERT INTO source_doc(slug,title,license,meta) VALUES(:slug,:title,:license,:meta) "
                        "ON CONFLICT (slug) DO UPDATE SET title = EXCLUDED.title RETURNING id",
                        "license",
                        "meta",
                    ),
                    {
                        "slug": "smyth",
                        "title": "Smyth Greek Grammar",
                        "license": {"name": "public-domain"},
                        "meta": {"language": "grc-cls"},
                    },
                )
                source_id = source_result.scalar()

                body = "The accusative expresses the respect in which the statement is true."
                params = {
                    "source_id": source_id,
                    "anchor": "smyth-123",
                    "title": "Accusative of Respect",
                    "body": body,
                    "body_fold": accent_fold(body),
                }
                existing = await db.execute(
                    text("SELECT id FROM grammar_topic WHERE source_id=:source_id AND anchor=:anchor"),
                    params,
                )
                if existing.scalar():
                    await db.execute(
                        text(
                            "UPDATE grammar_topic SET title=:title, body=:body, body_fold=:body_fold WHERE source_id=:source_id AND anchor=:anchor"  # noqa: E501
                        ),
                        params,
                    )
                else:
                    await db.execute(
                        text(
                            "INSERT INTO grammar_topic(source_id, anchor, title, body, body_fold) VALUES(:source_id, :anchor, :title, :body, :body_fold)"  # noqa: E501
                        ),
                        params,
                    )

                await db.commit()

        await _ingest()
        await _seed_reference_data()
        return True

    @pytest.fixture
    async def client():
        """Create an async HTTP client for testing API endpoints."""
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            yield client

    @pytest.fixture
    async def session():
        """Create a database session for testing."""
        async with SessionLocal() as session:
            yield session

    @pytest.fixture
    async def test_db(session):
        """Alias for legacy tests expecting test_db fixture."""
        yield session


_DB_FIXTURE_NAMES = {
    "session",
    "db_session",
    "client",
    "auth_headers",
    "test_user",
    "ensure_iliad_sample",
    "ensure_contract_dataset",
}

_DB_MODULE_SUFFIXES = {
    os.path.join("backend", "app", "tests", "test_contracts.py"),
    os.path.join("backend", "app", "tests", "test_gamification_integration.py"),
    os.path.join("backend", "app", "tests", "test_password_change.py"),
    os.path.join("backend", "app", "tests", "test_coach_endpoint.py"),
    os.path.join("backend", "app", "tests", "test_integration_mvp.py"),
    os.path.join("backend", "app", "tests", "test_lesson_quality.py"),
    os.path.join("backend", "app", "tests", "test_lessons.py"),
    os.path.join("backend", "app", "tests", "test_quests.py"),
    os.path.join("backend", "app", "tests", "test_search_endpoint.py"),
    os.path.join("backend", "app", "tests", "test_srs.py"),
}


def pytest_collection_modifyitems(config, items):
    if RUN_DB_TESTS:
        return

    skip_db = pytest.mark.skip(reason=DB_SKIP_REASON)
    for item in items:
        if _DB_FIXTURE_NAMES.intersection(item.fixturenames):
            item.add_marker(skip_db)
            continue

        path = os.path.normpath(str(item.fspath))
        if any(path.endswith(suffix) for suffix in _DB_MODULE_SUFFIXES):
            item.add_marker(skip_db)
