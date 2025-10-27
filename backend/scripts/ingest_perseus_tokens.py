#!/usr/bin/env python
"""Ingest Perseus morphology tokens into the token table.

This script parses the canonical TEI XML files shipped in backend/data
and populates the token table with lemma + morphology information so the
reader's word-tap experience returns rich data.

Usage:
    python backend/scripts/ingest_perseus_tokens.py --work iliad odyssey
    python backend/scripts/ingest_perseus_tokens.py --work all
    python backend/scripts/ingest_perseus_tokens.py --dry-run
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Sequence

from sqlalchemy import delete, insert, select
from sqlalchemy.ext.asyncio import AsyncSession

# Ensure backend/ is on sys.path so we can import app.*
CURRENT_DIR = Path(__file__).resolve()
BACKEND_ROOT = CURRENT_DIR.parent.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.db.models import Language, SourceDoc, TextSegment, TextWork, Token  # noqa: E402
from app.db.session import SessionLocal  # noqa: E402
from app.ingestion.sources.perseus import (  # noqa: E402
    PerseusSegment,
    extract_book_line_segments,
    extract_stephanus_segments,
    read_tei,
)

DATA_DIR = BACKEND_ROOT / "data"


@dataclass(frozen=True)
class WorkConfig:
    key: str
    title: str
    author: str
    language_code: str
    ref_prefix: str
    tei_path: Path
    parser: str  # "book_line" | "stephanus"
    source_slug: str
    include_books: Sequence[str] | None = None


WORKS: dict[str, WorkConfig] = {
    "iliad": WorkConfig(
        key="iliad",
        title="Iliad",
        author="Homer",
        language_code="grc-cls",
        ref_prefix="Il",
        tei_path=DATA_DIR / "iliad_grc.xml",
        parser="book_line",
        source_slug="perseus-homer-iliad",
    ),
    "odyssey": WorkConfig(
        key="odyssey",
        title="Odyssey",
        author="Homer",
        language_code="grc-cls",
        ref_prefix="Od",
        tei_path=DATA_DIR / "odyssey_grc.xml",
        parser="book_line",
        source_slug="perseus-homer-odyssey",
    ),
    "apology": WorkConfig(
        key="apology",
        title="Apology",
        author="Plato",
        language_code="grc-cls",
        ref_prefix="Apol",
        tei_path=DATA_DIR / "plato_apology_grc.xml",
        parser="stephanus",
        source_slug="perseus-plato-apology",
    ),
    "symposium": WorkConfig(
        key="symposium",
        title="Symposium",
        author="Plato",
        language_code="grc-cls",
        ref_prefix="Symp",
        tei_path=DATA_DIR / "plato_symposium_grc.xml",
        parser="stephanus",
        source_slug="perseus-plato-symposium",
    ),
    "republic": WorkConfig(
        key="republic",
        title="Republic",
        author="Plato",
        language_code="grc-cls",
        ref_prefix="Rep",
        tei_path=DATA_DIR / "plato_republic_grc.xml",
        parser="stephanus",
        source_slug="perseus-plato-republic",
    ),
}


class IngestionError(RuntimeError):
    """Raised when ingestion prerequisites are missing."""


async def ingest_work(session: AsyncSession, config: WorkConfig, *, dry_run: bool = False) -> dict:
    """Ingest morphology tokens for a single work."""

    if not config.tei_path.exists():
        raise IngestionError(f"TEI file not found: {config.tei_path}")

    lang_id = await _resolve_language_id(session, config.language_code)
    work_id = await _resolve_work_id(session, lang_id, config.author, config.title, config.source_slug)

    segment_rows = await session.execute(
        select(TextSegment.id, TextSegment.ref, TextSegment.text_nfc).where(TextSegment.work_id == work_id)
    )
    rows = segment_rows.fetchall()
    if not rows:
        raise IngestionError(
            f"No text segments found for work '{config.title}' ({config.author}). "
            "Run backend/scripts/seed_perseus_content.py first."
        )

    by_ref: dict[str, tuple[int, str]] = {ref: (seg_id, text_nfc) for seg_id, ref, text_nfc in rows}
    by_text: dict[str, List[tuple[int, str]]] = {}
    for seg_id, ref, text_nfc in rows:
        by_text.setdefault(text_nfc, []).append((seg_id, ref))

    root = read_tei(config.tei_path)
    segments = list(_extract_segments(root, config))

    used_segment_ids: set[int] = set()
    unmatched_refs: List[str] = []

    segments_updated = 0
    tokens_inserted = 0

    for segment in segments:
        match = _match_segment(segment, by_ref, by_text, used_segment_ids)
        if not match:
            unmatched_refs.append(segment.ref)
            continue

        segment_id = match[0]
        used_segment_ids.add(segment_id)

        if not dry_run:
            await session.execute(delete(Token).where(Token.segment_id == segment_id))

        segments_updated += 1

        if not segment.tokens:
            continue

        batch = [
            {
                "segment_id": segment_id,
                "idx": idx,
                "surface": token.surface[:150],
                "surface_nfc": token.surface_nfc[:150],
                "surface_fold": token.surface_fold[:150],
                "lemma": (token.lemma[:150] if token.lemma else None),
                "lemma_fold": (token.lemma_fold[:150] if token.lemma_fold else None),
                "msd": token.msd or None,
            }
            for idx, token in enumerate(segment.tokens)
        ]

        if not dry_run and batch:
            await session.execute(insert(Token), batch)

        tokens_inserted += len(batch)

    if not dry_run:
        await session.commit()

    return {
        "work": config.key,
        "segments_considered": len(segments),
        "segments_updated": segments_updated,
        "tokens_inserted": tokens_inserted,
        "unmatched": unmatched_refs,
        "dry_run": dry_run,
    }


def _extract_segments(root, config: WorkConfig) -> Iterable[PerseusSegment]:
    if config.parser == "book_line":
        return extract_book_line_segments(root, config.ref_prefix, include_books=config.include_books)
    if config.parser == "stephanus":
        return extract_stephanus_segments(root, config.ref_prefix)
    raise IngestionError(f"Unknown parser mode: {config.parser}")


async def _resolve_language_id(session: AsyncSession, code: str) -> int:
    result = await session.execute(select(Language.id).where(Language.code == code))
    lang_id = result.scalar_one_or_none()
    if lang_id is None:
        raise IngestionError(f"Language with code '{code}' not found. Seed languages first.")
    return lang_id


async def _resolve_work_id(
    session: AsyncSession, language_id: int, author: str, title: str, source_slug: str | None = None
) -> int:
    stmt = (
        select(TextWork.id)
        .join(SourceDoc, SourceDoc.id == TextWork.source_id)
        .where(
            TextWork.language_id == language_id,
            TextWork.author == author,
            TextWork.title == title,
        )
    )
    if source_slug:
        stmt = stmt.where(SourceDoc.slug == source_slug)

    result = await session.execute(stmt)
    work_id = result.scalar_one_or_none()
    if work_id is None:
        raise IngestionError(
            f"TextWork not found for author='{author}', title='{title}'. "
            "Seed the base text segments before ingesting morphology."
        )
    return work_id


def _match_segment(
    segment: PerseusSegment,
    by_ref: dict[str, tuple[int, str]],
    by_text: dict[str, List[tuple[int, str]]],
    used_ids: set[int],
) -> tuple[int, str] | None:
    candidate = by_ref.get(segment.ref)
    if candidate and candidate[0] not in used_ids:
        return candidate

    candidates = by_text.get(segment.text_nfc)
    if not candidates:
        return None

    for seg_id, ref in candidates:
        if seg_id not in used_ids:
            return seg_id, ref
    return None


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ingest Perseus morphology tokens.")
    parser.add_argument(
        "--work",
        nargs="+",
        metavar="WORK",
        choices=["all", *sorted(WORKS.keys())],
        default=["iliad"],
        help="Which works to ingest (default: iliad). Use 'all' for every configured work.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Parse TEI and show the plan without modifying the database.",
    )
    return parser.parse_args()


async def _run(args: argparse.Namespace) -> None:
    selected = args.work
    if "all" in selected:
        configs = list(WORKS.values())
    else:
        configs = [WORKS[name] for name in selected]

    async with SessionLocal() as session:
        for config in configs:
            try:
                summary = await ingest_work(session, config, dry_run=args.dry_run)
            except IngestionError as exc:
                print(f"[{config.key}] ❌ {exc}")
                continue

            unmatched = summary["unmatched"]
            status_icon = "🔍" if args.dry_run else "✅"
            print(
                f"[{config.key}] {status_icon} segments={summary['segments_updated']}/"
                f"{summary['segments_considered']} tokens={summary['tokens_inserted']}"
                f"{' (dry-run)' if args.dry_run else ''}"
            )
            if unmatched:
                sample = ", ".join(unmatched[:5])
                suffix = "…" if len(unmatched) > 5 else ""
                print(f"    ⚠️  Unmatched segments ({len(unmatched)}): {sample}{suffix}")


def main() -> None:
    args = _parse_args()
    try:
        asyncio.run(_run(args))
    except KeyboardInterrupt:
        print("\nInterrupted by user.")


if __name__ == "__main__":
    main()
