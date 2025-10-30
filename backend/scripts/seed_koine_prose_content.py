"""
Seed Koine Greek prose texts from Perseus canonical-greekLit repository.

Handles Hellenistic/Roman period prose works:
- Josephus (historian)
- Plutarch (biographer)
- Strabo (geographer)
- Diodorus Siculus (historian)
- Lucian (satirist)
"""

import asyncio
import logging
import sys
import unicodedata
import xml.etree.ElementTree as ET
from io import StringIO
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.core.config import settings
from app.db.engine import create_asyncpg_engine
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


def parse_perseus_koine_prose_xml(xml_path: Path, work_abbr: str) -> list[dict]:
    """
    Parse Perseus TEI XML format for Koine Greek prose texts.

    Handles two common structures:
    - book.section (Josephus)
    - chapter.section (Plutarch, Lucian, Diodorus, Strabo)
    """
    # Handle XML entities by pre-processing the file
    try:
        tree = ET.parse(xml_path)
    except ET.ParseError as e:
        logger.warning(f"XML Parse Error in {xml_path}: {e}")
        # Read file and replace common entities
        with open(xml_path, "r", encoding="utf-8") as f:
            content = f.read()

        replacements = {
            "&dagger;": "†",
            "&mdash;": "—",
            "&ndash;": "–",
            "&ldquo;": '"',
            "&rdquo;": '"',
            "&nbsp;": " ",
            "&lsquo;": """, '&rsquo;': """,
            "&hellip;": "…",
        }
        for old, new in replacements.items():
            content = content.replace(old, new)

        tree = ET.parse(StringIO(content))

    root = tree.getroot()
    ns = {"tei": "http://www.tei-c.org/ns/1.0"}

    segments = []
    seen_refs = set()

    # Try book.section structure first (Josephus)
    book_divs = root.findall(".//tei:div[@type='textpart'][@subtype='book']", ns)

    if book_divs:
        # Book.Section structure
        for book_div in book_divs:
            book_n = book_div.get("n", "1")
            try:
                book_int = int(book_n)
            except (ValueError, TypeError):
                continue

            section_divs = book_div.findall(".//tei:div[@type='textpart'][@subtype='section']", ns)

            for section_div in section_divs:
                section_n = section_div.get("n", "0")
                try:
                    section_int = int(section_n)
                except (ValueError, TypeError):
                    continue

                # Extract text from all <p> tags
                paragraphs = section_div.findall(".//tei:p", ns)
                text_parts = []
                for p in paragraphs:
                    text = " ".join([t.strip() for t in p.itertext() if t.strip()])
                    if text:
                        text_parts.append(text)

                if text_parts:
                    full_text = " ".join(text_parts)
                    ref = f"{work_abbr}.{book_int}.{section_int}"

                    if ref not in seen_refs:
                        seen_refs.add(ref)
                        segments.append(
                            {"ref": ref, "book": book_int, "chapter": section_int, "text": full_text}
                        )
    else:
        # Chapter.Section structure (Plutarch, Lucian, Diodorus, Strabo)
        chapter_divs = root.findall(".//tei:div[@type='textpart'][@subtype='chapter']", ns)

        for chapter_div in chapter_divs:
            chapter_n = chapter_div.get("n", "1")
            try:
                chapter_int = int(chapter_n)
            except (ValueError, TypeError):
                continue

            section_divs = chapter_div.findall(".//tei:div[@type='textpart'][@subtype='section']", ns)

            for section_div in section_divs:
                section_n = section_div.get("n", "0")
                try:
                    section_int = int(section_n)
                except (ValueError, TypeError):
                    continue

                # Extract text from all <p> tags
                paragraphs = section_div.findall(".//tei:p", ns)
                text_parts = []
                for p in paragraphs:
                    text = " ".join([t.strip() for t in p.itertext() if t.strip()])
                    if text:
                        text_parts.append(text)

                if text_parts:
                    full_text = " ".join(text_parts)
                    ref = f"{work_abbr}.{chapter_int}.{section_int}"

                    if ref not in seen_refs:
                        seen_refs.add(ref)
                        segments.append(
                            {"ref": ref, "book": chapter_int, "chapter": section_int, "text": full_text}
                        )

        # If no chapters found, try section-only structure (Lucian dialogues)
        if not segments:
            section_divs = root.findall(".//tei:div[@type='textpart'][@subtype='section']", ns)

            for section_div in section_divs:
                section_n = section_div.get("n", "0")
                try:
                    section_int = int(section_n)
                except (ValueError, TypeError):
                    continue

                # Extract text from all <p> and <sp> tags (for dialogues)
                text_parts = []
                paragraphs = section_div.findall(".//tei:p", ns)
                for p in paragraphs:
                    text = " ".join([t.strip() for t in p.itertext() if t.strip()])
                    if text:
                        text_parts.append(text)

                if text_parts:
                    full_text = " ".join(text_parts)
                    # Use format: work.section (treating as single-book work)
                    ref = f"{work_abbr}.{section_int}"

                    if ref not in seen_refs:
                        seen_refs.add(ref)
                        segments.append({"ref": ref, "book": 1, "chapter": section_int, "text": full_text})

    logger.info(f"  Parsed {len(segments)} segments from {xml_path.name}")
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


