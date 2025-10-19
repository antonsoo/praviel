"""Check if daily texts exist for Old Norse and Old English."""

import asyncio

from app.core.config import settings
from app.db.models import DailyText
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker


async def main():
    engine = create_async_engine(settings.database_url)
    SessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with SessionLocal() as session:
        for lang_code, lang_name in [("non", "Old Norse"), ("ang", "Old English")]:
            result = await session.execute(select(DailyText).where(DailyText.language == lang_code).limit(1))
            row = result.first()
            print(f"{lang_name} ({lang_code}): {'EXISTS' if row else 'NOT FOUND'}")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(main())
