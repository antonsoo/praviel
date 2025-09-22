from __future__ import annotations

from pathlib import Path
from typing import Any, Dict

from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.util import text_with_json
from app.ingestion.normalize import accent_fold, nfc
from app.ingestion.sources.perseus import iter_lines_book1, iter_tokens, read_tei

ILIAD_AUTHOR = "Homer"
ILIAD_TITLE = "Iliad"
SRC_SLUG = "perseus-canonical-greekLit"
SRC_TITLE = "Perseus Digital Library"

SAMPLE_TOKENS = [
    ("μῆνιν", "μῆνις", "n-s---fa-"),
    ("ἄειδε", "ἀείδω", "v-imp---2s-"),
    ("θεὰ", "θεά", "n-s---fn-"),
    ("Πηληϊάδεω", "Πηληϊάδης", "n-s---mg-"),
    ("Ἀχιλῆος", "Ἀχιλλεύς", "n-s---mg-"),
]


async def ensure_language(db: AsyncSession, code: str, name: str) -> int:
    await db.execute(
        text("INSERT INTO language(code,name) VALUES(:c,:n) ON CONFLICT (code) DO NOTHING"),
        {"c": code, "n": name},
    )
    row = (await db.execute(text("SELECT id FROM language WHERE code=:c"), {"c": code})).first()
    if not row:
        raise RuntimeError(f"Language {code} not found after seed attempt")
    return row[0]


async def ensure_source(
    db: AsyncSession, slug: str, title: str, license_meta: dict, extra_meta: dict | None = None
) -> int:
    row = (await db.execute(text("SELECT id FROM source_doc WHERE slug=:s"), {"s": slug})).first()
    if row:
        return row[0]
    await db.execute(
        text_with_json(
            "INSERT INTO source_doc(slug,title,license,meta) VALUES(:s,:t,:lic,:m)",
            "lic",
            "m",
        ),
        {"s": slug, "t": title, "lic": license_meta, "m": extra_meta or {}},
    )
    await db.commit()
    row2 = (await db.execute(text("SELECT id FROM source_doc WHERE slug=:s"), {"s": slug})).first()
    return row2[0]


async def ensure_work(
    db: AsyncSession,
    lang_code: str,
    source_id: int,
    author: str,
    title: str,
    ref_scheme: str,
) -> int:
    lang_id = await ensure_language(db, lang_code, "Ancient Greek" if lang_code == "grc" else lang_code)
    row = (
        await db.execute(
            text("SELECT id FROM text_work WHERE language_id=:l AND author=:a AND title=:t"),
            {"l": lang_id, "a": author, "t": title},
        )
    ).first()
    if row:
        return row[0]

    await db.execute(
        text("INSERT INTO text_work(language_id,source_id,author,title,ref_scheme) VALUES(:l,:s,:a,:t,:r)"),
        {"l": lang_id, "s": source_id, "a": author, "t": title, "r": ref_scheme},
    )
    await db.commit()
    r2 = (
        await db.execute(
            text("SELECT id FROM text_work WHERE language_id=:l AND author=:a AND title=:t"),
            {"l": lang_id, "a": author, "t": title},
        )
    ).first()
    return r2[0]


