#!/usr/bin/env python3
"""Seed SBL Greek New Testament (SBLGNT) Koine Greek content into database.

This script parses the SBLGNT text files and inserts the Koine Greek
New Testament into the database with proper structure.
"""

import asyncio
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
    """Normalize text to NFC, and create folded version.

    Returns:
        (text_raw, text_nfc, text_fold)
    """
    text_raw = text.strip()
    text_nfc = unicodedata.normalize("NFC", text_raw)
    # Folded: lowercase, remove accents
    text_fold = "".join(
        c
        for c in unicodedata.normalize("NFD", text_nfc.lower())
        if not unicodedata.combining(c)
    )
    return text_raw, text_nfc, text_fold


def parse_sblgnt_book(txt_path: Path) -> tuple[str, list[dict]]:
    """Parse SBLGNT text file format.

    Format:
        Line 1: Book title (e.g., "ΚΑΤΑ ΜΑΘΘΑΙΟΝ")
        Following lines: Ref TAB Greek text (e.g., "Matt 1:1\tΒίβλος...")

    Args:
        txt_path: Path to text file (e.g., Matt.txt)

    Returns:
        tuple of (title, segments)
        title: Book title (e.g., "Matthew")
        segments: [{"ref": "Matt.1.1", "chapter": 1, "verse": 1, "text": "..."}]
    """
    with open(txt_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    if not lines:
        raise ValueError(f"Empty file: {txt_path}")

    # First line is the Greek title (we'll derive English title from filename)
    filename = txt_path.stem  # "Matt", "Mark", etc.

    segments = []
    for line in lines[1:]:  # Skip first line (title)
        line = line.strip()
        if not line or "\t" not in line:
            continue

        ref, text = line.split("\t", 1)
        text = text.strip()
        if not text:
            continue

        # Parse reference: "Matt 1:1" -> book="Matt", chapter=1, verse=1
        parts = ref.split()
        if len(parts) < 2:
            continue

        book_abbrev = parts[0]
        verse_ref = parts[1]  # "1:1"

        if ":" not in verse_ref:
            continue

        chapter_str, verse_str = verse_ref.split(":", 1)
        try:
            chapter = int(chapter_str)
            verse = int(verse_str)
        except ValueError:
            continue

        # Convert ref to standard format: Matt 1:1 -> Matt.1.1
        standard_ref = f"{book_abbrev}.{chapter}.{verse}"

        segments.append(
            {
                "ref": standard_ref,
                "chapter": chapter,
                "verse": verse,
                "text": text,
            }
        )

    logger.info(f"Parsed {len(segments)} verses from {filename}")
    return filename, segments


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
                "source": "SBL Greek New Testament",
                "url": "https://sblgnt.com/",
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


async def seed_nt_book(
    session: AsyncSession,
    txt_path: Path,
    author: str,
    title: str,
    lang: Language,
    source: SourceDoc,
):
    """Seed a single NT book."""
    logger.info(f"Seeding {title}...")

    filename, segments = parse_sblgnt_book(txt_path)

    work = await seed_text_work(
        session,
        language_id=lang.id,
        source_id=source.id,
        author=author,
        title=title,
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
        f"[OK] Seeded {new_count} new {title} segments "
        f"(skipped {len(segments) - new_count} existing)"
    )


async def main():
    """Main seeding function."""
    logger.info("=" * 60)
    logger.info("KOINE GREEK NEW TESTAMENT (SBLGNT) SEEDING")
    logger.info("=" * 60)

    engine = create_async_engine(settings.DATABASE_URL, echo=False)

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Create language and source
        lang = await seed_language(session, "grc-koi", "Koine Greek")

        source = await seed_source_doc(
            session,
            slug="sblgnt-new-testament",
            title="SBL Greek New Testament",
            license_info={
                "name": "Creative Commons Attribution 4.0 International",
                "url": "https://creativecommons.org/licenses/by/4.0/",
            },
        )

        data_dir = (
            Path(__file__).parent.parent
            / "data"
            / "SBLGNT"
            / "data"
            / "sblgnt"
            / "text"
        )

        # New Testament books
        nt_books = [
            ("Matt.txt", "Various", "Matthew"),
            ("Mark.txt", "Various", "Mark"),
            ("Luke.txt", "Various", "Luke"),
            ("John.txt", "Various", "John"),
            ("Acts.txt", "Various", "Acts"),
            ("Rom.txt", "Various", "Romans"),
            ("1Cor.txt", "Various", "1 Corinthians"),
            ("2Cor.txt", "Various", "2 Corinthians"),
            ("Gal.txt", "Various", "Galatians"),
            ("Eph.txt", "Various", "Ephesians"),
            ("Phil.txt", "Various", "Philippians"),
            ("Col.txt", "Various", "Colossians"),
            ("1Thess.txt", "Various", "1 Thessalonians"),
            ("2Thess.txt", "Various", "2 Thessalonians"),
            ("1Tim.txt", "Various", "1 Timothy"),
            ("2Tim.txt", "Various", "2 Timothy"),
            ("Titus.txt", "Various", "Titus"),
            ("Phlm.txt", "Various", "Philemon"),
            ("Heb.txt", "Various", "Hebrews"),
            ("Jas.txt", "Various", "James"),
            ("1Pet.txt", "Various", "1 Peter"),
            ("2Pet.txt", "Various", "2 Peter"),
            ("1John.txt", "Various", "1 John"),
            ("2John.txt", "Various", "2 John"),
            ("3John.txt", "Various", "3 John"),
            ("Jude.txt", "Various", "Jude"),
            ("Rev.txt", "Various", "Revelation"),
        ]

        for filename, author, title in nt_books:
            txt_path = data_dir / filename
            if txt_path.exists():
                await seed_nt_book(session, txt_path, author, title, lang, source)
            else:
                logger.warning(f"[X] File not found: {txt_path}")

    await engine.dispose()

    logger.info("=" * 60)
    logger.info("[OK] KOINE GREEK NEW TESTAMENT SEEDING COMPLETE")
    logger.info("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
