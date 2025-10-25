#!/usr/bin/env python3
"""Seed Westminster Leningrad Codex (UXLC) Hebrew Bible content into database.

This script parses the UXLC XML files and inserts Hebrew Biblical texts
into the database with proper structure.
"""

import asyncio
import logging
import sys
import unicodedata
import xml.etree.ElementTree as ET
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
    """Normalize text to NFC, and create folded version.

    Returns:
        (text_raw, text_nfc, text_fold)
    """
    text_raw = text.strip()
    text_nfc = unicodedata.normalize("NFC", text_raw)
    # Folded: lowercase, remove accents and cantillation marks
    text_fold = "".join(
        c
        for c in unicodedata.normalize("NFD", text_nfc.lower())
        if not unicodedata.combining(c)
    )
    return text_raw, text_nfc, text_fold


def parse_uxlc_book(xml_path: Path) -> tuple[dict, list[dict]]:
    """Parse UXLC format Hebrew Bible book.

    Args:
        xml_path: Path to XML file (e.g., Genesis.xml)

    Returns:
        tuple of (book_info, segments)
        book_info: {"title": "Genesis", "hebrew_title": "בראשית", "abbrev": "Gen"}
        segments: [{"ref": "Gen.1.1", "chapter": 1, "verse": 1, "text": "..."}]
    """
    tree = ET.parse(xml_path)
    root = tree.getroot()

    # Extract book metadata
    book_elem = root.find(".//book")
    if book_elem is None:
        raise ValueError(f"No <book> element found in {xml_path}")

    names_elem = book_elem.find("names")
    title = names_elem.findtext("name", "Unknown")
    abbrev = names_elem.findtext("abbrev", "Unknown")
    hebrew_name = names_elem.findtext("hebrewname", "")

    book_info = {
        "title": title,
        "hebrew_title": hebrew_name,
        "abbrev": abbrev,
    }

    # Parse chapters and verses
    segments = []
    for chapter in book_elem.findall("c"):
        chapter_num = int(chapter.get("n", 0))
        if chapter_num == 0:
            continue

        for verse in chapter.findall("v"):
            verse_num = int(verse.get("n", 0))
            if verse_num == 0:
                continue

            # Collect all words in the verse
            words = []
            for word in verse.findall("w"):
                word_text = word.text or ""
                if word_text.strip():
                    words.append(word_text.strip())

            if not words:
                continue

            verse_text = " ".join(words)
            ref = f"{abbrev}.{chapter_num}.{verse_num}"

            segments.append(
                {
                    "ref": ref,
                    "chapter": chapter_num,
                    "verse": verse_num,
                    "text": verse_text,
                }
            )

    logger.info(f"Parsed {len(segments)} verses from {title}")
    return book_info, segments


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
                "source": "Westminster Leningrad Codex (UXLC)",
                "url": "https://tanach.us/",
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


async def seed_hebrew_book(
    session: AsyncSession,
    xml_path: Path,
    author: str,
    title: str,
    hebrew_title: str,
    lang: Language,
    source: SourceDoc,
):
    """Seed a single Hebrew Bible book."""
    logger.info(f"Seeding {title} ({hebrew_title})...")

    book_info, segments = parse_uxlc_book(xml_path)

    # Override title if provided (for cleaner display)
    display_title = f"{title} ({hebrew_title})" if hebrew_title else title

    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author=author,
        title=display_title,
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
        f"✅ Seeded {new_count} new {title} segments "
        f"(skipped {len(segments) - new_count} existing)"
    )


async def main():
    """Main seeding function."""
    logger.info("=" * 60)
    logger.info("HEBREW BIBLE (UXLC) SEEDING - TOP 10 BOOKS")
    logger.info("=" * 60)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Create language and source
        lang = await seed_language(session, "hbo", "Biblical Hebrew")

        source = await seed_source_doc(
            session,
            slug="uxlc-hebrew-bible",
            title="Westminster Leningrad Codex (UXLC)",
            license_info={
                "name": "Public Domain",
                "url": "https://tanach.us/Pages/About.html",
            },
        )

        data_dir = Path(__file__).parent.parent / "data" / "tanach_uxlc" / "Books"

        # Top 10 books according to TOP_TEN_WORKS_PER_LANGUAGE.md
        books_to_seed = [
            ("Genesis.xml", "Torah", "Genesis", "Bereshit"),
            ("Exodus.xml", "Torah", "Exodus", "Shemot"),
            ("Deuteronomy.xml", "Torah", "Deuteronomy", "Devarim"),
            ("Isaiah.xml", "Neviim", "Isaiah", "Yeshayahu"),
            ("Samuel_1.xml", "Neviim", "1 Samuel", "Shmuel Alef"),
            ("Samuel_2.xml", "Neviim", "2 Samuel", "Shmuel Bet"),
            ("Kings_1.xml", "Neviim", "1 Kings", "Melakhim Alef"),
            ("Kings_2.xml", "Neviim", "2 Kings", "Melakhim Bet"),
            ("Jeremiah.xml", "Neviim", "Jeremiah", "Yirmeyahu"),
            ("Ezekiel.xml", "Neviim", "Ezekiel", "Yehezkel"),
            ("Psalms.xml", "Ketuvim", "Psalms", "Tehillim"),
            ("Job.xml", "Ketuvim", "Job", "Iyov"),
        ]

        for filename, author, title, hebrew_title in books_to_seed:
            xml_path = data_dir / filename
            if xml_path.exists():
                await seed_hebrew_book(
                    session, xml_path, author, title, hebrew_title, lang, source
                )
            else:
                logger.warning(f"❌ File not found: {xml_path}")

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("✅ HEBREW BIBLE SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
