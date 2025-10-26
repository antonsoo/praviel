#!/usr/bin/env python3
"""Seed Old Church Slavonic content from PROIEL Treebank into database.

This script parses PROIEL XML files and inserts Old Church Slavonic texts
into the database with proper structure.
"""

import asyncio
import logging
import sys
import unicodedata
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List

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


def parse_proiel_ocs_xml(xml_path: Path) -> Dict[str, List[dict]]:
    """Parse PROIEL XML format for Old Church Slavonic (Codex Marianus).

    Args:
        xml_path: Path to marianus.xml file

    Returns:
        Dict mapping book abbreviations to lists of segments:
        {
            "MATT": [{"ref": "Matt.1.1", "chapter": 1, "verse": 1, "text": "..."}, ...],
            "MARK": [...],
            ...
        }
    """
    tree = ET.parse(xml_path)
    root = tree.getroot()

    # Dictionary to hold segments by book
    books: Dict[str, List[dict]] = {}

    # Find all sentences
    for sentence in root.findall(".//sentence"):
        tokens = sentence.findall("token")
        if not tokens:
            continue

        # Get citation from first token
        first_token = tokens[0]
        citation = first_token.get("citation-part", "")

        if not citation:
            continue

        # Parse citation (e.g., "MATT 5.24" -> book="MATT", chapter=5, verse=24)
        try:
            parts = citation.split()
            if len(parts) != 2:
                continue

            book_abbr = parts[0]
            chapter_verse = parts[1].split(".")
            if len(chapter_verse) != 2:
                continue

            chapter = int(chapter_verse[0])
            verse = int(chapter_verse[1])
        except (ValueError, IndexError):
            continue

        # Collect all text forms from tokens in this sentence
        text_parts = []
        for token in tokens:
            form = token.get("form")
            if form:
                text_parts.append(form)

        if not text_parts:
            continue

        sentence_text = " ".join(text_parts)

        # Create reference in format: "Book.Chapter.Verse"
        book_name_map = {
            "MATT": "Matthew",
            "MARK": "Mark",
            "LUKE": "Luke",
            "JOHN": "John",
        }
        book_name = book_name_map.get(book_abbr, book_abbr)
        ref = f"{book_name}.{chapter}.{verse}"

        # Initialize book list if needed
        if book_abbr not in books:
            books[book_abbr] = []

        # Check if we already have this verse (PROIEL may have multiple sentences per verse)
        existing = next((s for s in books[book_abbr] if s["ref"] == ref), None)
        if existing:
            # Append to existing verse text
            existing["text"] += " " + sentence_text
        else:
            # Add new verse
            books[book_abbr].append({
                "ref": ref,
                "chapter": chapter,
                "verse": verse,
                "text": sentence_text,
            })

    # Sort verses within each book
    for book_segments in books.values():
        book_segments.sort(key=lambda x: (x["chapter"], x["verse"]))

    logger.info(f"Parsed {sum(len(segs) for segs in books.values())} verses from {len(books)} books")
    return books


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
                "source": "PROIEL Treebank",
                "url": "https://github.com/proiel/proiel-treebank",
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


async def seed_ocs_work(
    session: AsyncSession,
    xml_path: Path,
    lang: Language,
    source: SourceDoc,
):
    """Seed Codex Marianus (Gospels) from PROIEL XML."""
    logger.info("Seeding Codex Marianus (Gospels)...")

    # Parse the XML to get all books
    books_data = parse_proiel_ocs_xml(xml_path)

    # Create the work
    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author="Various",
        title="Codex Marianus (Gospels)",
        ref_scheme="book.chapter.verse",
    )

    # Check existing segments
    result = await session.execute(
        select(TextSegment.ref).where(TextSegment.work_id == work.id)
    )
    existing_refs = {row[0] for row in result.fetchall()}

    # Insert new segments from all books
    new_count = 0
    for book_abbr, segments in books_data.items():
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
        f"[OK] Seeded {new_count} new Codex Marianus segments "
        f"(skipped {len(existing_refs)} existing)"
    )


async def main():
    """Main seeding function."""
    logger.info("=" * 60)
    logger.info("OLD CHURCH SLAVONIC (PROIEL) SEEDING")
    logger.info("=" * 60)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        lang = await seed_language(session, "cu", "Old Church Slavonic")

        source = await seed_source_doc(
            session,
            slug="proiel-ocs",
            title="PROIEL Treebank - Old Church Slavonic Texts",
            license_info={
                "name": "Creative Commons Attribution-NonCommercial-ShareAlike 3.0",
                "url": "http://creativecommons.org/licenses/by-nc-sa/3.0/us/",
            },
        )

        # Path to PROIEL marianus.xml
        xml_path = (
            Path(__file__).parent.parent
            / "data"
            / "proiel-treebank"
            / "marianus.xml"
        )

        if xml_path.exists():
            await seed_ocs_work(session, xml_path, lang, source)
        else:
            logger.error(f"[X] File not found: {xml_path}")

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("[OK] OLD CHURCH SLAVONIC SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
