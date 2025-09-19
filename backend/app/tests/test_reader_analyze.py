from __future__ import annotations

import os
from contextlib import AsyncExitStack

import httpx
import pytest

from app.tests.conftest import run_async

test_requires_db = os.getenv("RUN_DB_TESTS") == "1"
pytestmark = pytest.mark.skipif(not test_requires_db, reason="Set RUN_DB_TESTS=1 to run DB-backed tests")


def _call_reader(payload: dict[str, str]):
    async def _request() -> httpx.Response:
        from app.main import app

        async with AsyncExitStack() as stack:
            await stack.enter_async_context(app.router.lifespan_context(app))
            async with httpx.AsyncClient(
                transport=httpx.ASGITransport(app=app),
                base_url="http://testserver",
            ) as client:
                return await client.post("/reader/analyze", json=payload)

    return run_async(_request())


def test_reader_analyze_returns_tokens_and_hits(ensure_iliad_sample):
    response = _call_reader({"q": "Μῆνιν ἄειδε"})

    assert response.status_code == 200, response.text
    payload = response.json()
    tokens = payload.get("tokens")
    assert isinstance(tokens, list) and tokens
    first = tokens[0]
    assert first["text"].startswith("Μῆνιν")
    assert first["lemma"] is None
    assert first["morph"] is None

    retrieval = payload.get("retrieval")
    assert isinstance(retrieval, list) and retrieval
    top = retrieval[0]
    assert "segment_id" in top
    assert top.get("work_ref")
    assert top.get("text_nfc")
    assert top.get("reasons") == ["lexical"]


def test_reader_analyze_variants_align_hits(ensure_iliad_sample):
    base = _call_reader({"q": "Μῆνιν"})
    folded = _call_reader({"q": "Μηνιν"})

    assert base.status_code == 200 and folded.status_code == 200
    base_id = base.json()["retrieval"][0]["segment_id"]
    folded_id = folded.json()["retrieval"][0]["segment_id"]
    assert base_id == folded_id
