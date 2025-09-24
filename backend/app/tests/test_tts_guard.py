from __future__ import annotations

import os
from contextlib import AsyncExitStack

import httpx
import pytest

from app.core.config import settings
from app.db.util import SessionLocal, text_with_json
from app.ingestion.jobs import ensure_language, ensure_source, ensure_work
from app.ingestion.normalize import accent_fold, nfc
from app.tests.conftest import run_async

RUN_DB_TESTS = os.getenv("RUN_DB_TESTS") == "1"
pytestmark = pytest.mark.skipif(not RUN_DB_TESTS, reason="Set RUN_DB_TESTS=1 to run DB-backed tests")


def _post_tts(payload: dict[str, str], headers: dict[str, str] | None = None) -> httpx.Response:
    async def _request() -> httpx.Response:
        from app.main import app

        async with AsyncExitStack() as stack:
            await stack.enter_async_context(app.router.lifespan_context(app))
            async with httpx.AsyncClient(
                transport=httpx.ASGITransport(app=app),
                base_url="http://testserver",
            ) as client:
                return await client.post("/tts/speak", json=payload, headers=headers)

    return run_async(_request())


@pytest.fixture(scope="function")
def ensure_nc_segment() -> None:
    async def _seed() -> None:
        async with SessionLocal() as session:
            await ensure_language(session, "grc", "Ancient Greek")
            source_id = await ensure_source(
                session,
                "tts-nc-sample",
                "NC Sample Source",
                {"license": "CC BY-NC-SA 4.0"},
                {"purpose": "tts-guard-test"},
            )
            work_id = await ensure_work(session, "grc", source_id, "NcAuthor", "NcSample", "line")

            text_value = "ἄειδε θεά"
            normalized = nfc(text_value)
            folded = accent_fold(normalized)
            await session.execute(
                text_with_json(
                    """
                    INSERT INTO text_segment(work_id, ref, text_raw, text_nfc, text_fold, meta)
                    VALUES (:work_id, :ref, :raw, :nfc, :fold, :meta)
                    ON CONFLICT (work_id, ref) DO UPDATE SET
                        text_raw = EXCLUDED.text_raw,
                        text_nfc = EXCLUDED.text_nfc,
                        text_fold = EXCLUDED.text_fold,
                        meta = EXCLUDED.meta,
                        updated_at = now()
                    """,
                    "meta",
                ),
                {
                    "work_id": work_id,
                    "ref": "1.1",
                    "raw": normalized,
                    "nfc": normalized,
                    "fold": folded,
                    "meta": {"label": "Nc"},
                },
            )
            await session.commit()

    run_async(_seed())


def test_tts_guard_allows_daily_line(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "TTS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "TTS_LICENSE_GUARD", True, raising=False)

    response = _post_tts({"text": "χαῖρε κόσμε", "provider": "echo"})

    assert response.status_code == 200, response.text
    payload = response.json()
    assert "audio" in payload and "meta" in payload


def test_tts_guard_blocks_noncommercial_canon(
    monkeypatch: pytest.MonkeyPatch,
    ensure_nc_segment: None,
) -> None:
    monkeypatch.setattr(settings, "TTS_ENABLED", True, raising=False)
    monkeypatch.setattr(settings, "TTS_LICENSE_GUARD", True, raising=False)

    response = _post_tts({"text": "Nc.1.1 ἄειδε θεά", "provider": "echo"})

    assert response.status_code == 403, response.text
    detail = response.json()["detail"]
    assert detail["ref"] == "Nc.1.1"
    assert "nc" in detail["license"].lower()
    assert detail["reason"].startswith("TTS disabled")
