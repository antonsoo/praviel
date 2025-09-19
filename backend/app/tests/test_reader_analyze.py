from __future__ import annotations

import json
import os
from contextlib import AsyncExitStack

import httpx
import pytest

from app.tests.conftest import run_async

test_requires_db = os.getenv("RUN_DB_TESTS") == "1"
pytestmark = pytest.mark.skipif(not test_requires_db, reason="Set RUN_DB_TESTS=1 to run DB-backed tests")


def _call_reader(payload: dict[str, str], params: dict[str, str] | None = None):
    async def _request() -> httpx.Response:
        from app.main import app

        async with AsyncExitStack() as stack:
            await stack.enter_async_context(app.router.lifespan_context(app))
            async with httpx.AsyncClient(
                transport=httpx.ASGITransport(app=app),
                base_url="http://testserver",
            ) as client:
                return await client.post("/reader/analyze", json=payload, params=params)

    return run_async(_request())


def test_reader_analyze_returns_tokens_and_hits(ensure_iliad_sample):
    response = _call_reader({"q": "μῆνιν ἄειδε"})

    assert response.status_code == 200, response.text
    payload = response.json()

    tokens = payload.get("tokens")
    assert isinstance(tokens, list) and tokens
    first = tokens[0]
    assert first["text"].startswith("μῆνιν")
    assert first["lemma"] == "μῆνις"
    assert first["morph"] == "n-s---fa-"

    retrieval = payload.get("retrieval")
    assert isinstance(retrieval, list) and retrieval
    top = retrieval[0]
    assert "segment_id" in top
    assert top.get("work_ref")
    assert top.get("text_nfc")
    assert top.get("reasons") == ["lexical"]
    assert payload.get("lexicon") is None
    assert payload.get("grammar") is None


def test_reader_analyze_variants_align_hits(ensure_iliad_sample):
    base = _call_reader({"q": "μῆνιν"})
    folded = _call_reader({"q": "ΜΗΝΙΝ"})

    assert base.status_code == 200 and folded.status_code == 200
    base_id = base.json()["retrieval"][0]["segment_id"]
    folded_id = folded.json()["retrieval"][0]["segment_id"]
    assert base_id == folded_id


def test_reader_analyze_includes_lexicon_and_smyth(ensure_iliad_sample):
    params = {"include": json.dumps({"lsj": True, "smyth": True})}
    response = _call_reader({"q": "μῆνιν ἄειδε"}, params=params)

    assert response.status_code == 200, response.text
    payload = response.json()

    lexicon = payload.get("lexicon")
    assert isinstance(lexicon, list) and lexicon
    assert any(entry.get("lemma") == "μῆνις" for entry in lexicon)

    grammar = payload.get("grammar")
    assert isinstance(grammar, list) and grammar
    top = grammar[0]
    assert top.get("anchor") == "smyth-123"
    assert top.get("title")