async def seed_koine_work(
    session: AsyncSession,
    xml_path: Path,
    author: str,
    title: str,
    work_abbr: str,
    lang: Language,
    source: SourceDoc,
):
    """Seed a single Koine Greek work."""
    logger.info(f"Seeding {title} by {author}...")

    segments = parse_perseus_koine_prose_xml(xml_path, work_abbr)
    ref_scheme = "book.chapter"

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
            meta={"book": seg.get("book"), "chapter": seg.get("chapter")},
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
    logger.info("KOINE GREEK (PERSEUS) PROSE SEEDING")
    logger.info("=" * 60)

    engine = create_asyncpg_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        lang = await seed_language(session, "grc-koi", "Koine Greek")

        source = await seed_source_doc(
            session,
            slug="perseus-koine-texts",
            title="Perseus Digital Library - Koine Greek Texts",
            license_info={
                "name": "Creative Commons Attribution-ShareAlike 3.0",
                "url": "https://creativecommons.org/licenses/by-sa/3.0/",
            },
        )

        base_dir = Path(__file__).parent.parent / "data" / "canonical-greekLit" / "data"

        # Koine Greek prose works with TLG codes
        koine_works = [
            # (tlg_author, tlg_work, author, title, abbreviation)
            ("tlg0526", "tlg001", "Josephus", "Jewish Antiquities", "Ant"),
            ("tlg0526", "tlg004", "Josephus", "Jewish War", "War"),
            ("tlg0007", "tlg047", "Plutarch", "Alexander", "Alex"),
            ("tlg0007", "tlg012", "Plutarch", "Pericles", "Per"),
            ("tlg0007", "tlg048", "Plutarch", "Caesar", "Caes"),
            ("tlg0099", "tlg001", "Strabo", "Geography", "Geog"),
            ("tlg0060", "tlg001", "Diodorus Siculus", "Historical Library", "Diod"),
            ("tlg0062", "tlg001", "Lucian", "Phalaris", "Phal"),
            ("tlg0062", "tlg048", "Lucian", "Astrology", "Astr"),
        ]

        for tlg_author, tlg_work, author, title, abbr in koine_works:
            xml_path = base_dir / tlg_author / tlg_work / f"{tlg_author}.{tlg_work}.perseus-grc2.xml"

            if not xml_path.exists():
                # Try alternative editions
                for edition in ["grc1", "grc3", "grc4", "grc5", "grc6"]:
                    alt_path = (
                        base_dir / tlg_author / tlg_work / f"{tlg_author}.{tlg_work}.perseus-{edition}.xml"
                    )
                    if alt_path.exists():
                        xml_path = alt_path
                        break

            if xml_path.exists():
                try:
                    await seed_koine_work(session, xml_path, author, title, abbr, lang, source)
                except Exception as e:
                    logger.error(f"[X] Failed to seed {title}: {e}")
            else:
                logger.warning(f"[X] File not found for {title}: {xml_path}")

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("[OK] KOINE GREEK PROSE SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
