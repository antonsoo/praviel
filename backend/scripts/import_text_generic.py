#!/usr/bin/env python3
"""Generic text importer for loading canonical texts into database.

This script provides a flexible way to import texts from various sources
(plain text, JSON, CSV, etc.) into the database with proper normalization.

Usage:
    python import_text_generic.py --language lat --work-title "Aeneid" \\
        --author "Virgil" --file texts/vergil_aeneid.txt --format plain

Supported formats:
    - plain: Plain text with line numbers (e.g., "1.1 Arma virumque cano...")
    - json: JSON array of {ref, text} objects
    - csv: CSV with ref,text columns
    - xml-tei: TEI XML format (Perseus-style)

The script will:
1. Parse the input file
2. Normalize text (NFC Unicode, fold for search)
3. Create or update TextWork entry
4. Insert TextSegments with proper references
5. Handle duplicates gracefully
"""

import argparse
import asyncio
import csv
import json
import logging
import re
import sys
import unicodedata
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Dict, List, Tuple

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from app.core.config import settings
from app.db.models import Language, SourceDoc, TextSegment, TextWork

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


def normalize_text(text: str) -> Tuple[str, str, str]:
    """Normalize text to NFC, and create folded version for search.

    Returns:
        (text_raw, text_nfc, text_fold)
    """
    text_raw = text.strip()
    text_nfc = unicodedata.normalize("NFC", text_raw)
    # Folded: lowercase, remove accents for search
    text_fold = "".join(
        c for c in unicodedata.normalize("NFD", text_nfc.lower()) if not unicodedata.combining(c)
    )
    return text_raw, text_nfc, text_fold


