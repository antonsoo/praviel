#!/usr/bin/env python3
"""Verify content in database."""

import asyncio
import sys
from pathlib import Path

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.core.config import settings
from app.db.engine import create_asyncpg_engine
from app.db.models import Language, Lexeme, SourceDoc, TextSegment, TextWork


async def verify_content():
    """Verify seeded content."""
    engine = create_asyncpg_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        print("=" * 60)
        print("DATABASE CONTENT VERIFICATION")
        print("=" * 60)

        # Languages
        result = await session.execute(select(Language))
        languages = result.scalars().all()
        print(f"\nLanguages ({len(languages)}):")
        for lang in languages:
            print(f"  - {lang.code}: {lang.name}")

        # Source docs
        result = await session.execute(select(SourceDoc))
        sources = result.scalars().all()
        print(f"\nSource Documents ({len(sources)}):")
        for source in sources:
            print(f"  - {source.slug}: {source.title}")

        # Text works
        result = await session.execute(select(TextWork))
        works = result.scalars().all()
        print(f"\nText Works ({len(works)}):")
        for work in works:
            # Count segments
            seg_result = await session.execute(
                select(func.count(TextSegment.id)).where(TextSegment.work_id == work.id)
            )
            seg_count = seg_result.scalar()
            print(f"  - {work.title} by {work.author}: {seg_count} segments")

        # Sample content from Iliad
        result = await session.execute(select(TextWork).where(TextWork.title == "Iliad"))
        iliad = result.scalar_one_or_none()

        if iliad:
            print(f"\n{'=' * 60}")
            print("SAMPLE ILIAD CONTENT (First 5 lines)")
            print(f"{'=' * 60}")

            result = await session.execute(
                select(TextSegment).where(TextSegment.work_id == iliad.id).order_by(TextSegment.ref).limit(5)
            )
            segments = result.scalars().all()

            for seg in segments:
                # Encode to ASCII to avoid unicode errors in output
                text_ascii = seg.text_nfc.encode("ascii", "ignore").decode("ascii")
                print(f"  {seg.ref}: {text_ascii[:60]}...")

        # Lexemes
        result = await session.execute(select(func.count(Lexeme.id)))
        lex_count = result.scalar()
        print(f"\nLexemes: {lex_count}")

        # Total segments
        result = await session.execute(select(func.count(TextSegment.id)))
        total_segs = result.scalar()

        print(f"\n{'=' * 60}")
        print(f"TOTAL: {total_segs} text segments")
        print(f"{'=' * 60}")

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(verify_content())
