from __future__ import annotations

import asyncio

import pytest
import pytest_asyncio
from sqlalchemy import text

from app.db.init_db import initialize_database
from app.db.util import SessionLocal
from app.db.util import engine as _engine


# Use one event loop for the whole test session (matches pytest-asyncio default).
@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    try:
        yield loop
    finally:
        loop.close()


# Ensure the async engine is disposed once at the end of the session.
@pytest_asyncio.fixture(scope="session", autouse=True)
async def _dispose_engine_at_end():
    try:
        yield
    finally:
        try:
            await _engine.dispose()
        except Exception:
            # Keep tests resilient; we don't want disposal failures to fail the suite
            pass


# Ensure required PostgreSQL extensions exist (run once per session).
@pytest_asyncio.fixture(scope="session", autouse=True)
async def _ensure_pg_extensions():
    async with SessionLocal() as db:
        await db.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await db.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
        await db.commit()


# Initialize/seed the DB once for the session.
@pytest_asyncio.fixture(scope="session", autouse=True)
async def _init_db_once():
    async with SessionLocal() as db:
        await initialize_database(db)
