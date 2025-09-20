from __future__ import annotations

import argparse
import json
import os
from typing import Any, Iterable, Sequence

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import NoSuchTableError

try:  # Prefer project helper if available
    from app.ingestion.normalize import accent_fold
except ImportError:  # pragma: no cover - fallback for standalone usage
    import unicodedata

    def accent_fold(value: str) -> str:
        decomposed = unicodedata.normalize("NFD", value)
        stripped = "".join(ch for ch in decomposed if unicodedata.category(ch) != "Mn")
        folded = stripped.casefold()
        return unicodedata.normalize("NFC", folded)


DEFAULT_DB_URL = "postgresql+psycopg://app:app@localhost:5433/app"


def _resolve_url(database_url: str | None) -> str:
    return database_url or os.getenv("DATABASE_URL_SYNC") or os.getenv("DATABASE_URL") or DEFAULT_DB_URL


def _ensure_engine(database_url: str | None) -> Engine:
    return create_engine(_resolve_url(database_url), future=True)


def _gather_columns(engine: Engine, table: str) -> set[str]:
    try:
        return {col["name"] for col in inspect(engine).get_columns(table)}
    except NoSuchTableError:
        return set()


def _build_query(engine: Engine) -> tuple[str, bool, bool] | None:
    segment_cols = _gather_columns(engine, "text_segment")
    required_segment = {"text_fold", "text_raw"}
    if not required_segment.issubset(segment_cols):
        return None

    work_cols = _gather_columns(engine, "text_work") if "work_id" in segment_cols else set()
    language_cols = _gather_columns(engine, "language") if "language_id" in work_cols else set()

    idx_select = "COALESCE(text_segment.idx, 0) AS idx" if "idx" in segment_cols else "0 AS idx"

    select_parts = [
        "text_segment.ref",
        "text_segment.text_raw AS text",
        idx_select,
        "similarity(text_segment.text_fold, :q_fold) AS score",
    ]

    joins: list[str] = []
    include_work = bool(work_cols)
    include_language = bool(language_cols and include_work)

    if include_work:
        joins.append("LEFT JOIN text_work ON text_work.id = text_segment.work_id")
        if "title" in work_cols:
            select_parts.append("text_work.title AS work_title")
        if "author" in work_cols:
            select_parts.append("text_work.author AS work_author")
    if include_language:
        joins.append("LEFT JOIN language ON language.id = text_work.language_id")
        if "code" in language_cols:
            select_parts.append("language.code AS lang_code")
        if "name" in language_cols:
            select_parts.append("language.name AS lang_name")

    where_clauses = ["similarity(text_segment.text_fold, :q_fold) >= :threshold"]
    requires_lang_filter = include_language and "code" in language_cols
    if requires_lang_filter:
        where_clauses.append("language.code = :lang")

    sql = "\n".join(
        [
            f"SELECT {', '.join(select_parts)}",
            "FROM text_segment",
            *joins,
            "WHERE " + " AND ".join(where_clauses),
            "ORDER BY score DESC, text_segment.ref",
            "LIMIT :limit",
        ]
    )
    return sql, include_work, requires_lang_filter


def _coerce_result(row: Any, include_work: bool) -> dict[str, Any]:
    data = dict(row._mapping)
    result: dict[str, Any] = {
        "text": data.pop("text", None),
        "idx": data.pop("idx", 0),
        "score": data.pop("score", 0.0),
        "ref": data.pop("ref", None),
    }

    work_name = data.pop("work_title", None)
    work_author = data.pop("work_author", None)
    if include_work and (work_name or work_author):
        if work_name and work_author:
            result["work"] = f"{work_author} — {work_name}"
        else:
            result["work"] = work_name or work_author

    lang_code = data.pop("lang_code", None)
    if lang_code:
        result["lang"] = lang_code
    lang_name = data.pop("lang_name", None)
    if lang_name:
        result.setdefault("lang_name", lang_name)

    for key, value in data.items():
        result.setdefault(key, value)
    return result


def search(
    query: str,
    *,
    language: str = "grc",
    limit: int = 5,
    threshold: float = 0.1,
    database_url: str | None = None,
) -> list[dict[str, Any]]:
    """Execute a trigram search over text segments."""

    if not query:
        return []

    engine = _ensure_engine(database_url)
    plan = _build_query(engine)
    if plan is None:
        return []

    sql, include_work, requires_lang_filter = plan
    params: dict[str, Any] = {
        "q_fold": accent_fold(query),
        "threshold": threshold,
        "limit": max(1, limit),
    }
    if requires_lang_filter:
        params["lang"] = language

    with engine.connect() as conn:
        rows = conn.execute(text(sql), params).fetchall()

    return [_coerce_result(row, include_work) for row in rows]


def _print(results: Iterable[dict[str, Any]]) -> None:
    for entry in results:
        print(json.dumps(entry, ensure_ascii=False))


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run trigram search over text_segment")
    parser.add_argument("query", help="Search query string")
    parser.add_argument("-l", "--language", default="grc", help="Language code (default: grc)")
    parser.add_argument("-k", "--limit", type=int, default=5, help="Maximum rows to return")
    parser.add_argument(
        "-t",
        "--threshold",
        type=float,
        default=0.1,
        help="Minimum trigram similarity (default: 0.1)",
    )
    parser.add_argument("--database-url", default=None, help="Override database URL")
    args = parser.parse_args(argv)

    results = search(
        args.query,
        language=args.language,
        limit=args.limit,
        threshold=args.threshold,
        database_url=args.database_url,
    )
    _print(results)
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
