from pathlib import Path

import pytest
from sqlalchemy import text

from app.core.config import settings
from app.db.session import SessionLocal
from app.ingestion.jobs import ingest_iliad_sample


@pytest.mark.asyncio
async def test_ingest_iliad_sample(tmp_path: Path):
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
