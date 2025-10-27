#!/usr/bin/env python3
"""Seed Perseus Digital Library Classical Greek content into database.

This script parses Perseus TEI XML files and inserts Greek texts
into the database with proper structure.
"""

import asyncio
import logging
import sys
import unicodedata
import xml.etree.ElementTree as ET
from io import StringIO
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
        c for c in unicodedata.normalize("NFD", text_nfc.lower()) if not unicodedata.combining(c)
    )
    return text_raw, text_nfc, text_fold


def parse_perseus_greek_xml(xml_path: Path, work_abbr: str) -> list[dict]:
    """Parse Perseus TEI XML format for Greek poetry texts.

    Args:
        xml_path: Path to XML file
        work_abbr: Work abbreviation (e.g., "Theog", "WD", "OT")

    Returns list of segments with structure:
        {"ref": "Theog.1", "line": 1, "text": "..."}
    """
    # Handle XML entities
    try:
        tree = ET.parse(xml_path)
    except ET.ParseError as e:
        logger.warning(f"XML Parse Error in {xml_path}: {e}")
        logger.warning("Attempting to parse with entity replacement...")

        with open(xml_path, "r", encoding="utf-8") as f:
            content = f.read()

        replacements = {
            "&dagger;": "†",
            "&mdash;": "—",
            "&ndash;": "–",
            "&ldquo;": '"',
            "&rdquo;": '"',
            "&lsquo;": "'",
            "&rsquo;": "'",
            "&nbsp;": " ",
            "&hellip;": "…",
        }

        for old, new in replacements.items():
            content = content.replace(old, new)

        tree = ET.parse(StringIO(content))

    root = tree.getroot()
    ns = {"tei": "http://www.tei-c.org/ns/1.0"}
    segments = []
    seen_refs = set()

    # Find all lines (Greek poetry is typically not divided into books for shorter works)
    for line_elem in root.findall(".//tei:l", ns):
        line_n = line_elem.get("n")
        if not line_n:
            continue

        # Get text content
        text_parts = []
        for text in line_elem.itertext():
            cleaned = text.strip()
            if cleaned:
                text_parts.append(cleaned)

        text = " ".join(text_parts)
        if not text:
            continue

        try:
            line_int = int(line_n)
        except ValueError:
            continue

        ref = f"{work_abbr}.{line_int}"
        if ref in seen_refs:
            continue
        seen_refs.add(ref)

        segments.append(
            {
                "ref": ref,
                "line": line_int,
                "text": text,
            }
        )

    logger.info(f"Parsed {len(segments)} lines from {work_abbr} XML")
    return segments


def parse_perseus_epic_xml(xml_path: Path, work_abbr: str) -> list[dict]:
    """Parse Perseus TEI XML format for Greek epic poetry (with book.line structure).

    Args:
        xml_path: Path to XML file
        work_abbr: Work abbreviation (e.g., "Il", "Od")

    Returns list of segments with book.line structure
    """
    try:
        tree = ET.parse(xml_path)
    except ET.ParseError as e:
        logger.warning(f"XML Parse Error: {e}")
        with open(xml_path, "r", encoding="utf-8") as f:
            content = f.read()
        replacements = {"&dagger;": "†", "&mdash;": "—", "&ndash;": "–", "&nbsp;": " "}
        for old, new in replacements.items():
            content = content.replace(old, new)
        tree = ET.parse(StringIO(content))

    root = tree.getroot()
    ns = {"tei": "http://www.tei-c.org/ns/1.0"}
    segments = []
    seen_refs = set()

    # Find book divs (case-insensitive for subtype - Iliad uses "Book" vs "book")
    book_divs = []
    for div in root.findall(".//tei:div[@type='textpart']", ns):
        subtype = div.get("subtype", "").lower()
        if subtype == "book":
            book_divs.append(div)

    for book_div in book_divs:
        book_n = book_div.get("n")
        if not book_n:
            continue

        try:
            book_int = int(book_n)
        except ValueError:
            continue

        # Find lines within this book
        for line_elem in book_div.findall(".//tei:l", ns):
            line_n = line_elem.get("n")
            if not line_n:
                continue

            try:
                line_int = int(line_n)
            except ValueError:
                continue

            # Get text content
            text_parts = []
            for text in line_elem.itertext():
                cleaned = text.strip()
                if cleaned:
                    text_parts.append(cleaned)

            text = " ".join(text_parts)
            if not text:
                continue

            ref = f"{work_abbr}.{book_int}.{line_int}"
            if ref in seen_refs:
                continue
            seen_refs.add(ref)

            segments.append(
                {
                    "ref": ref,
                    "book": book_int,
                    "line": line_int,
                    "text": text,
                }
            )

    logger.info(f"Parsed {len(segments)} lines from {work_abbr} epic XML")
    return segments


