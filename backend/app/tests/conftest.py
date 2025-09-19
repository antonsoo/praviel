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
    from app.db.util import SessionLocal
    from app.db.util import engine as _engine
    from app.ingestion.jobs import ingest_iliad_sample

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

        run_async(_ingest())
        return True
