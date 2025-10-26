#!/usr/bin/env python
"""Ingest morphology data from Perseus UD and PROIEL treebanks.

This script reads CoNLL-U formatted treebank data and populates the token table
with lemma and morphology information for the word-tap feature.

Usage:
    python backend/scripts/ingest_treebank_tokens.py --source perseus
    python backend/scripts/ingest_treebank_tokens.py --source proiel
    python backend/scripts/ingest_treebank_tokens.py --source all
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path
from typing import List

from sqlalchemy import delete, insert, select
from sqlalchemy.ext.asyncio import AsyncSession

# Ensure backend/ is on sys.path
CURRENT_DIR = Path(__file__).resolve()
BACKEND_ROOT = CURRENT_DIR.parent.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from app.db.models import Language, SourceDoc, TextSegment, TextWork, Token  # noqa: E402
from app.db.session import SessionLocal  # noqa: E402
from app.ingestion.normalize import accent_fold, nfc  # noqa: E402

DATA_DIR = BACKEND_ROOT / "data"


def parse_conllu(file_path: Path) -> List[List[dict]]:
    """Parse CoNLL-U file and return list of sentences (each sentence is a list of token dicts)."""
    sentences = []
    current_sentence = []
    current_text = None

    with open(file_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.rstrip()

            if not line:
                # End of sentence
                if current_sentence:
                    sentences.append({"text": current_text, "tokens": current_sentence})
                    current_sentence = []
                    current_text = None
                continue

            if line.startswith("#"):
                # Comment/metadata
                if line.startswith("# text = "):
                    current_text = line[9:].strip()
                continue

            # Parse token line
            parts = line.split("\t")
            if len(parts) < 6:
                continue

            token_id = parts[0]
            # Skip multi-word tokens (e.g., "1-2")
            if "-" in token_id or "." in token_id:
                continue

            surface = parts[1]
            lemma = parts[2]
            pos = parts[3]
            morph_tag = parts[4] if len(parts) > 4 else None
            features = parts[5] if len(parts) > 5 else None

            current_sentence.append(
                {
                    "surface": surface,
                    "lemma": lemma,
                    "pos": pos,
                    "morph_tag": morph_tag,
                    "features": features,
                }
            )

    # Don't forget the last sentence
    if current_sentence:
        sentences.append({"text": current_text, "tokens": current_sentence})

    return sentences


async def ingest_perseus_ud(session: AsyncSession) -> dict:
    """Ingest Perseus UD Ancient Greek treebank."""
    train_file = DATA_DIR / "UD_Ancient_Greek-Perseus" / "grc_perseus-ud-train.conllu"

    if not train_file.exists():
        raise FileNotFoundError(f"Perseus UD train file not found: {train_file}")

    print(f"Parsing {train_file}...")
    sentences = parse_conllu(train_file)
    print(f"Found {len(sentences)} sentences")

    # Get or create language
    lang_id = await _get_language_id(session, "grc-cls")

    # Get or create source and work
    work_id = await _get_or_create_treebank_work(
        session, lang_id, "Perseus UD Treebank", "Various Authors", "perseus-ud-reference"
    )

    # Clear existing tokens for this work
    await session.execute(
        delete(Token).where(
            Token.segment_id.in_(select(TextSegment.id).where(TextSegment.work_id == work_id))
        )
    )

    # Clear existing segments for this work
    await session.execute(delete(TextSegment).where(TextSegment.work_id == work_id))
    await session.flush()

    # Insert segments and tokens
    tokens_inserted = 0
    for idx, sentence_data in enumerate(sentences):
        text = sentence_data.get("text") or " ".join(t["surface"] for t in sentence_data["tokens"])

        # Create segment
        text_normalized = nfc(text)
        segment = TextSegment(
            work_id=work_id,
            ref=f"UD.{idx + 1}",
            text_raw=text,
            text_nfc=text_normalized,
            text_fold=accent_fold(text_normalized),
        )
        session.add(segment)
        await session.flush()  # Get segment ID

        # Insert tokens
        for token_idx, token_data in enumerate(sentence_data["tokens"]):
            surface = token_data["surface"]
            lemma = token_data["lemma"]
            morph_tag = token_data.get("morph_tag")
            features = token_data.get("features")

            # Store morphology in msd field as JSONB
            msd = {}
            if morph_tag and morph_tag != "_":
                msd["perseus_tag"] = morph_tag
            if features and features != "_":
                msd["features"] = features

            token = Token(
                segment_id=segment.id,
                idx=token_idx,
                surface=surface[:150],
                surface_nfc=nfc(surface)[:150],
                surface_fold=accent_fold(surface)[:150],
                lemma=lemma[:150] if lemma and lemma != "_" else None,
                lemma_fold=accent_fold(lemma)[:150] if lemma and lemma != "_" else None,
                msd=msd if msd else None,
            )
            session.add(token)
            tokens_inserted += 1

        if (idx + 1) % 1000 == 0:
            print(f"Processed {idx + 1} sentences, {tokens_inserted} tokens...")
            await session.commit()

    await session.commit()
    return {"source": "perseus-ud", "sentences": len(sentences), "tokens": tokens_inserted}


async def ingest_proiel(session: AsyncSession) -> dict:
    """Ingest PROIEL Greek NT and Herodotus treebanks."""
    nt_file = DATA_DIR / "proiel-treebank" / "greek-nt.conll"
    hdt_file = DATA_DIR / "proiel-treebank" / "hdt.conll"

    results = []
    for file_path, title in [(nt_file, "Greek New Testament"), (hdt_file, "Herodotus")]:
        if not file_path.exists():
            print(f"Warning: {file_path} not found, skipping")
            continue

        print(f"\nParsing {file_path}...")
        sentences = parse_conllu(file_path)
        print(f"Found {len(sentences)} sentences")

        # Get or create language
        lang_id = await _get_language_id(session, "grc-cls")

        # Get or create work
        slug = "proiel-nt" if "nt" in file_path.name else "proiel-hdt"
        work_id = await _get_or_create_treebank_work(
            session, lang_id, f"PROIEL {title}", "Various Authors", slug
        )

        # Clear existing data
        await session.execute(
            delete(Token).where(
                Token.segment_id.in_(select(TextSegment.id).where(TextSegment.work_id == work_id))
            )
        )
        await session.execute(delete(TextSegment).where(TextSegment.work_id == work_id))
        await session.flush()

        # Insert segments and tokens
        tokens_inserted = 0
        for idx, sentence_data in enumerate(sentences):
            text = sentence_data.get("text") or " ".join(t["surface"] for t in sentence_data["tokens"])

            text_normalized = nfc(text)
            segment = TextSegment(
                work_id=work_id,
                ref=f"{slug.upper()}.{idx + 1}",
                text_raw=text,
                text_nfc=text_normalized,
                text_fold=accent_fold(text_normalized),
            )
            session.add(segment)
            await session.flush()

            for token_idx, token_data in enumerate(sentence_data["tokens"]):
                surface = token_data["surface"]
                lemma = token_data["lemma"]
                morph_tag = token_data.get("morph_tag")
                features = token_data.get("features")

                msd = {}
                if morph_tag and morph_tag != "_":
                    msd["proiel_tag"] = morph_tag
                if features and features != "_":
                    msd["features"] = features

                token = Token(
                    segment_id=segment.id,
                    idx=token_idx,
                    surface=surface[:150],
                    surface_nfc=nfc(surface)[:150],
                    surface_fold=accent_fold(surface)[:150],
                    lemma=lemma[:150] if lemma and lemma != "_" else None,
                    lemma_fold=accent_fold(lemma)[:150] if lemma and lemma != "_" else None,
                    msd=msd if msd else None,
                )
                session.add(token)
                tokens_inserted += 1

            if (idx + 1) % 1000 == 0:
                print(f"Processed {idx + 1} sentences, {tokens_inserted} tokens...")
                await session.commit()

        await session.commit()
        results.append({"source": slug, "sentences": len(sentences), "tokens": tokens_inserted})

    return results


async def _get_language_id(session: AsyncSession, code: str) -> int:
    """Get language ID by code."""
    result = await session.execute(select(Language.id).where(Language.code == code))
    lang_id = result.scalar_one_or_none()
    if not lang_id:
        raise ValueError(f"Language {code} not found in database")
    return lang_id


async def _get_or_create_treebank_work(
    session: AsyncSession, language_id: int, title: str, author: str, slug: str
) -> int:
    """Get or create a treebank reference work."""
    # Get or create source
    result = await session.execute(select(SourceDoc.id).where(SourceDoc.slug == slug))
    source_id = result.scalar_one_or_none()

    if not source_id:
        source = SourceDoc(
            slug=slug,
            title=f"{title} (Treebank Reference Data)",
            meta={"type": "treebank"},
            license={
                "name": "CC BY-NC-SA 3.0",
                "url": "https://creativecommons.org/licenses/by-nc-sa/3.0/",
            },
        )
        session.add(source)
        await session.flush()
        source_id = source.id

    # Get or create work
    result = await session.execute(
        select(TextWork.id).where(TextWork.source_id == source_id, TextWork.title == title)
    )
    work_id = result.scalar_one_or_none()

    if not work_id:
        work = TextWork(
            language_id=language_id,
            source_id=source_id,
            author=author,
            title=title,
            ref_scheme="simple",
        )
        session.add(work)
        await session.flush()
        work_id = work.id

    return work_id


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ingest treebank morphology data.")
    parser.add_argument(
        "--source",
        choices=["perseus", "proiel", "all"],
        default="all",
        help="Which treebank to ingest (default: all)",
    )
    return parser.parse_args()


async def _run(args: argparse.Namespace) -> None:
    async with SessionLocal() as session:
        if args.source in ["perseus", "all"]:
            print("\n=== Ingesting Perseus UD Treebank ===")
            result = await ingest_perseus_ud(session)
            print(f"[{result['source']}] Sentences: {result['sentences']}, Tokens: {result['tokens']}")

        if args.source in ["proiel", "all"]:
            print("\n=== Ingesting PROIEL Treebanks ===")
            results = await ingest_proiel(session)
            for result in results:
                print(f"[{result['source']}] Sentences: {result['sentences']}, Tokens: {result['tokens']}")


def main() -> None:
    args = _parse_args()
    try:
        asyncio.run(_run(args))
        print("\n[SUCCESS] Treebank ingestion completed!")
    except Exception as e:
        print(f"\n[ERROR] Ingestion failed: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
