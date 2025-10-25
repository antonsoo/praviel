#!/usr/bin/env python3
"""Seed Perseus Digital Library Classical Latin content into database.

This script parses Perseus TEI XML files and inserts Latin texts
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
    """Normalize text to NFC, and create folded version."""
    text_raw = text.strip()
    text_nfc = unicodedata.normalize("NFC", text_raw)
    text_fold = "".join(
        c
        for c in unicodedata.normalize("NFD", text_nfc.lower())
        if not unicodedata.combining(c)
    )
    return text_raw, text_nfc, text_fold


def parse_perseus_latin_xml(xml_path: Path, work_abbr: str) -> list[dict]:
    """Parse Perseus TEI XML format for Latin texts - comprehensive parser.

    Handles multiple TEI structures:
    - book.line (poetry in books: Virgil, Ovid)
    - book.chapter.section (prose in books: Caesar, Livy)
    - speech.section (orations: Cicero)
    - poem.line (standalone poems: Catullus)

    Args:
        xml_path: Path to XML file
        work_abbr: Work abbreviation (e.g., "Aen", "Phil")

    Returns list of segments with structure:
        {"ref": "Aen.1.1", "book": 1, "line": 1, "text": "..."}
    """
    # Handle XML entities by pre-processing the file
    try:
        tree = ET.parse(xml_path)
    except ET.ParseError as e:
        logger.warning(f"XML Parse Error in {xml_path}: {e}")
        logger.warning("Attempting to parse with entity replacement...")

        # Read file and replace entities
        with open(xml_path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Replace problematic HTML/Unicode entities
        replacements = {
            '&dagger;': '†', '&mdash;': '—', '&ndash;': '–',
            '&ldquo;': '"', '&rdquo;': '"', '&lsquo;': "'", '&rsquo;': "'",
            '&nbsp;': ' ', '&hellip;': '…', '&middot;': '·',
            '&sect;': '§', '&para;': '¶', '&deg;': '°',
            '&prime;': '′', '&Prime;': '″', '&times;': '×', '&divide;': '÷',
        }

        for old, new in replacements.items():
            content = content.replace(old, new)

        from io import StringIO
        tree = ET.parse(StringIO(content))

    root = tree.getroot()
    ns = {"tei": "http://www.tei-c.org/ns/1.0"}
    segments = []
    seen_refs = set()

    # Strategy: Try different structures in order of specificity

    # 1. Try SPEECH.SECTION format (Cicero orations)
    speech_divs = root.findall(".//tei:div[@type='textpart'][@subtype='speech']", ns)
    if speech_divs:
        for speech_div in speech_divs:
            speech_n = speech_div.get("n")
            if not speech_n:
                continue
            try:
                speech_int = int(speech_n)
            except ValueError:
                continue

            # Find sections within this speech
            for section_div in speech_div.findall(".//tei:div[@subtype='section']", ns):
                section_n = section_div.get("n")
                if not section_n:
                    continue
                try:
                    section_int = int(section_n)
                except ValueError:
                    continue

                # Extract text from <p> tags
                text_parts = []
                for p in section_div.findall(".//tei:p", ns):
                    for text in p.itertext():
                        cleaned = text.strip()
                        if cleaned:
                            text_parts.append(cleaned)

                text = " ".join(text_parts)
                if not text:
                    continue

                ref = f"{work_abbr}.{speech_int}.{section_int}"
                if ref not in seen_refs:
                    seen_refs.add(ref)
                    segments.append({
                        "ref": ref,
                        "book": speech_int,
                        "line": section_int,
                        "text": text,
                    })

    # 2. Try POEM.LINE format (Catullus)
    if not segments:
        poem_divs = root.findall(".//tei:div[@type='textpart'][@subtype='poem']", ns)
        if poem_divs:
            for poem_div in poem_divs:
                poem_n = poem_div.get("n")
                if not poem_n:
                    continue
                try:
                    poem_int = int(poem_n)
                except ValueError:
                    continue

                # Find lines within this poem
                for line_elem in poem_div.findall(".//tei:l", ns):
                    line_n = line_elem.get("n")
                    if not line_n:
                        continue
                    try:
                        line_int = int(line_n)
                    except ValueError:
                        continue

                    text_parts = []
                    for text in line_elem.itertext():
                        cleaned = text.strip()
                        if cleaned:
                            text_parts.append(cleaned)

                    text = " ".join(text_parts)
                    if not text:
                        continue

                    ref = f"{work_abbr}.{poem_int}.{line_int}"
                    if ref not in seen_refs:
                        seen_refs.add(ref)
                        segments.append({
                            "ref": ref,
                            "book": poem_int,
                            "line": line_int,
                            "text": text,
                        })

    # 3. Try CHAPTER with MILESTONE SECTIONS (Sallust)
    if not segments:
        chapter_divs = root.findall(".//tei:div[@type='textpart'][@subtype='chapter']", ns)
        if chapter_divs:
            for chapter_div in chapter_divs:
                chapter_n = chapter_div.get("n")
                if not chapter_n:
                    continue
                try:
                    chapter_int = int(chapter_n)
                except ValueError:
                    continue

                # Find all paragraphs and milestone sections within chapter
                paragraphs = chapter_div.findall(".//tei:p", ns)
                current_section = None
                text_parts = []

                for p in paragraphs:
                    # Process this paragraph's content with milestones
                    for elem in p.iter():
                        if elem.tag == f"{{{ns['tei']}}}milestone" and elem.get("unit") == "section":
                            # Save previous section if we have content
                            if current_section is not None and text_parts:
                                text = " ".join(text_parts)
                                ref = f"{work_abbr}.{chapter_int}.{current_section}"
                                if ref not in seen_refs:
                                    seen_refs.add(ref)
                                    segments.append({
                                        "ref": ref,
                                        "book": chapter_int,
                                        "line": current_section,
                                        "text": text,
                                    })

                            # Start new section
                            section_n = elem.get("n")
                            if section_n:
                                try:
                                    current_section = int(section_n)
                                    text_parts = []
                                except ValueError:
                                    pass
                        elif elem.text and elem.text.strip():
                            if current_section is not None:
                                text_parts.append(elem.text.strip())
                        if elem.tail and elem.tail.strip():
                            if current_section is not None:
                                text_parts.append(elem.tail.strip())

                # Save last section
                if current_section is not None and text_parts:
                    text = " ".join(text_parts)
                    ref = f"{work_abbr}.{chapter_int}.{current_section}"
                    if ref not in seen_refs:
                        seen_refs.add(ref)
                        segments.append({
                            "ref": ref,
                            "book": chapter_int,
                            "line": current_section,
                            "text": text,
                        })

    # 4. Try BOOK.LINE or BOOK.CHAPTER.SECTION format (traditional)
    if not segments:
        book_divs = root.findall(".//tei:div[@type='textpart'][@subtype='book']", ns)
        for book_div in book_divs:
            book_n = book_div.get("n")
            if not book_n:
                continue
            try:
                book_int = int(book_n)
            except ValueError:
                continue

            # Try poetry format first (lines)
            lines = book_div.findall(".//tei:l", ns)
            if lines:
                # Poetry format: Book.Line
                for line_elem in lines:
                    line_n = line_elem.get("n")
                    if not line_n:
                        continue
                    try:
                        line_int = int(line_n)
                    except ValueError:
                        continue

                    text_parts = []
                    for text in line_elem.itertext():
                        cleaned = text.strip()
                        if cleaned:
                            text_parts.append(cleaned)

                    text = " ".join(text_parts)
                    if not text:
                        continue

                    ref = f"{work_abbr}.{book_int}.{line_int}"
                    if ref not in seen_refs:
                        seen_refs.add(ref)
                        segments.append({
                            "ref": ref,
                            "book": book_int,
                            "line": line_int,
                            "text": text,
                        })
            else:
                # Prose format: Book.Chapter.Section
                for chapter_div in book_div.findall(".//tei:div[@subtype='chapter']", ns):
                    chapter_n = chapter_div.get("n")
                    if not chapter_n:
                        continue
                    try:
                        chapter_int = int(chapter_n)
                    except ValueError:
                        continue

                    for section_div in chapter_div.findall(".//tei:div[@subtype='section']", ns):
                        section_n = section_div.get("n")
                        if not section_n:
                            continue
                        try:
                            section_int = int(section_n)
                        except ValueError:
                            continue

                        text_parts = []
                        for p in section_div.findall(".//tei:p", ns):
                            for text in p.itertext():
                                cleaned = text.strip()
                                if cleaned:
                                    text_parts.append(cleaned)

                        text = " ".join(text_parts)
                        if not text:
                            continue

                        ref = f"{work_abbr}.{book_int}.{chapter_int}.{section_int}"
                        if ref not in seen_refs:
                            seen_refs.add(ref)
                            segments.append({
                                "ref": ref,
                                "book": book_int,
                                "line": chapter_int,
                                "text": text,
                            })

    logger.info(f"Parsed {len(segments)} segments from {work_abbr} XML")
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
                "source": "Perseus Digital Library",
                "url": "https://github.com/PerseusDL/canonical-latinLit",
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


async def seed_latin_work(
    session: AsyncSession,
    xml_path: Path,
    author: str,
    title: str,
    work_abbr: str,
    lang: Language,
    source: SourceDoc,
):
    """Seed a single Latin work."""
    logger.info(f"Seeding {title} by {author}...")

    segments = parse_perseus_latin_xml(xml_path, work_abbr)

    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author=author,
        title=title,
        ref_scheme="book.line",
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
            meta={"book": seg["book"], "line": seg["line"]},
        )
        session.add(segment)
        new_count += 1

    await session.commit()
    logger.info(
        f"[OK] Seeded {new_count} new {title} segments "
        f"(skipped {len(segments) - new_count} existing)"
    )


async def main():
    """Main seeding function."""
    logger.info("=" * 60)
    logger.info("CLASSICAL LATIN (PERSEUS) SEEDING - TOP 10 WORKS")
    logger.info("=" * 60)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Create language and source
        lang = await seed_language(session, "lat", "Classical Latin")

        source = await seed_source_doc(
            session,
            slug="perseus-latin-texts",
            title="Perseus Digital Library - Classical Latin Texts",
            license_info={
                "name": "Creative Commons Attribution-ShareAlike 3.0",
                "url": "https://creativecommons.org/licenses/by-sa/3.0/",
            },
        )

        base_dir = (
            Path(__file__).parent.parent
            / "data"
            / "canonical-latinLit"
            / "data"
        )

        # Top 10 Latin works with their PHI codes
        latin_works = [
            # (phi_author_code, phi_work_code, author, title, abbreviation)
            ("phi0690", "phi003", "Virgil", "Aeneid", "Aen"),
            ("phi0959", "phi006", "Ovid", "Metamorphoses", "Met"),
            ("phi0550", "phi001", "Lucretius", "De Rerum Natura", "Lucr"),
            ("phi0448", "phi001", "Julius Caesar", "Commentaries on the Gallic War", "Gall"),
            ("phi1351", "phi005", "Tacitus", "Annals", "Ann"),
            ("phi0914", "phi001", "Livy", "Ab Urbe Condita", "Liv"),
            ("phi0893", "phi004", "Horace", "Odes", "Carm"),
            ("phi0978", "phi001", "Pliny the Elder", "Naturalis Historia", "Nat"),
            ("phi1276", "phi001", "Juvenal", "Satires", "Sat"),
            ("phi0474", "phi035", "Cicero", "Philippicae", "Phil"),
            ("phi0631", "phi001", "Sallust", "Catilinae Coniuratio", "Cat"),
            ("phi0472", "phi001", "Catullus", "Carmina", "Catull"),
        ]

        for phi_author, phi_work, author, title, abbr in latin_works:
            # Try different Perseus editions in order of preference
            xml_path = None
            for edition in ['lat2', 'lat1', 'lat3', 'lat4', 'lat5', 'lat6']:
                candidate = base_dir / phi_author / phi_work / f"{phi_author}.{phi_work}.perseus-{edition}.xml"
                if candidate.exists():
                    xml_path = candidate
                    break

            if xml_path and xml_path.exists():
                await seed_latin_work(session, xml_path, author, title, abbr, lang, source)
            else:
                logger.warning(f"[X] File not found for {author} - {title}")
                logger.warning(f"    Checked: {phi_author}/{phi_work}/phi*.perseus-lat*.xml")

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("[OK] CLASSICAL LATIN SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
