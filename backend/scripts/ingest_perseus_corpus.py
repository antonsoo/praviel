#!/usr/bin/env python3
"""Ingest complete Perseus corpus into the database.

This script scans the Perseus Digital Library corpus downloaded from GitHub
and populates the database with complete texts (not just placeholder snippets).

Usage:
    python backend/scripts/ingest_perseus_corpus.py
    python backend/scripts/ingest_perseus_corpus.py --limit 10
    python backend/scripts/ingest_perseus_corpus.py --language greek
    python backend/scripts/ingest_perseus_corpus.py --dry-run
"""

from __future__ import annotations

import argparse
import asyncio
import logging
import sys
from pathlib import Path
from typing import Dict, List, Tuple

from lxml import etree
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker

# Ensure backend/ is on sys.path
CURRENT_DIR = Path(__file__).resolve()
BACKEND_ROOT = CURRENT_DIR.parent.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.core.config import settings
from app.db.engine import create_asyncpg_engine
from app.db.models import Language, SourceDoc, TextSegment, TextWork, Token
from app.ingestion.sources.perseus import (
    PerseusSegment,
    extract_book_line_segments,
    extract_stephanus_segments,
    read_tei,
)

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

# Paths to Perseus corpus
PERSEUS_DIR = BACKEND_ROOT.parent / "data" / "vendor" / "perseus"
GREEK_LIT_DIR = PERSEUS_DIR / "canonical-greekLit" / "data"
LATIN_LIT_DIR = PERSEUS_DIR / "canonical-latinLit" / "data"

# TEI namespace
NS = {
    "tei": "http://www.tei-c.org/ns/1.0",
    "ti": "http://chs.harvard.edu/xmlns/cts",
    "xml": "http://www.w3.org/XML/1998/namespace"
}


def find_perseus_texts(corpus_dir: Path, language_code: str) -> List[Tuple[Path, Path]]:
    """Find all Greek or Latin TEI XML files in Perseus corpus.

    Returns:
        List of tuples: (cts_xml_path, tei_xml_path)
    """
    texts = []

    if not corpus_dir.exists():
        logger.warning(f"Corpus directory not found: {corpus_dir}")
        return texts

    # Find all __cts__.xml files
    for author_dir in corpus_dir.iterdir():
        if not author_dir.is_dir() or author_dir.name.startswith("."):
            continue

        for work_dir in author_dir.iterdir():
            if not work_dir.is_dir() or work_dir.name.startswith("."):
                continue

            cts_file = work_dir / "__cts__.xml"
            if not cts_file.exists():
                continue

            # Find the corresponding TEI XML file
            lang_suffix = "grc" if language_code.startswith("grc") else "lat"
            tei_files = list(work_dir.glob(f"*.perseus-{lang_suffix}*.xml"))

            if tei_files:
                texts.append((cts_file, tei_files[0]))

    return texts


def parse_cts_metadata(cts_path: Path) -> Dict[str, str] | None:
    """Parse CTS metadata file to extract author and title."""
    try:
        tree = etree.parse(str(cts_path))
        root = tree.getroot()

        # Extract title from the work element
        title_el = root.find(".//ti:title[@xml:lang='eng']", namespaces=NS)
        if title_el is None:
            title_el = root.find(".//ti:label[@xml:lang='eng']", namespaces=NS)

        if title_el is None or not title_el.text:
            return None

        title = title_el.text.strip()

        # Try to get author from parent directory
        # The directory structure is: data/tlg0012/tlg001/__cts__.xml
        # where tlg0012 is the author ID
        author = None

        return {"title": title, "author": author}
    except Exception as e:
        logger.warning(f"Failed to parse CTS metadata from {cts_path}: {e}")
        return None


def parse_tei_metadata(tei_path: Path) -> Dict[str, str] | None:
    """Parse TEI XML file to extract author and title from header."""
    try:
        root = read_tei(tei_path)

        # Extract author
        author_el = root.find(".//tei:author", namespaces=NS)
        author = author_el.text.strip() if author_el is not None and author_el.text else "Unknown"

        # Extract title (prefer Greek/Latin title)
        title_el = root.find(".//tei:titleStmt/tei:title[@xml:lang='grc']", namespaces=NS)
        if title_el is None:
            title_el = root.find(".//tei:titleStmt/tei:title[@xml:lang='lat']", namespaces=NS)
        if title_el is None:
            title_el = root.find(".//tei:titleStmt/tei:title", namespaces=NS)

        title = title_el.text.strip() if title_el is not None and title_el.text else "Unknown"

        return {"author": author, "title": title}
    except Exception as e:
        logger.warning(f"Failed to parse TEI metadata from {tei_path}: {e}")
        return None