def parse_plain_text(file_path: Path) -> List[Dict[str, str]]:
    """Parse plain text format with ref prefix.

    Expected format:
        1.1 First line of text
        1.2 Second line of text
        2.1 First line of book 2

    Returns list of {ref, text} dicts
    """
    segments = []
    with open(file_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith("#"):  # Skip empty lines and comments
                continue

            # Try to extract reference prefix (e.g., "1.1", "Il.1.1", "Gen.1.1")
            match = re.match(r"^([\w\.]+)\s+(.+)$", line)
            if match:
                ref, text = match.groups()
                segments.append({"ref": ref, "text": text})
            else:
                logger.warning(f"Line {line_num}: Could not parse reference, skipping: {line[:50]}...")

    logger.info(f"Parsed {len(segments)} segments from plain text")
    return segments


def parse_json(file_path: Path) -> List[Dict[str, str]]:
    """Parse JSON format.

    Expected format:
        [
            {"ref": "1.1", "text": "First line"},
            {"ref": "1.2", "text": "Second line"}
        ]
    """
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError("JSON must be an array of objects")

    segments = []
    for item in data:
        if "ref" in item and "text" in item:
            segments.append({"ref": item["ref"], "text": item["text"]})
        else:
            logger.warning(f"Skipping invalid JSON item: {item}")

    logger.info(f"Parsed {len(segments)} segments from JSON")
    return segments


def parse_csv(file_path: Path) -> List[Dict[str, str]]:
    """Parse CSV format with ref,text columns."""
    segments = []
    with open(file_path, "r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if "ref" in row and "text" in row:
                segments.append({"ref": row["ref"], "text": row["text"]})
            else:
                logger.warning(f"Skipping CSV row without ref/text: {row}")

    logger.info(f"Parsed {len(segments)} segments from CSV")
    return segments


def parse_xml_tei(file_path: Path) -> List[Dict[str, str]]:
    """Parse TEI XML format (basic support).

    Looks for div and p elements with n attributes for references.
    """
    tree = ET.parse(file_path)
    root = tree.getroot()
    ns = {"tei": "http://www.tei-c.org/ns/1.0"}

    segments = []

    # Find all elements with 'n' attribute (line numbers, sections, etc.)
    for elem in root.findall(".//*[@n]", ns):
        ref = elem.get("n")
        # Get text content, joining all text nodes
        text = "".join(elem.itertext()).strip()
        if text:
            segments.append({"ref": ref, "text": text})

    logger.info(f"Parsed {len(segments)} segments from TEI XML")
    return segments


async def import_texts(
    language_code: str,
    work_title: str,
    author: str,
    file_path: Path,
    format: str,
    work_abbr: str = None,
) -> None:
    """Import texts into database.

    Args:
        language_code: Language code (e.g., 'lat', 'grc-cls', 'san')
        work_title: Title of work (e.g., "Aeneid")
        author: Author name (e.g., "Virgil")
        file_path: Path to input file
        format: Input format (plain, json, csv, xml-tei)
        work_abbr: Optional work abbreviation (e.g., "Aen", "Il")
    """
    # Parse input file based on format
    if format == "plain":
        segments = parse_plain_text(file_path)
    elif format == "json":
        segments = parse_json(file_path)
    elif format == "csv":
        segments = parse_csv(file_path)
    elif format == "xml-tei":
        segments = parse_xml_tei(file_path)
    else:
        raise ValueError(f"Unknown format: {format}")

    if not segments:
        logger.error("No segments parsed from input file")
        return

    logger.info(f"Parsed {len(segments)} segments, connecting to database...")

    # Connect to database
    engine = create_async_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Find language
        result = await session.execute(select(Language).where(Language.code == language_code))
        language = result.scalar_one_or_none()

        if not language:
            logger.error(f"Language '{language_code}' not found in database")
            await engine.dispose()
            return

        logger.info(f"Found language: {language.name} ({language.code})")

        # Find or create source document
        source_slug = "user-import"
        result = await session.execute(select(SourceDoc).where(SourceDoc.slug == source_slug))
        source = result.scalar_one_or_none()

        if not source:
            source = SourceDoc(
                slug=source_slug,
                title="User Imported Texts",
                license={"name": "Public Domain", "url": ""},
                meta={"imported_via": "import_text_generic.py"},
            )
            session.add(source)
            await session.flush()
            logger.info(f"Created source: {source_slug}")
        else:
            logger.info(f"Using existing source: {source_slug} (ID: {source.id})")

        # Find or create work
        result = await session.execute(
            select(TextWork).where(
                TextWork.language_id == language.id,
                TextWork.title == work_title,
            )
        )
        work = result.scalar_one_or_none()

        if not work:
            work = TextWork(
                language_id=language.id,
                source_id=source.id,
                title=work_title,
                author=author,
                ref_scheme="custom",
            )
            session.add(work)
            await session.flush()
            logger.info(f"Created new work: {work_title} by {author}")
        else:
            logger.info(f"Using existing work: {work_title} (ID: {work.id})")

        # Insert segments
        inserted_count = 0
        skipped_count = 0

        for item in segments:
            ref = item["ref"]
            text = item["text"]

            # Check if segment already exists
            result = await session.execute(
                select(TextSegment).where(
                    TextSegment.work_id == work.id,
                    TextSegment.ref == ref,
                )
            )
            existing = result.scalar_one_or_none()

            if existing:
                skipped_count += 1
                continue

            # Normalize text
            text_raw, text_nfc, text_fold = normalize_text(text)

            # Create segment
            segment = TextSegment(
                work_id=work.id,
                ref=ref,
                text_raw=text_raw,
                text_nfc=text_nfc,
                text_fold=text_fold,
            )
            session.add(segment)
            inserted_count += 1

            # Commit in batches of 100
            if inserted_count % 100 == 0:
                await session.commit()
                logger.info(f"Inserted {inserted_count} segments...")

        # Final commit
        await session.commit()

        # Update work segment count
        work.num_segments = inserted_count + skipped_count
        await session.commit()

        logger.info("\nImport complete!")
        logger.info(f"  Inserted: {inserted_count} segments")
        logger.info(f"  Skipped (already exist): {skipped_count} segments")
        logger.info(f"  Total in work: {work.num_segments} segments")

    await engine.dispose()


def main():
    parser = argparse.ArgumentParser(
        description="Import canonical texts into database",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    # Import Latin text from plain text file
    python import_text_generic.py --language lat --work-title "Aeneid" \\
        --author "Virgil" --file texts/aeneid.txt --format plain

    # Import Sanskrit from JSON
    python import_text_generic.py --language san --work-title "Bhagavad Gita" \\
        --author "Vyasa" --file texts/gita.json --format json

    # Import Hebrew from CSV
    python import_text_generic.py --language hbo --work-title "Genesis" \\
        --author "Moses" --file texts/genesis.csv --format csv
        """,
    )

    parser.add_argument("--language", required=True, help="Language code (e.g., lat, grc-cls, san)")
    parser.add_argument("--work-title", required=True, help='Work title (e.g., "Aeneid")')
    parser.add_argument("--author", required=True, help='Author name (e.g., "Virgil")')
    parser.add_argument("--file", required=True, type=Path, help="Input file path")
    parser.add_argument(
        "--format", required=True, choices=["plain", "json", "csv", "xml-tei"], help="Input file format"
    )
    parser.add_argument("--work-abbr", help="Work abbreviation (optional)")

    args = parser.parse_args()

    # Validate input file exists
    if not args.file.exists():
        logger.error(f"Input file not found: {args.file}")
        sys.exit(1)

    # Run import
    asyncio.run(
        import_texts(
            language_code=args.language,
            work_title=args.work_title,
            author=args.author,
            file_path=args.file,
            format=args.format,
            work_abbr=args.work_abbr,
        )
    )


if __name__ == "__main__":
    main()
