#!/usr/bin/env python3
"""List all languages."""

import asyncio
import sys
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).parent))

from app.core.config import settings
from app.db.engine import create_asyncpg_engine
from app.db.models import Language


async def main():
    engine = create_asyncpg_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        result = await session.execute(select(Language))
        langs = result.scalars().all()

        print("All languages:")
        for lang in langs:
            print(f"  {lang.code}: {lang.name}")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