async def ingest_iliad_sample(
    db: AsyncSession,
    tei_path: Path,
    tokenized_path: Path,
    start_line: int = 1,
    end_line: int = 50,
) -> Dict[str, Any]:
    """
    Ingest Iliad Book 1 lines start_line–end_line into text_segment and token tables.
    DEV/TEST-ONLY: we clear existing segments for this work to keep test runs deterministic.
    """
    if start_line < 1:
        raise ValueError("start_line must be >= 1")
    if end_line < start_line:
        raise ValueError("end_line must be >= start_line")

    root = read_tei(tei_path)
    tro = read_tei(tokenized_path) if tokenized_path.exists() else root

    source_id = await ensure_source(
        db,
        SRC_SLUG,
        SRC_TITLE,
        {"license": "CC BY-SA", "url": "https://perseus.tufts.edu"},
        {},
    )
    work_id = await ensure_work(db, "grc", source_id, ILIAD_AUTHOR, ILIAD_TITLE, "book:line")

    # ---- DEV determinism: purge existing segments/tokens for this work ----
    await db.execute(
        text(
            "DELETE FROM token USING text_segment "
            "WHERE token.segment_id = text_segment.id AND text_segment.work_id = :w"
        ),
        {"w": work_id},
    )
    await db.execute(text("DELETE FROM text_segment WHERE work_id=:w"), {"w": work_id})
    await db.commit()

    added_segments = 0
    last_ref: str | None = None
    first_ref: str | None = None

    for idx, (ref, t_nfc, t_fold) in enumerate(iter_lines_book1(root), start=1):
        if idx < start_line:
            continue
        if idx > end_line:
            break
        if ref and "." in ref:
            line_ref = ref if ref.startswith("1.") else f"1.{ref.split('.', 1)[-1]}"
        else:
            line_ref = f"1.{idx}"
        chunk_id = f"iliad1-{idx:03d}"
        await db.execute(
            text_with_json(
                "INSERT INTO text_segment(work_id,ref,text_raw,text_nfc,text_fold,meta) "
                "VALUES(:w,:r,:raw,:nfc,:fold,:m)",
                "m",
            ),
            {
                "w": work_id,
                "r": line_ref,
                "raw": t_nfc,
                "nfc": t_nfc,
                "fold": t_fold,
                "m": {"chunk_id": chunk_id},
            },
        )
        added_segments += 1
        last_ref = line_ref
        if first_ref is None:
            first_ref = line_ref

    primary_ref = first_ref or f"1.{start_line}"

    # Minimal token demo: attach first few tokens of the first ingested line under its segment
    seg_id_row = (
        await db.execute(
            text("SELECT id FROM text_segment WHERE work_id=:w AND ref=:r"),
            {"w": work_id, "r": primary_ref},
        )
    ).first()
    if seg_id_row:
        seg_id = seg_id_row[0]
        idx = 0
        inserted = 0
        for sn, sf, ln, lf, msd in iter_tokens(tro):
            await db.execute(
                text_with_json(
                    "INSERT INTO token(segment_id,idx,surface,surface_nfc,surface_fold,lemma,lemma_fold,msd) "
                    "VALUES(:sid,:i,:s,:sn,:sf,:l,:lf,:m)",
                    "m",
                ),
                {"sid": seg_id, "i": idx, "s": sn, "sn": sn, "sf": sf, "l": ln, "lf": lf, "m": msd},
            )
            inserted += 1
            idx += 1
            if idx >= 12:
                break

        if inserted == 0:
            for surface, lemma, tag in SAMPLE_TOKENS:
                surface_nfc = nfc(surface)
                surface_fold = accent_fold(surface_nfc)
                lemma_fold = accent_fold(lemma) if lemma else None
                msd_payload = {"perseus_tag": tag} if tag else {}
                await db.execute(
                    text_with_json(
                        (
                            "INSERT INTO token("
                            "segment_id,idx,surface,surface_nfc,surface_fold,"
                            "lemma,lemma_fold,msd) "
                            "VALUES(:sid,:i,:s,:sn,:sf,:l,:lf,:m)"
                        ),
                        "m",
                    ),
                    {
                        "sid": seg_id,
                        "i": idx,
                        "s": surface_nfc,
                        "sn": surface_nfc,
                        "sf": surface_fold,
                        "l": lemma,
                        "lf": lemma_fold,
                        "m": msd_payload,
                    },
                )
                idx += 1

    await db.commit()

    end_total = (
        await db.execute(
            select(func.count()).select_from(text("text_segment")).where(text("work_id=:w")).params(w=work_id)
        )
    ).scalar_one()

    slice_end = last_ref or primary_ref
    slice_start = first_ref or f"1.{start_line}"
    return {
        "segments_added": added_segments,
        "segments_total": int(end_total),
        "work_id": work_id,
        "source_id": source_id,
        "slice": {"start": slice_start, "end": slice_end},
    }
