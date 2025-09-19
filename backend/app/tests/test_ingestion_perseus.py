import os
from pathlib import Path

import pytest
from sqlalchemy import text

from app.core.config import settings
from app.db.session import SessionLocal
from app.ingestion.jobs import ingest_iliad_sample

RUN_DB_TESTS = os.getenv("RUN_DB_TESTS") == "1"
pytestmark = pytest.mark.skipif(
    not RUN_DB_TESTS,
    reason="Set RUN_DB_TESTS=1 to run backend ingestion DB tests",
)


@pytest.mark.asyncio
async def test_ingest_iliad_sample():
    # Use real data path; if not present, skip
    tei = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1.xml"
    if not tei.exists():
        pytest.skip("Perseus TEI not present locally")
    tok = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1_tokens.xml"
    async with SessionLocal() as db:
        res = await ingest_iliad_sample(db, tei, tok if tok.exists() else tei)
        assert res["segments_added"] >= 10

        segs = (await db.execute(text("SELECT count(*) FROM text_segment"))).scalar_one()
        assert segs >= 10

        # Check deterministic chunk_id presence
        meta = (await db.execute(text("SELECT meta FROM text_segment LIMIT 1"))).first()[0]
        assert "chunk_id" in (meta or {})
