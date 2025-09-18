from __future__ import annotations

import argparse
import os
import sys
from typing import Iterable, Optional, Sequence

from sqlalchemy import create_engine, text
from sqlalchemy.engine import Connection, Engine

_PREFERRED_TEXT_COLUMNS: Sequence[str] = (
    "text_fold",
    "norm_text",
    "text_nfc",
    "text_raw",
    "raw_text",
)


def _db_url() -> str:
    return os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://postgres:postgres@localhost:5433/postgres",
    )


def _engine(url: str) -> Engine:
    return create_engine(url, future=True)


def _table_columns(conn: Connection, table: str) -> set[str]:
    rows = conn.execute(
        text(
            """
            SELECT column_name
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = :table
            """
        ),
        {"table": table},
    )
    return set(rows.scalars().all())


def _detect_text_column(columns: Iterable[str]) -> str:
    ordered = list(columns)
    if not ordered:
        raise RuntimeError("text_segment table not found")
    for candidate in _PREFERRED_TEXT_COLUMNS:
        if candidate in columns:
            return candidate
    return sorted(ordered)[0]


def _row_value(row, key: str, index: int):
    mapping = getattr(row, "_mapping", None)
    if mapping is not None:
        return mapping[key]
    return row[index]


def search(
    query: str,
    language: Optional[str],
    limit: int,
    threshold: float,
    db_url: str,
):
    engine = _engine(db_url)
    with engine.begin() as conn:
        segment_cols = _table_columns(conn, "text_segment")
        work_cols = _table_columns(conn, "text_work")

        column = _detect_text_column(segment_cols)
        column_expr = f"text_segment.{column}"
        similarity_expr = f"similarity({column_expr}, :query)"

        joins: list[str] = []
        join_work = bool(work_cols)
        join_language = False

        if join_work:
            joins.append("LEFT JOIN text_work ON text_work.id = text_segment.work_id")

        if "language_id" in segment_cols:
            joins.append("LEFT JOIN language ON language.id = text_segment.language_id")
            join_language = True
        elif join_work and "language_id" in work_cols:
            joins.append("LEFT JOIN language ON language.id = text_work.language_id")
            join_language = True

        where_parts = [f"{similarity_expr} >= :threshold"]
        params = {"query": query, "threshold": threshold, "limit": limit}

        if language and join_language:
            where_parts.append("language.code = :language")
            params["language"] = language
        elif language and not join_language:
            print(
                "Language filter ignored: schema exposes no language relationship",
                file=sys.stderr,
            )

        work_select = "COALESCE(text_work.title, '') AS work" if join_work else "'' AS work"
        lang_select = "COALESCE(language.code, '') AS lang" if join_language else "'' AS lang"

        sql = text(
            f"""
            SELECT
                {column_expr} AS text,
                COALESCE(text_segment.idx, 0) AS idx,
                {work_select},
                {lang_select},
                {similarity_expr} AS score
            FROM text_segment
            {" ".join(joins)}
            WHERE {" AND ".join(where_parts)}
            ORDER BY {similarity_expr} DESC
            LIMIT :limit
            """
        )

        rows = conn.execute(sql, params).fetchall()
        return rows


def main(argv: Optional[Sequence[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Fuzzy search over text_segment using pg_trgm similarity",
    )
    parser.add_argument("--q", "--query", dest="query", required=True, help="Search text")
    parser.add_argument(
        "--language",
        "-l",
        default="grc",
        help="Language code filter",
    )
    parser.add_argument(
        "--limit",
        "-k",
        type=int,
        default=5,
        help="Maximum number of rows to return",
    )
    parser.add_argument(
        "--threshold",
        "-t",
        type=float,
        default=0.1,
        help="Similarity threshold (0..1)",
    )
    parser.add_argument(
        "--database-url",
        dest="db_url",
        default=None,
        help="Database URL override",
    )

    args = parser.parse_args(argv)
    url = args.db_url or _db_url()
    rows = search(args.query, args.language, args.limit, args.threshold, url)

    for row in rows:
        text_value = _row_value(row, "text", 0)
        idx_value = _row_value(row, "idx", 1)
        work_value = _row_value(row, "work", 2)
        lang_value = _row_value(row, "lang", 3)
        score_value = _row_value(row, "score", 4)
        print(f"[{lang_value}] {work_value} #{idx_value}: score={score_value:.3f} :: {text_value}")

    if not rows:
        print("No results.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
