#!/usr/bin/env python3
"""Seed Ancient Aramaic content (Targum Onkelos) into database.

This script parses Targum Onkelos JSON files from Sefaria and inserts Aramaic texts
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


def parse_sefaria_targum_json(json_path: Path, book_name: str) -> list[dict]:
    """Parse Sefaria Targum JSON format.

    Args:
        json_path: Path to targum JSON file
        book_name: Name of the book (e.g., "Genesis", "Exodus")

    Returns:
        List of segments with structure:
        {"ref": "Gen.1.1", "chapter": 1, "verse": 1, "text": "..."}
    """
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Get the primary Hebrew version text
    segments = []
    versions = data.get("versions", [])
    if not versions:
        logger.warning(f"No versions found in {json_path}")
        return segments

    # Get the text from the first version
    version = versions[0]
    text_data = version.get("text", [])

    # text_data is a list of chapters, each chapter is a list of verses
    for chapter_idx, chapter_verses in enumerate(text_data):
        chapter_num = chapter_idx + 1
        if isinstance(chapter_verses, list):
            for verse_idx, verse_text in enumerate(chapter_verses):
                verse_num = verse_idx + 1
                if verse_text and isinstance(verse_text, str):
                    ref = f"{book_name}.{chapter_num}.{verse_num}"
                    segments.append({
                        "ref": ref,
                        "chapter": chapter_num,
                        "verse": verse_num,
                        "text": verse_text,
                    })

    logger.info(f"Parsed {len(segments)} verses from {book_name}")
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
                "source": "Sefaria.org",
                "url": "https://www.sefaria.org",
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


async def seed_targum_book(
    session: AsyncSession,
    json_path: Path,
    book_name: str,
    book_title: str,
    lang: Language,
    source: SourceDoc,
):
    """Seed one book of Targum Onkelos."""
    logger.info(f"Seeding {book_title}...")

    # Parse the JSON to get all verses
    segments = parse_sefaria_targum_json(json_path, book_name)

    if not segments:
        logger.warning(f"No segments found for {book_title}")
        return

    # Create the work
    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author="Onkelos",
        title=f"Targum Onkelos - {book_title}",
        ref_scheme="book.chapter.verse",
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
        f"[OK] Seeded {new_count} new {book_title} verses "
        f"(skipped {len(existing_refs)} existing)"
    )


async def main():
    """Main seeding function."""
    logger.info("=" * 60)
    logger.info("ANCIENT ARAMAIC (TARGUMIM) SEEDING")
    logger.info("=" * 60)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        lang = await seed_language(session, "arc", "Ancient Aramaic")

        # Targum Onkelos source
        source_onkelos = await seed_source_doc(
            session,
            slug="targum-onkelos",
            title="Targum Onkelos (Aramaic Torah)",
            license_info={
                "name": "Public Domain",
                "url": "https://www.sefaria.org",
                "note": "Ancient Aramaic translation of the Torah"
            },
        )

        # Targum Jonathan source
        source_jonathan = await seed_source_doc(
            session,
            slug="targum-jonathan",
            title="Targum Jonathan (Aramaic Prophets)",
            license_info={
                "name": "Public Domain",
                "url": "https://www.sefaria.org",
                "note": "Ancient Aramaic translation of the Prophets"
            },
        )

        # Path to Targum JSON files
        base_path = Path(__file__).parent.parent / "data" / "aramaic-targum"

        # Targum Onkelos - Books of the Torah
        logger.info("\n--- Seeding Targum Onkelos (Torah) ---")
        onkelos_books = [
            ("onkelos_genesis.json", "Genesis", "בראשית (Genesis)"),
            ("onkelos_exodus.json", "Exodus", "שמות (Exodus)"),
            ("onkelos_leviticus.json", "Leviticus", "ויקרא (Leviticus)"),
            ("onkelos_numbers.json", "Numbers", "במדבר (Numbers)"),
            ("onkelos_deuteronomy.json", "Deuteronomy", "דברים (Deuteronomy)"),
        ]

        for filename, book_name, book_title in onkelos_books:
            json_path = base_path / filename
            if json_path.exists():
                await seed_targum_book(session, json_path, book_name, book_title, lang, source_onkelos)
            else:
                logger.error(f"[X] File not found: {json_path}")

        # Targum Jonathan - Books of the Prophets
        logger.info("\n--- Seeding Targum Jonathan (Prophets) ---")
        jonathan_books = [
            ("jonathan_joshua.json", "Joshua", "יהושע (Joshua)"),
            ("jonathan_judges.json", "Judges", "שופטים (Judges)"),
            ("jonathan_samuel_i.json", "I_Samuel", "שמואל א (I Samuel)"),
            ("jonathan_isaiah.json", "Isaiah", "ישעיהו (Isaiah)"),
        ]

        for filename, book_name, book_title in jonathan_books:
            json_path = base_path / filename
            if json_path.exists():
                await seed_targum_book(session, json_path, book_name, book_title, lang, source_jonathan)
            else:
                logger.warning(f"[!] File not found (skipping): {json_path}")

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("[OK] ANCIENT ARAMAIC SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
