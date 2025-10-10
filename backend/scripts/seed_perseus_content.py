#!/usr/bin/env python3
"""Seed Perseus Digital Library content into database.

This script downloads and processes canonical Greek texts from Perseus,
parsing them and inserting into the database with proper structure.
"""

import asyncio
import logging

# Add parent directory to path for imports
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
    # Folded: lowercase, remove accents
    text_fold = "".join(
        c for c in unicodedata.normalize("NFD", text_nfc.lower()) if not unicodedata.combining(c)
    )
    return text_raw, text_nfc, text_fold


def parse_iliad_xml(xml_path: Path) -> list[dict]:
    """Parse Perseus XML format for Iliad.

    Returns list of segments with structure:
        {"ref": "1.1", "book": 1, "line": 1, "text": "μῆνιν ἄειδε..."}
    """
    # Parse with explicit UTF-8 encoding
    tree = ET.parse(xml_path)
    root = tree.getroot()

    # Perseus XML uses TEI namespace
    ns = {"tei": "http://www.tei-c.org/ns/1.0"}

    segments = []

    # Find all textpart div elements with subtype="Book"
    for div in root.findall(".//tei:div[@subtype='Book']", ns):
        book_n = div.get("n")
        if not book_n:
            continue

        # Find all lines (l elements) in this book
        for line_elem in div.findall(".//tei:l", ns):
            line_n = line_elem.get("n")
            if not line_n:
                continue

            # Get text content, removing any nested tags (like milestone)
            # Use itertext() to get all text, then clean it
            text_parts = []
            for text in line_elem.itertext():
                cleaned = text.strip()
                if cleaned:
                    text_parts.append(cleaned)

            text = " ".join(text_parts)
            if not text:
                continue

            segments.append(
                {"ref": f"{book_n}.{line_n}", "book": int(book_n), "line": int(line_n), "text": text}
            )

    logger.info(f"Parsed {len(segments)} lines from Iliad XML")
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
    session: AsyncSession, language_id: int, source_id: int, author: str, title: str, ref_scheme: str
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
            language_id=language_id, source_id=source_id, author=author, title=title, ref_scheme=ref_scheme
        )
        session.add(work)
        await session.flush()
        logger.info(f"Created text work: {title} by {author}")
    else:
        logger.info(f"Text work '{title}' already exists")

    return work


async def seed_iliad(session: AsyncSession, xml_path: Path, max_books: int = 1):
    """Seed Homer's Iliad from Perseus XML.

    Args:
        session: Database session
        xml_path: Path to Iliad XML file
        max_books: Maximum number of books to seed (default 1 for quick start)
    """
    logger.info(f"Seeding Iliad (first {max_books} books)...")

    # 1. Create/get language
    lang = await seed_language(session, "grc", "Ancient Greek")

    # 2. Create/get source doc
    source = await seed_source_doc(
        session,
        slug="perseus-homer-iliad",
        title="Homer's Iliad (Perseus Digital Library)",
        license_info={
            "name": "Creative Commons Attribution-ShareAlike 3.0",
            "url": "https://creativecommons.org/licenses/by-sa/3.0/",
        },
    )

    # 3. Create/get work
    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author="Homer",
        title="Iliad",
        ref_scheme="book.line",
    )

    # 4. Parse XML
    segments = parse_iliad_xml(xml_path)

    # Filter to max_books
    segments = [s for s in segments if s["book"] <= max_books]
    logger.info(f"Seeding {len(segments)} lines (books 1-{max_books})")

    # 5. Check existing segments
    result = await session.execute(select(TextSegment.ref).where(TextSegment.work_id == work.id))
    existing_refs = {row[0] for row in result.fetchall()}

    # 6. Insert new segments
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
            meta={"book": seg["book"], "line": seg["line"]},
        )
        session.add(segment)
        new_count += 1

    await session.commit()
    logger.info(f"✅ Seeded {new_count} new Iliad segments (skipped {len(segments) - new_count} existing)")


