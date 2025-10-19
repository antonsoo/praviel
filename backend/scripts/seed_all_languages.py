#!/usr/bin/env python3
"""Seed all 36 supported ancient languages into the database."""

import asyncio
import logging
import sys
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.core.config import settings
from app.db.models import Language

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)

# Complete mapping of language codes to names
LANGUAGES = [
    ("akk", "Akkadian"),
    ("ang", "Old English"),
    ("ara", "Classical Arabic"),
    ("arc", "Aramaic"),
    ("ave", "Avestan"),
    ("bod", "Classical Tibetan"),
    ("cop", "Coptic"),
    ("cu", "Old Church Slavonic"),
    ("egy-old", "Old Egyptian"),
    ("egy", "Middle Egyptian"),
    ("gez", "Ge'ez (Ethiopic)"),
    ("got", "Gothic"),
    ("grc", "Ancient Greek"),
    ("hbo", "Biblical Hebrew"),
    ("hit", "Hittite"),
    ("lat", "Latin"),
    ("lzh", "Classical Chinese"),
    ("nci", "Classical Nahuatl"),
    ("non", "Old Norse"),
    ("ojp", "Old Japanese"),
    ("pal", "Middle Persian (Pahlavi)"),
    ("pli", "Pali"),
    ("qwh", "Quechua (Huaylas)"),
    ("san-ved", "Vedic Sanskrit"),
    ("san", "Sanskrit"),
    ("sga", "Old Irish"),
    ("sog", "Sogdian"),
    ("sux", "Sumerian"),
    ("syc", "Classical Syriac"),
    ("tam-old", "Old Tamil"),
    ("txb", "Tocharian B"),
    ("uga", "Ugaritic"),
    ("xcl", "Classical Armenian"),
    ("xto", "Tocharian A"),
]


async def seed_languages():
    """Seed all languages into database."""
    logger.info(f"Seeding {len(LANGUAGES)} languages into database...")

    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    created_count = 0
    skipped_count = 0

    async with async_session() as session:
        for code, name in LANGUAGES:
            # Check if language already exists
            result = await session.execute(
                select(Language).where(Language.code == code)
            )
            existing = result.scalar_one_or_none()

            if existing:
                logger.info(f"  ✓ {code:12} - {name:30} (already exists)")
                skipped_count += 1
            else:
                lang = Language(code=code, name=name)
                session.add(lang)
                created_count += 1
                logger.info(f"  + {code:12} - {name:30} (created)")

        await session.commit()

    await engine.dispose()

    logger.info(f"\nCompleted!")
    logger.info(f"  Created: {created_count}")
    logger.info(f"  Already existed: {skipped_count}")
    logger.info(f"  Total languages: {len(LANGUAGES)}")


if __name__ == "__main__":
    asyncio.run(seed_languages())
