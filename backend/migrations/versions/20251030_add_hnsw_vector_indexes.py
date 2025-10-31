"""Promote pgvector indexes to HNSW for fast semantic search.

Revision ID: 20251030_add_hnsw_vector_indexes
Revises: 20251029_personalization
Create Date: 2025-10-30 10:15:00.000000
"""

from __future__ import annotations

import logging
from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy import text

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20251030_add_hnsw_vector_indexes"
down_revision: Union[str, Sequence[str], None] = "20251029_personalization"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

LOGGER = logging.getLogger("alembic.hnsw")

HNSW_INDEXES: tuple[tuple[str, str, str], ...] = (
    ("text_segment", "ix_text_segment_emb_hnsw", "emb"),
    ("grammar_topic", "ix_grammar_topic_emb_hnsw", "emb"),
    ("generated_vocabulary", "ix_generated_vocabulary_emb_hnsw", "emb"),
)

LEGACY_INDEXES: tuple[tuple[str, str], ...] = (
    ("text_segment", "ix_text_segment_emb_cosine"),
)


def _has_vector_extension(bind) -> bool:
    try:
        res = bind.execute(text("SELECT 1 FROM pg_extension WHERE extname = 'vector' LIMIT 1"))
        return bool(res.scalar())
    except Exception:
        return False


def _has_hnsw_support(bind) -> bool:
    """
    pgvector 0.5+ registers an access method named 'hnsw'. If it is missing we
    fall back to the legacy IVFFlat index and treat this migration as a no-op.
    """

    try:
        res = bind.execute(text("SELECT 1 FROM pg_am WHERE amname = 'hnsw' LIMIT 1"))
        return bool(res.scalar())
    except Exception:
        return False


def _drop_index(bind, index_name: str) -> None:
    bind.execute(text(f'DROP INDEX IF EXISTS "{index_name}"'))


def _create_hnsw_index(bind, table: str, index: str, column: str) -> None:
    bind.execute(
        text(
            f'CREATE INDEX IF NOT EXISTS "{index}" '
            f'ON "{table}" USING hnsw ("{column}" vector_cosine_ops) '
            "WITH (m = 24, ef_construction = 256)"
        )
    )


def _analyze_table(bind, table: str) -> None:
    bind.execute(text(f'ANALYZE "{table}"'))


def upgrade() -> None:
    bind = op.get_bind()
    if not (_has_vector_extension(bind) and _has_hnsw_support(bind)):
        LOGGER.warning("pgvector HNSW support unavailable; skipping HNSW index migration.")
        return

    inspector = sa.inspect(bind)

    for table, legacy in LEGACY_INDEXES:
        indexes = {idx["name"] for idx in inspector.get_indexes(table)}
        if legacy in indexes:
            _drop_index(bind, legacy)

    for table, index, column in HNSW_INDEXES:
        indexes = {idx["name"] for idx in inspector.get_indexes(table)}
        if index not in indexes:
            _create_hnsw_index(bind, table, index, column)
        _analyze_table(bind, table)


def downgrade() -> None:
    bind = op.get_bind()
    if not _has_vector_extension(bind):
        return

    for table, index, _column in HNSW_INDEXES:
        _drop_index(bind, index)

    # Restore the legacy IVFFlat index to maintain compatibility with older deployments
    bind.execute(
        text(
            "CREATE INDEX IF NOT EXISTS ix_text_segment_emb_cosine "
            "ON text_segment USING ivfflat (emb vector_cosine_ops) WITH (lists = 100)"
        )
    )
    _analyze_table(bind, "text_segment")
