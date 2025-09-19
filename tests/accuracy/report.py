from __future__ import annotations

import asyncio
import json
from pathlib import Path
from typing import Any, Dict, Iterable

from app.db.util import SessionLocal
from app.ingestion.normalize import accent_fold
from app.ling.morph import analyze_tokens
from app.retrieval.hybrid import hybrid_search
from sqlalchemy import text


async def evaluate_retrieval(entries: Iterable[Dict[str, Any]]) -> Dict[str, Any]:
    matches = 0
    total = 0
    for entry in entries:
        total += 1
        language = entry.get("language", "grc")
        expected = set(entry.get("expected_refs", []))
        hits = await hybrid_search(entry["query"], language=language)
        refs = {hit["work_ref"] for hit in hits}
        if refs & expected:
            matches += 1
    return {"matches": matches, "total": total, "accuracy": matches / total if total else 0.0}


async def evaluate_smyth(entries: Iterable[Dict[str, Any]], *, limit: int = 5) -> Dict[str, Any]:
    entries = list(entries)
    if not entries:
        return {"matches": 0, "total": 0, "accuracy": 0.0}

    matches = 0
    async with SessionLocal() as session:
        await session.execute(text("SELECT set_limit(:threshold)"), {"threshold": 0.05})
        for entry in entries:
            language = entry.get("language", "grc")
            expected = set(entry.get("expected", []))
            result = await session.execute(
                text(
                    """
                    SELECT gt.anchor
                    FROM grammar_topic AS gt
                    JOIN source_doc AS sd ON sd.id = gt.source_id
                    WHERE gt.body_fold % :query_fold
                      AND COALESCE(sd.meta->>'language', 'grc') = :language
                    ORDER BY similarity(gt.body_fold, :query_fold) DESC, gt.anchor
                    LIMIT :limit
                    """
                ),
                {
                    "query_fold": accent_fold(entry["query"]),
                    "language": language,
                    "limit": limit,
                },
            )
            anchors = set(result.scalars().all())
            if anchors & expected:
                matches += 1
    total = len(entries)
    return {"matches": matches, "total": total, "accuracy": matches / total if total else 0.0}


async def evaluate_tokens(entries: Iterable[Dict[str, Any]], *, language: str = "grc") -> Dict[str, Any]:
    entries = list(entries)
    if not entries:
        return {
            "total": 0,
            "lemma_matches": 0,
            "morph_matches": 0,
            "lemma_accuracy": 0.0,
            "morph_accuracy": 0.0,
        }

    surfaces = [entry["surface"] for entry in entries]
    analyses = await analyze_tokens(surfaces, language=language)

    lemma_matches = 0
    morph_matches = 0
    for entry, analysis in zip(entries, analyses):
        if analysis.get("lemma") == entry.get("lemma"):
            lemma_matches += 1
        expected_morph = entry.get("morph")
        if expected_morph and analysis.get("morph") == expected_morph:
            morph_matches += 1

    total = len(entries)
    return {
        "total": total,
        "lemma_matches": lemma_matches,
        "morph_matches": morph_matches,
        "lemma_accuracy": lemma_matches / total if total else 0.0,
        "morph_accuracy": morph_matches / total if total else 0.0,
    }


async def generate_report(data: Dict[str, Any]) -> Dict[str, Any]:
    return {
        "retrieval": await evaluate_retrieval(data.get("retrieval", [])),
        "smyth": await evaluate_smyth(data.get("smyth", [])),
        "tokens": await evaluate_tokens(data.get("tokens", [])),
    }


def load_gold(path: Path | None = None) -> Dict[str, Any]:
    target = path or Path(__file__).resolve().parent / "gold.yaml"
    return json.loads(target.read_text(encoding="utf-8"))


async def main() -> None:
    data = load_gold()
    report = await generate_report(data)
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(main())
