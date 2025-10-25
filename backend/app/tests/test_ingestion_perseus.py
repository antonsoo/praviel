from __future__ import annotations

import os
from pathlib import Path

import pytest
from lxml import etree
from sqlalchemy import text

from app.core.config import settings
from app.db.session import SessionLocal
from app.ingestion.jobs import ingest_iliad_sample
from app.ingestion.sources.perseus import extract_book_line_segments, extract_stephanus_segments

RUN_DB_TESTS = os.getenv("RUN_DB_TESTS") == "1"


def _parse_xml(xml: str) -> etree._Element:
    return etree.fromstring(xml.encode("utf-8"))


def test_extract_book_line_segments_basic():
    xml = """
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
      <text>
        <body>
          <div type="book" n="1">
            <l n="1">
              <w lemma="ἀνήρ" ana="n-s---mn-">Ἀνήρ</w>
              <pc>,</pc>
              <w lemma="εἰμί" ana="v3spia---">ἐστίν</w>
            </l>
            <l n="2">
              <w lemma="θεός" ana="n-s---mn-">θεός</w>
            </l>
          </div>
        </body>
      </text>
    </TEI>
    """
    root = _parse_xml(xml)
    segments = list(extract_book_line_segments(root, "Il"))
    assert len(segments) == 2

    first = segments[0]
    assert first.ref == "Il.1.1"
    assert first.text_nfc.startswith("Ἀνήρ")
    assert len(first.tokens) == 2
    assert first.tokens[0].lemma == "ἀνήρ"
    assert first.tokens[0].msd.get("perseus_tag") == "n-s---mn-"


def test_extract_stephanus_segments_basic():
    xml = """
    <TEI xmlns="http://www.tei-c.org/ns/1.0">
      <text>
        <body>
          <div subtype="section" n="1">
            <p>
              <milestone unit="section" resp="Stephanus" n="17a"/>
              <w lemma="ἄνδρες" ana="n-v---mn-">ἄνδρες</w>
              <pc>,</pc>
              <w lemma="Ἀθηναῖος" ana="n-v---mn-">Ἀθηναῖοι</w>
              <milestone unit="section" resp="Stephanus" n="17b"/>
              <w lemma="λέγω" ana="v1spia---">λέγω</w>
            </p>
          </div>
        </body>
      </text>
    </TEI>
    """
    root = _parse_xml(xml)
    segments = list(extract_stephanus_segments(root, "Apol"))
    assert [segment.ref for segment in segments] == ["Apol.17a", "Apol.17b"]

    first = segments[0]
    assert first.tokens[0].surface == "ἄνδρες"
    assert first.tokens[0].msd.get("perseus_tag") == "n-v---mn-"


@pytest.mark.asyncio
@pytest.mark.skipif(
    not RUN_DB_TESTS,
    reason="Set RUN_DB_TESTS=1 to run backend ingestion DB tests",
)
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
