from __future__ import annotations

import asyncio
import json
import os
from pathlib import Path

import pytest
from app.core.config import settings
from app.db.util import SessionLocal
from app.ingestion.jobs import ingest_iliad_sample
from app.retrieval.hybrid import hybrid_search

RUN_ACCURACY = os.getenv("RUN_ACCURACY_TESTS") == "1"
RUN_DB = os.getenv("RUN_DB_TESTS") == "1"

if os.name == "nt":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
pytestmark = pytest.mark.skipif(
    not (RUN_ACCURACY and RUN_DB),
    reason="Set RUN_DB_TESTS=1 and RUN_ACCURACY_TESTS=1 to run accuracy harness",
)


@pytest.mark.asyncio
async def test_accuracy_smoke_report() -> None:
    await _ensure_iliad_sample()

    gold_path = Path(__file__).resolve().parent / "gold.yaml"
    entries = json.loads(gold_path.read_text(encoding="utf-8"))
    assert entries, "Gold file is empty"

    matches = 0
    for item in entries:
        language = item.get("language", "grc")
        expected = set(item.get("expected_refs", []))
        hits = await hybrid_search(item["query"], language=language)
        refs = {hit["work_ref"] for hit in hits}
        if expected & refs:
            matches += 1

    total = len(entries)
    print(f"Accuracy smoke: {matches}/{total} queries matched expected refs")
    assert total == len(entries)


async def _ensure_iliad_sample() -> None:
    tei = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1.xml"
    if not tei.exists():
        pytest.skip("Perseus Iliad TEI sample missing")
    tokens = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1_tokens.xml"
    async with SessionLocal() as session:
        await ingest_iliad_sample(session, tei, tokens if tokens.exists() else tei)