def detect_structure_type(root: etree._Element) -> str:
    """Detect the citation structure of the text (book.line, stephanus, etc.)."""
    # Check for Stephanus pagination (Plato)
    stephanus_milestones = root.xpath(
        ".//tei:milestone[@unit='section'][@resp='Stephanus']",
        namespaces=NS
    )
    if stephanus_milestones:
        return "stephanus"

    # Check for book/line structure (Homer, epic poetry)
    book_divs = root.xpath(
        ".//tei:div[@type='textpart'][@subtype='Book' or @subtype='book']",
        namespaces=NS
    )
    if book_divs:
        lines = root.xpath(".//tei:l", namespaces=NS)
        if lines:
            return "book.line"

    # Check for chapter structure
    chapter_divs = root.xpath(
        ".//tei:div[@type='textpart'][@subtype='chapter' or @subtype='Chapter']",
        namespaces=NS
    )
    if chapter_divs:
        return "book.chapter"

    # Default to generic structure
    return "generic"


def extract_all_segments(root: etree._Element, ref_prefix: str, structure_type: str) -> List[PerseusSegment]:
    """Extract all segments from a TEI document based on its structure."""
    segments = []

    if structure_type == "stephanus":
        segments = list(extract_stephanus_segments(root, ref_prefix))
    elif structure_type == "book.line":
        # Extract all books (not just book 1)
        segments = list(extract_book_line_segments(root, ref_prefix, include_books=None))
    else:
        # For generic structure, try to extract any segments we can find
        # This is a fallback for texts that don't fit the above patterns
        segments = list(extract_generic_segments(root, ref_prefix))

    return segments


def extract_generic_segments(root: etree._Element, ref_prefix: str) -> List[PerseusSegment]:
    """Extract segments from texts with generic structure."""
    from app.ingestion.sources.perseus import _build_segment, _collect_text_parts, _collect_tokens

    segments = []

    # Try to find any <p> or <l> elements with numbering
    for idx, elem in enumerate(root.xpath(".//tei:p | .//tei:l", namespaces=NS), start=1):
        n = elem.get("n") or str(idx)
        text_parts = _collect_text_parts(elem.itertext())

        if not text_parts:
            continue

        tokens = _collect_tokens(elem)
        segment = _build_segment(
            ref=f"{ref_prefix}.{n}",
            text_parts=text_parts,
            tokens=tokens,
            meta={"section": n}
        )

        if segment:
            segments.append(segment)

    return segments


async def ingest_text(
    async_session_maker: sessionmaker,
    tei_path: Path,
    language_code: str,
    source_doc_id: int,
    dry_run: bool = False
) -> Dict[str, any]:
    """Ingest a single text into the database using its own session."""

    # Parse metadata and TEI outside of database session
    metadata = parse_tei_metadata(tei_path)
    if not metadata:
        return {"error": "Failed to parse metadata"}

    author = metadata["author"]
    title = metadata["title"]

    # Parse TEI
    root = read_tei(tei_path)
    structure_type = detect_structure_type(root)

    # Generate a short reference prefix (e.g., "Il" for Iliad)
    ref_prefix = "".join(word[0] for word in title.split()[:2])[:4]

    # Extract all segments
    segments = extract_all_segments(root, ref_prefix, structure_type)

    if not segments:
        return {"error": "No segments extracted"}

    if dry_run:
        return {
            "author": author,
            "title": title,
            "structure": structure_type,
            "segments_count": len(segments),
            "dry_run": True
        }

    # Create a new session for this text ingestion
    async with async_session_maker() as session:
        try:
            # Get language
            lang_result = await session.execute(
                select(Language).where(Language.code == language_code)
            )
            language = lang_result.scalar_one_or_none()

            if not language:
                return {"error": f"Language {language_code} not found"}

            # Check if work already exists
            work_result = await session.execute(
                select(TextWork).where(
                    TextWork.language_id == language.id,
                    TextWork.author == author,
                    TextWork.title == title
                )
            )
            work = work_result.scalar_one_or_none()

            if work:
                # Delete existing segments and tokens for this work
                await session.execute(
                    TextSegment.__table__.delete().where(TextSegment.work_id == work.id)
                )
                logger.info(f"  Replacing existing work: {author} - {title}")
            else:
                # Create new work
                work = TextWork(
                    language_id=language.id,
                    source_id=source_doc_id,
                    author=author,
                    title=title,
                    ref_scheme=structure_type
                )
                session.add(work)
                await session.flush()

            # Insert segments and tokens
            tokens_count = 0
            for segment in segments:
                seg = TextSegment(
                    work_id=work.id,
                    ref=segment.ref,
                    text_raw=segment.text_raw[:1000],  # Truncate if too long
                    text_nfc=segment.text_nfc[:1000],
                    text_fold=segment.text_fold[:1000],
                    meta=segment.meta
                )
                session.add(seg)
                await session.flush()

                # Insert tokens if available
                for idx, token in enumerate(segment.tokens):
                    tok = Token(
                        segment_id=seg.id,
                        idx=idx,
                        surface=token.surface[:150],
                        surface_nfc=token.surface_nfc[:150],
                        surface_fold=token.surface_fold[:150],
                        lemma=token.lemma[:150] if token.lemma else None,
                        lemma_fold=token.lemma_fold[:150] if token.lemma_fold else None,
                        msd=token.msd or None
                    )
                    session.add(tok)
                    tokens_count += 1

            await session.commit()

            return {
                "author": author,
                "title": title,
                "structure": structure_type,
                "segments_count": len(segments),
                "tokens_count": tokens_count
            }
        except Exception as e:
            # Session will be automatically rolled back when exiting the context
            await session.rollback()
            return {"error": str(e)}


