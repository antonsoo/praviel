from __future__ import annotations
import asyncio
import pytest
import pytest_asyncio
from app.db.util import engine
from app.db.init_db import initialize_database
from app.db.session import SessionLocal

# One event loop for all async tests (avoids “different loop” errors on Windows)
@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()

# Initialize DB once per test session (ensures extensions + grc/lat seeded)
@pytest.fixture(scope="session", autouse=True)
async def _init_db_once():
    async with SessionLocal() as db:
        await initialize_database(db)
        
@pytest_asyncio.fixture(scope="session", autouse=True)
async def _dispose_engine_at_end():
    yield
    await engine.dispose()