def parse_perseus_greek_prose_xml(xml_path: Path, work_abbr: str) -> list[dict]:
    """Parse Perseus TEI XML format for Greek prose (with book structure).

    Args:
        xml_path: Path to XML file
        work_abbr: Work abbreviation (e.g., "Hist", "Pel")

    Returns list of segments with book.chapter structure
    """
    try:
        tree = ET.parse(xml_path)
    except ET.ParseError as e:
        logger.warning(f"XML Parse Error: {e}")
        with open(xml_path, "r", encoding="utf-8") as f:
            content = f.read()
        replacements = {"&dagger;": "†", "&mdash;": "—", "&ndash;": "–"}
        for old, new in replacements.items():
            content = content.replace(old, new)
        tree = ET.parse(StringIO(content))

    root = tree.getroot()
    ns = {"tei": "http://www.tei-c.org/ns/1.0"}
    segments = []
    seen_refs = set()

    # Find book divs
    for book_div in root.findall(".//tei:div[@type='textpart'][@subtype='book']", ns):
        book_n = book_div.get("n")
        if not book_n:
            continue

        try:
            book_int = int(book_n)
        except ValueError:
            continue

        # Find chapters or sections (Republic uses "section" instead of "chapter")
        chapter_divs = book_div.findall(".//tei:div[@subtype='chapter']", ns)
        if not chapter_divs:
            chapter_divs = book_div.findall(".//tei:div[@subtype='section']", ns)

        for chapter_div in chapter_divs:
            chapter_n = chapter_div.get("n")
            if not chapter_n:
                continue

            try:
                chapter_int = int(chapter_n)
            except ValueError:
                continue

            # Get all paragraph text
            text_parts = []
            for p in chapter_div.findall(".//tei:p", ns):
                for text in p.itertext():
                    cleaned = text.strip()
                    if cleaned:
                        text_parts.append(cleaned)

            text = " ".join(text_parts)
            if not text:
                continue

            ref = f"{work_abbr}.{book_int}.{chapter_int}"
            if ref in seen_refs:
                continue
            seen_refs.add(ref)

            segments.append(
                {
                    "ref": ref,
                    "line": chapter_int,
                    "text": text,
                }
            )

    logger.info(f"Parsed {len(segments)} chapters from {work_abbr} XML")
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


async def seed_source_doc(session: AsyncSession, slug: str, title: str, license_info: dict) -> SourceDoc:
    """Get or create source document."""
    result = await session.execute(select(SourceDoc).where(SourceDoc.slug == slug))
    doc = result.scalar_one_or_none()

    if not doc:
        doc = SourceDoc(
            slug=slug,
            title=title,
            license=license_info,
            meta={
                "source": "Perseus Digital Library",
                "url": "https://github.com/PerseusDL/canonical-greekLit",
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


async def seed_greek_work(
    session: AsyncSession,
    xml_path: Path,
    author: str,
    title: str,
    work_abbr: str,
    work_type: str,
    lang: Language,
    source: SourceDoc,
):
    """Seed a single Greek work.

    Args:
        work_type: "epic" (book.line), "poetry" (line), or "prose" (book.chapter)
    """
    logger.info(f"Seeding {title} by {author}...")

    if work_type == "epic":
        segments = parse_perseus_epic_xml(xml_path, work_abbr)
        ref_scheme = "book.line"
    elif work_type == "prose":
        segments = parse_perseus_greek_prose_xml(xml_path, work_abbr)
        ref_scheme = "book.chapter"
    else:  # poetry
        segments = parse_perseus_greek_xml(xml_path, work_abbr)
        ref_scheme = "line"

    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author=author,
        title=title,
        ref_scheme=ref_scheme,
    )

    # Check existing segments
    result = await session.execute(select(TextSegment.ref).where(TextSegment.work_id == work.id))
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
            meta={"line": seg["line"]},
        )
        session.add(segment)
        new_count += 1

    await session.commit()
    logger.info(
        f"[OK] Seeded {new_count} new {title} segments (skipped {len(segments) - new_count} existing)"
    )


async def main():
    """Main seeding function."""
    logger.info("=" * 60)
    logger.info("CLASSICAL GREEK (PERSEUS) SEEDING - ALL 10 WORKS")
    logger.info("=" * 60)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        lang = await seed_language(session, "grc", "Classical Greek")

        source = await seed_source_doc(
            session,
            slug="perseus-greek-texts",
            title="Perseus Digital Library - Classical Greek Texts",
            license_info={
                "name": "Creative Commons Attribution-ShareAlike 3.0",
                "url": "https://creativecommons.org/licenses/by-sa/3.0/",
            },
        )

        base_dir = Path(__file__).parent.parent / "data" / "canonical-greekLit" / "data"

        # All 10 Classical Greek works with TLG codes
        greek_works = [
            # (tlg_author, tlg_work, author, title, abbreviation, work_type)
            # work_type: "epic" (book.line), "poetry" (line), "prose" (book.chapter)
            ("tlg0012", "tlg001", "Homer", "Iliad", "Il", "epic"),
            ("tlg0012", "tlg002", "Homer", "Odyssey", "Od", "epic"),
            ("tlg0020", "tlg001", "Hesiod", "Theogony", "Theog", "poetry"),
            ("tlg0020", "tlg002", "Hesiod", "Works and Days", "WD", "poetry"),
            ("tlg0011", "tlg004", "Sophocles", "Oedipus Rex", "OT", "poetry"),
            ("tlg0011", "tlg002", "Sophocles", "Antigone", "Ant", "poetry"),
            ("tlg0006", "tlg003", "Euripides", "Medea", "Med", "poetry"),
            ("tlg0016", "tlg001", "Herodotus", "Histories", "Hist", "prose"),
            ("tlg0003", "tlg001", "Thucydides", "History of the Peloponnesian War", "Pel", "prose"),
            ("tlg0059", "tlg030", "Plato", "Republic", "Rep", "prose"),
        ]

        for tlg_author, tlg_work, author, title, abbr, work_type in greek_works:
            xml_path = base_dir / tlg_author / tlg_work / f"{tlg_author}.{tlg_work}.perseus-grc2.xml"

            if xml_path.exists():
                await seed_greek_work(session, xml_path, author, title, abbr, work_type, lang, source)
            else:
                logger.warning(f"[X] File not found: {xml_path}")

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("[OK] CLASSICAL GREEK SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