async def main(args: argparse.Namespace) -> None:
    """Main entry point."""

    # Create database engine
    engine = create_asyncpg_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Get or create Perseus source document
        source_result = await session.execute(
            select(SourceDoc).where(SourceDoc.slug == "perseus-digital-library")
        )
        source_doc = source_result.scalar_one_or_none()

        if not source_doc:
            source_doc = SourceDoc(
                slug="perseus-digital-library",
                title="Perseus Digital Library",
                license={
                    "name": "CC-BY-SA-4.0",
                    "url": "https://creativecommons.org/licenses/by-sa/4.0/"
                },
                meta={
                    "url": "https://github.com/PerseusDL",
                    "description": "Classical Greek and Latin texts from Perseus Digital Library"
                }
            )
            session.add(source_doc)
            await session.commit()

        # Determine which languages to process
        languages = []
        if args.language == "all" or args.language == "greek":
            languages.append(("grc-cls", GREEK_LIT_DIR))
        if args.language == "all" or args.language == "latin":
            languages.append(("lat", LATIN_LIT_DIR))

        # Process each language
        total_ingested = 0
        total_failed = 0

        for language_code, corpus_dir in languages:
            logger.info(f"\n{'='*60}")
            logger.info(f"Processing {language_code} texts from {corpus_dir}")
            logger.info(f"{'='*60}\n")

            texts = find_perseus_texts(corpus_dir, language_code)

            if args.limit:
                texts = texts[:args.limit]

            logger.info(f"Found {len(texts)} texts to process\n")

            for idx, (cts_path, tei_path) in enumerate(texts, start=1):
                try:
                    result = await ingest_text(
                        async_session,
                        tei_path,
                        language_code,
                        source_doc.id,
                        dry_run=args.dry_run
                    )

                    if "error" in result:
                        logger.warning(f"[{idx}/{len(texts)}] ❌ {tei_path.name}: {result['error']}")
                        total_failed += 1
                    else:
                        status = "🔍" if args.dry_run else "✅"
                        logger.info(
                            f"[{idx}/{len(texts)}] {status} {result['author']} - {result['title']} "
                            f"({result['structure']}, {result['segments_count']} segments, "
                            f"{result.get('tokens_count', 0)} tokens)"
                        )
                        total_ingested += 1

                except Exception as e:
                    logger.error(f"[{idx}/{len(texts)}] ❌ {tei_path.name}: {e}")
                    total_failed += 1

        logger.info(f"\n{'='*60}")
        logger.info(f"Ingestion complete!")
        logger.info(f"  Ingested: {total_ingested}")
        logger.info(f"  Failed: {total_failed}")
        if args.dry_run:
            logger.info(f"  (DRY RUN - no changes made)")
        logger.info(f"{'='*60}\n")

    await engine.dispose()


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Ingest Perseus Digital Library corpus into database"
    )
    parser.add_argument(
        "--language",
        choices=["all", "greek", "latin"],
        default="all",
        help="Which language corpus to ingest (default: all)"
    )
    parser.add_argument(
        "--limit",
        type=int,
        help="Limit number of texts to process (for testing)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse and analyze without modifying database"
    )
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    try:
        asyncio.run(main(args))
    except KeyboardInterrupt:
        print("\n\nInterrupted by user.")
