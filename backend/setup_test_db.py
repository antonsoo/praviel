#!/usr/bin/env python
"""Setup test database with all tables."""

import asyncio

from app.db.models import Base as CoreBase
from app.db.user_models import Base as UserBase
from sqlalchemy import text
from sqlalchemy.ext.asyncio import create_async_engine

TEST_DATABASE_URL = "postgresql+asyncpg://app:app@localhost:5433/ancient_languages_test"


async def setup_test_db():
    """Create all tables in test database."""
    # First connection: drop schema
    engine1 = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with engine1.begin() as conn:
        await conn.execute(text("DROP SCHEMA IF EXISTS public CASCADE"))
        await conn.execute(text("CREATE SCHEMA public"))
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
    await engine1.dispose()

    # COMPLETELY NEW CONNECTION with fresh cache
    engine2 = create_async_engine(TEST_DATABASE_URL, echo=False, pool_size=1, max_overflow=0)
    async with engine2.begin() as conn:
        # Create tables
        await conn.run_sync(CoreBase.metadata.create_all)
        await conn.run_sync(UserBase.metadata.create_all)
    await engine2.dispose()

    print("✅ Test database setup complete")


if __name__ == "__main__":
    asyncio.run(setup_test_db())