async def seed_additional_vocabulary(session: AsyncSession):
    """Seed additional Greek vocabulary from common word lists."""
    logger.info("Seeding additional Greek vocabulary...")

    # Get Greek language
    result = await session.execute(select(Language).where(Language.code == "grc"))
    lang = result.scalar_one_or_none()
    if not lang:
        lang = await seed_language(session, "grc", "Ancient Greek")

    # Create source for vocabulary
    source = await seed_source_doc(
        session,
        slug="common-greek-vocab",
        title="Common Ancient Greek Vocabulary",
        license_info={"name": "Public Domain"},
    )

    # Create work for vocabulary lists
    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author="Various",
        title="Common Greek Phrases and Sentences",
        ref_scheme="phrase.n",
    )

    # Common sentences beyond just vocabulary
    common_phrases = [
        # Questions and greetings
        ("Τί ἐστιν ὄνομά σοι;", "What is your name?"),
        ("Πόθεν εἶ;", "Where are you from?"),
        ("Πόσων ἐτῶν εἶ;", "How old are you?"),
        ("Τί ποιεῖς;", "What are you doing?"),
        ("Πῶς ἔχεις;", "How are you?"),
        # Statements
        ("Μαθητής εἰμι.", "I am a student."),
        ("Διδάσκαλός εἰμι.", "I am a teacher."),
        ("Ἐν Ἀθήναις οἰκῶ.", "I live in Athens."),
        ("Ἑλληνικὰ μανθάνω.", "I am learning Greek."),
        ("Βιβλίον ἀναγιγνώσκω.", "I am reading a book."),
        # Commands
        ("Ἐλθὲ δεῦρο.", "Come here."),
        ("Κάθισον.", "Sit down."),
        ("Ἄκουσον.", "Listen."),
        ("Λέγε.", "Speak."),
        ("Γράψον.", "Write."),
        # Common expressions
        ("Οὐκ οἶδα.", "I don't know."),
        ("Ἐννοῶ.", "I understand."),
        ("Οὐκ ἐννοῶ.", "I don't understand."),
        ("Πάλιν λέγε, παρακαλῶ.", "Please say again."),
        ("Βραδύτερον λέγε.", "Speak more slowly."),
        # Longer sentences
        ("Ὁ διδάσκαλος τοὺς μαθητὰς διδάσκει.", "The teacher teaches the students."),
        ("Ἡ μήτηρ τὸ τέκνον φιλεῖ.", "The mother loves the child."),
        ("Οἱ στρατιῶται ὑπὲρ τῆς πατρίδος μάχονται.", "The soldiers fight for their country."),
        ("Ὁ σοφὸς ἀνὴρ πολλὰ γιγνώσκει.", "The wise man knows many things."),
        ("Τὸ ἀγαθὸν βιβλίον ἀνδρὶ σοφῷ ἐστιν φίλον.", "A good book is dear to a wise man."),
        # Philosophical sentences (simple)
        ("Γνῶθι σεαυτόν.", "Know thyself."),
        ("Μηδὲν ἄγαν.", "Nothing in excess."),
        ("Ὁ βίος βραχύς, ἡ δὲ τέχνη μακρή.", "Life is short, but art is long."),
        ("Ἀρχὴ ἥμισυ παντός.", "The beginning is half of everything."),
        ("Ὁ μὴ δαρεὶς ἄνθρωπος οὐ παιδεύεται.", "The person who is not beaten is not educated."),
    ]

    # Check existing
    result = await session.execute(select(TextSegment.ref).where(TextSegment.work_id == work.id))
    existing_refs = {row[0] for row in result.fetchall()}

    # Insert new phrases
    new_count = 0
    for i, (grc, en) in enumerate(common_phrases, 1):
        ref = f"phrase.{i}"
        if ref in existing_refs:
            continue

        text_raw, text_nfc, text_fold = normalize_text(grc)

        segment = TextSegment(
            work_id=work.id,
            ref=ref,
            text_raw=text_raw,
            text_nfc=text_nfc,
            text_fold=text_fold,
            meta={"translation": en, "type": "common_phrase"},
        )
        session.add(segment)
        new_count += 1

    await session.commit()
    logger.info(f"✅ Seeded {new_count} additional vocabulary phrases")


async def main():
    """Main seeding function."""
    logger.info("=" * 60)
    logger.info("PERSEUS CONTENT SEEDING")
    logger.info("=" * 60)

    # Create async engine
    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    # Create tables if they don't exist
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Create session
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # 1. Seed Iliad (Books 1-12 for comprehensive content)
        iliad_path = Path(__file__).parent.parent / "data" / "iliad_grc.xml"
        if iliad_path.exists():
            await seed_iliad(session, iliad_path, max_books=12)
        else:
            logger.warning(f"Iliad XML not found at {iliad_path}")

        # 2. Seed additional vocabulary
        await seed_additional_vocabulary(session)

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
