from __future__ import annotations

import os
import unicodedata

import pytest
from sqlalchemy import text

from app.core.config import settings
from app.db.util import SessionLocal
from app.ingestion.normalize import accent_fold
from app.retrieval.hybrid import hybrid_search
from app.tests.conftest import run_async

RUN_DB_TESTS = os.getenv("RUN_DB_TESTS") == "1"
pytestmark = pytest.mark.skipif(not RUN_DB_TESTS, reason="Set RUN_DB_TESTS=1 to run DB-backed tests")


def test_hybrid_search_returns_hit(ensure_iliad_sample):
    hits = run_async(hybrid_search("Μῆνιν", language="grc", k=3, t=0.05))
    assert hits, "Expected at least one hybrid hit"

    first = hits[0]
    assert "segment_id" in first and first["segment_id"]
    assert "work_ref" in first and isinstance(first["work_ref"], str)
    normalized = unicodedata.normalize("NFC", first.get("text_nfc", ""))
    assert accent_fold(normalized).startswith("μηνιν")
    assert 0.0 <= first["score"] <= 1.0
    assert first.get("reasons") == ["lexical"]


def test_hybrid_search_handles_folded_variants(ensure_iliad_sample):
    baseline = run_async(hybrid_search("Μῆνιν", language="grc", k=1, t=0.05))
    assert baseline, "expected baseline hybrid hit"
    target = baseline[0]["segment_id"]

    folded_variant = run_async(hybrid_search("Μηνιν", language="grc", k=1, t=0.05))
    oxia_variant = run_async(hybrid_search("Μὴνιν", language="grc", k=1, t=0.05))

    assert folded_variant and folded_variant[0]["segment_id"] == target
    assert oxia_variant and oxia_variant[0]["segment_id"] == target


def test_hybrid_search_reasons_reflect_embeddings(ensure_iliad_sample):
    # Clear any existing embeddings to confirm lexical-only reasons.
    async def _clear_embeddings() -> None:
        async with SessionLocal() as db:
            await db.execute(text("UPDATE text_segment SET emb = NULL"))
            await db.commit()

    run_async(_clear_embeddings())

    lexical_hits = run_async(hybrid_search("Μῆνιν", language="grc", k=3))
    assert lexical_hits
    assert all(hit.get("reasons") == ["lexical"] for hit in lexical_hits)

    # Attach a simple unit vector to the top segment to exercise vector blending.
    seg_id = lexical_hits[0]["segment_id"]
    emb = "[" + ",".join(["0.01"] * settings.EMBED_DIM) + "]"

    async def _apply_embedding() -> None:
        async with SessionLocal() as db:
            await db.execute(
                text("UPDATE text_segment SET emb = CAST(:vector AS vector) WHERE id = :seg_id"),
                {"vector": emb, "seg_id": seg_id},
            )
            await db.commit()

    run_async(_apply_embedding())

    hybrid_hits = run_async(hybrid_search("Μῆνιν", language="grc", k=3, use_vector=True))
    assert hybrid_hits
    assert any("vector" in hit.get("reasons", []) for hit in hybrid_hits)

    run_async(_clear_embeddings())


def test_hybrid_search_handles_accentless_queries(ensure_iliad_sample):
    accented = run_async(hybrid_search("Μῆνιν ἄειδε", language="grc", k=3, t=0.05))
    plain = run_async(hybrid_search("Μηνιν αειδε", language="grc", k=3, t=0.05))
    assert accented and plain, "expected hits for accented and plain queries"
    assert [hit["segment_id"] for hit in accented] == [hit["segment_id"] for hit in plain]
