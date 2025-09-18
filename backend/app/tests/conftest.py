from __future__ import annotations

import asyncio
import os

import pytest

RUN_DB_TESTS = os.getenv("RUN_DB_TESTS") == "1"

os.environ.setdefault(
    "DATABASE_URL",
    "postgresql+psycopg://placeholder:placeholder@localhost:5432/placeholder",
)
os.environ.setdefault("REDIS_URL", "redis://localhost:6379/0")


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    try:
        yield loop
    finally:
        loop.close()


if RUN_DB_TESTS:
    import pytest_asyncio
    from sqlalchemy import text

    from app.db.init_db import initialize_database
    from app.db.util import SessionLocal
    from app.db.util import engine as _engine

    @pytest_asyncio.fixture(scope="session", autouse=True)
    async def _dispose_engine_at_end():
        try:
            yield
        finally:
            try:
                await _engine.dispose()
            except Exception:
                pass

    @pytest_asyncio.fixture(scope="session", autouse=True)
    async def _ensure_pg_extensions():
        async with SessionLocal() as db:
            await db.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
            await db.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
            await db.commit()

    @pytest_asyncio.fixture(scope="session", autouse=True)
    async def _init_db_once():
        async with SessionLocal() as db:
            await initialize_database(db)
