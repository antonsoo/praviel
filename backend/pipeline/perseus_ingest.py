from __future__ import annotations

import argparse
import os
from pathlib import Path
from typing import Iterable, Sequence

from lxml import etree
from sqlalchemy import bindparam, create_engine, text
from sqlalchemy.dialects.postgresql import JSONB

try:
    from app.ingestion.normalize import accent_fold, nfc
except ModuleNotFoundError as exc:  # pragma: no cover - only hit outside repo
    raise SystemExit("Run from the backend package (PYTHONPATH=backend)") from exc

NS = {"tei": "http://www.tei-c.org/ns/1.0"}


def parse_lines(tei_path: Path) -> tuple[str, str, Sequence[tuple[str, str, str]]]:
    parser = etree.XMLParser(remove_comments=True, recover=True)
    root = etree.parse(str(tei_path), parser).getroot()

    author = (
        root.xpath("string(//tei:teiHeader//tei:titleStmt/tei:author)", namespaces=NS).strip() or "Unknown"
    )
    title = (
        root.xpath("string(//tei:teiHeader//tei:titleStmt/tei:title)", namespaces=NS).strip() or tei_path.stem
    )

    lines = root.xpath("//tei:div[@type='book'][1]//tei:l", namespaces=NS) or root.xpath(
        "//tei:l", namespaces=NS
    )

    parsed: list[tuple[str, str, str]] = []
    for idx, node in enumerate(lines, start=1):
        text_raw = "".join(node.itertext()).strip()
        if not text_raw:
            continue
        ref = node.get("{http://www.w3.org/XML/1998/namespace}id") or node.get("n") or str(idx)
        content_nfc = nfc(text_raw)
        parsed.append((ref, content_nfc, accent_fold(content_nfc)))
    return author, title, parsed


def ensure_language(conn, code: str, name: str) -> int:
    row = conn.execute(
        text(
            "INSERT INTO language(code,name) VALUES(:code,:name) "
            "ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name RETURNING id"
        ),
        {"code": code, "name": name},
    ).first()
    assert row is not None
    return int(row[0])


def ensure_source(conn, slug: str, title: str, license_meta: dict | None) -> int:
    stmt = text(
        "INSERT INTO source_doc(slug,title,license,meta) "
        "VALUES(:slug,:title,:license,:meta) "
        "ON CONFLICT (slug) DO UPDATE SET title = EXCLUDED.title RETURNING id"
    ).bindparams(
        bindparam("license", type_=JSONB),
        bindparam("meta", type_=JSONB),
    )
    row = conn.execute(
        stmt,
        {
            "slug": slug,
            "title": title,
            "license": license_meta or {},
            "meta": {},
        },
    ).first()
    assert row is not None
    return int(row[0])


def ensure_work(conn, language_id: int, source_id: int, author: str, title: str, ref_scheme: str) -> int:
    existing = conn.execute(
        text("SELECT id FROM text_work WHERE language_id=:lang AND author=:author AND title=:title"),
        {"lang": language_id, "author": author, "title": title},
    ).first()
    if existing:
        return int(existing[0])
    row = conn.execute(
        text(
            "INSERT INTO text_work(language_id,source_id,author,title,ref_scheme) "
            "VALUES(:lang,:source,:author,:title,:scheme) RETURNING id"
        ),
        {
            "lang": language_id,
            "source": source_id,
            "author": author,
            "title": title,
            "scheme": ref_scheme,
        },
    ).first()
    assert row is not None
    return int(row[0])


def upsert_segments(
    conn,
    work_id: int,
    lines: Iterable[tuple[str, str, str]],
    source_tag: str,
) -> int:
    inserted = 0
    for idx, (ref, content_nfc, content_fold) in enumerate(lines, start=1):
        stmt = text(
            """
            INSERT INTO text_segment(
                work_id,
                ref,
                text_raw,
                text_nfc,
                text_fold,
                meta
            ) VALUES (:work, :ref, :raw, :nfc, :fold, :meta)
            ON CONFLICT (work_id, ref) DO UPDATE SET
                text_raw = EXCLUDED.text_raw,
                text_nfc = EXCLUDED.text_nfc,
                text_fold = EXCLUDED.text_fold,
                meta = EXCLUDED.meta,
                updated_at = now()
            """
        ).bindparams(bindparam("meta", type_=JSONB))
        conn.execute(
            stmt,
            {
                "work": work_id,
                "ref": ref,
                "raw": content_nfc,
                "nfc": content_nfc,
                "fold": content_fold,
                "meta": {"chunk_index": idx, "source": source_tag},
            },
        )
        inserted += 1
    return inserted


def fetch_sample(conn, work_id: int):
    row = conn.execute(
        text(
            "SELECT ref, text_raw FROM text_segment "
            "WHERE work_id = :work ORDER BY (meta->>'chunk_index')::int NULLS FIRST, ref LIMIT 1"
        ),
        {"work": work_id},
    ).first()
    if not row:
        return None, None
    return row[0], row[1]


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Ingest a tiny Perseus TEI sample into text_segment")
    parser.add_argument("--tei", required=True, type=Path, help="Path to the TEI XML file")
    parser.add_argument("--language", default="grc", help="Language code (default: grc)")
    parser.add_argument("--language-name", default="Ancient Greek", help="Language display name")
    parser.add_argument("--source", default="perseus-sample", help="Source slug")
    parser.add_argument("--source-title", default="Perseus Sample", help="Source title")
    parser.add_argument("--ref-scheme", default="line", help="Reference scheme for text_work")
    parser.add_argument(
        "--ensure-table",
        action="store_true",
        help="Compat flag (no-op; schema already exists)",
    )
    parser.add_argument("--database-url", default=None, help="Override database URL")
    args = parser.parse_args(argv)

    if not args.tei.exists():
        raise SystemExit(f"TEI file not found: {args.tei}")

    db_url = (
        args.database_url or os.getenv("DATABASE_URL") or "postgresql+psycopg://app:app@localhost:5433/app"
    )

    author, title, lines = parse_lines(args.tei)
    if not lines:
        raise SystemExit("No TEI <l> lines found")

    engine = create_engine(db_url, future=True)
    with engine.begin() as conn:
        language_id = ensure_language(conn, args.language, args.language_name)
        source_id = ensure_source(conn, args.source, args.source_title, {"url": "https://perseus.tufts.edu"})
        work_id = ensure_work(conn, language_id, source_id, author, title, args.ref_scheme)
        inserted = upsert_segments(conn, work_id, lines, args.source)
        sample_ref, sample_text = fetch_sample(conn, work_id)

    print(f"Inserted={inserted} Work={author} - {title} FirstLine={sample_ref}:{sample_text}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
