from __future__ import annotations

import asyncio
import os
from pathlib import Path

import pytest
from sqlalchemy import text

if os.name == "nt":  # psycopg async requires selector loop on Windows
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())

TEST_LOOP = asyncio.new_event_loop()
asyncio.set_event_loop(TEST_LOOP)

RUN_DB_TESTS = os.getenv("RUN_DB_TESTS") == "1"

os.environ.setdefault(
    "DATABASE_URL",
    "postgresql+asyncpg://placeholder:placeholder@localhost:5432/placeholder",
)
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")


def run_async(coro):
    return TEST_LOOP.run_until_complete(coro)


@pytest.fixture(scope="session", autouse=True)
def _close_test_loop():
    try:
        yield
    finally:
        TEST_LOOP.call_soon_threadsafe(TEST_LOOP.stop)
        if not TEST_LOOP.is_closed():
            TEST_LOOP.close()


if RUN_DB_TESTS:
    from app.core.config import settings
    from app.db.init_db import initialize_database
    from app.db.util import SessionLocal, text_with_json
    from app.db.util import engine as _engine
    from app.ingestion.jobs import ingest_iliad_sample
    from app.ingestion.normalize import accent_fold

    @pytest.fixture(scope="session", autouse=True)
    def _dispose_engine_at_end():
        try:
            yield
        finally:
            try:
                run_async(_engine.dispose())
            except Exception:
                pass

    @pytest.fixture(scope="session", autouse=True)
    def _ensure_pg_extensions():
        async def _apply_extensions() -> None:
            async with SessionLocal() as db:
                await db.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
                await db.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
                await db.commit()

        run_async(_apply_extensions())

    @pytest.fixture(scope="session", autouse=True)
    def _init_db_once():
        async def _initialize() -> None:
            async with SessionLocal() as db:
                await initialize_database(db)

        run_async(_initialize())

    @pytest.fixture(scope="function")
    def ensure_iliad_sample():
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
                    {"code": "grc"},  # noqa: E501
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
                        "meta": {"language": "grc"},
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

        run_async(_ingest())
        run_async(_seed_reference_data())
        return True
