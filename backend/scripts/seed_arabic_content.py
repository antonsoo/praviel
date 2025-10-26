#!/usr/bin/env python3
"""Seed Classical Arabic content (Qur'an) into database.

This script parses the Qur'an JSON file and inserts Arabic texts
into the database with proper structure.
"""

import asyncio
import json
import logging
import sys
import unicodedata
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.core.config import settings
from app.db.models import Base, Language, SourceDoc, TextSegment, TextWork

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def normalize_text(text: str) -> tuple[str, str, str]:
    """Normalize text to NFC, and create folded version."""
    text_raw = text.strip()
    text_nfc = unicodedata.normalize("NFC", text_raw)
    text_fold = "".join(
        c
        for c in unicodedata.normalize("NFD", text_nfc.lower())
        if not unicodedata.combining(c)
    )
    return text_raw, text_nfc, text_fold


def parse_quran_json(json_path: Path) -> list[dict]:
    """Parse Qur'an JSON format.

    Args:
        json_path: Path to quran.json file

    Returns:
        List of segments with structure:
        {"ref": "1.1", "chapter": 1, "verse": 1, "text": "..."}
    """
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    segments = []
    for chapter_num_str, verses in data.items():
        for verse_data in verses:
            chapter = verse_data["chapter"]
            verse = verse_data["verse"]
            text = verse_data["text"]

            ref = f"{chapter}.{verse}"
            segments.append({
                "ref": ref,
                "chapter": chapter,
                "verse": verse,
                "text": text,
            })

    logger.info(f"Parsed {len(segments)} verses from Qur'an JSON")
    return segments


async def seed_language(session: AsyncSession, code: str, name: str) -> Language:
    """Get or create language."""
    result = await session.execute(select(Language).where(Language.code == code))
    lang = result.scalar_one_or_none()

    if not lang:
        lang = Language(code=code, name=name)
        session.add(lang)
        await session.flush()
        logger.info(f"Created language: {code} ({name})")
    else:
        logger.info(f"Language {code} already exists")

    return lang


async def seed_source_doc(
    session: AsyncSession, slug: str, title: str, license_info: dict
) -> SourceDoc:
    """Get or create source document."""
    result = await session.execute(select(SourceDoc).where(SourceDoc.slug == slug))
    doc = result.scalar_one_or_none()

    if not doc:
        doc = SourceDoc(
            slug=slug,
            title=title,
            license=license_info,
            meta={
                "source": "Quranic Text (via risan/quran-json)",
                "url": "https://github.com/risan/quran-json",
            },
        )
        session.add(doc)
        await session.flush()
        logger.info(f"Created source doc: {slug}")
    else:
        logger.info(f"Source doc {slug} already exists")

    return doc


async def seed_text_work(
    session: AsyncSession,
    language_id: int,
    source_id: int,
    author: str,
    title: str,
    ref_scheme: str,
) -> TextWork:
    """Get or create text work."""
    result = await session.execute(
        select(TextWork).where(
            TextWork.language_id == language_id,
            TextWork.source_id == source_id,
            TextWork.author == author,
            TextWork.title == title,
        )
    )
    work = result.scalar_one_or_none()

    if not work:
        work = TextWork(
            language_id=language_id,
            source_id=source_id,
            author=author,
            title=title,
            ref_scheme=ref_scheme,
        )
        session.add(work)
        await session.flush()
        logger.info(f"Created text work: {title} by {author}")
    else:
        logger.info(f"Text work '{title}' already exists")

    return work


async def seed_quran_work(
    session: AsyncSession,
    json_path: Path,
    lang: Language,
    source: SourceDoc,
):
    """Seed Qur'an from JSON."""
    logger.info("Seeding Qur'an...")

    # Parse the JSON to get all verses
    segments = parse_quran_json(json_path)

    # Create the work
    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author="Various",
        title="القرآن الكريم (The Holy Qur'an)",
        ref_scheme="chapter.verse",
    )

    # Check existing segments
    result = await session.execute(
        select(TextSegment.ref).where(TextSegment.work_id == work.id)
    )
    existing_refs = {row[0] for row in result.fetchall()}

    # Insert new segments
    new_count = 0
    for seg in segments:
        if seg["ref"] in existing_refs:
            continue

        text_raw, text_nfc, text_fold = normalize_text(seg["text"])
        segment = TextSegment(
            work_id=work.id,
            ref=seg["ref"],
            text_raw=text_raw,
            text_nfc=text_nfc,
            text_fold=text_fold,
            meta={"chapter": seg["chapter"], "verse": seg["verse"]},
        )
        session.add(segment)
        new_count += 1

    await session.commit()
    logger.info(
        f"[OK] Seeded {new_count} new Qur'an verses "
        f"(skipped {len(existing_refs)} existing)"
    )


async def main():
    """Main seeding function."""
    logger.info("=" * 60)
    logger.info("CLASSICAL ARABIC (QUR'AN) SEEDING")
    logger.info("=" * 60)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        lang = await seed_language(session, "ara", "Classical Arabic")

        source = await seed_source_doc(
            session,
            slug="quran",
            title="The Holy Qur'an",
            license_info={
                "name": "Public Domain / Creative Commons",
                "url": "https://github.com/risan/quran-json",
                "note": "Quranic text is generally considered public domain"
            },
        )

        # Path to Qur'an JSON
        json_path = (
            Path(__file__).parent.parent
            / "data"
            / "arabic-quran"
            / "quran.json"
        )

        if json_path.exists():
            await seed_quran_work(session, json_path, lang, source)
        else:
            logger.error(f"[X] File not found: {json_path}")

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("[OK] CLASSICAL ARABIC SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
