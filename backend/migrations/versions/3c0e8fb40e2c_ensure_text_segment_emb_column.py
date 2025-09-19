"""Ensure text_segment.emb column and vector index exist."""

from __future__ import annotations

import os
from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from pgvector.sqlalchemy import Vector
from sqlalchemy import text

# revision identifiers, used by Alembic.
revision: str = "3c0e8fb40e2c"
down_revision: Union[str, Sequence[str], None] = "a1f23b4c5d6e"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

INDEX_NAME = "ix_text_segment_emb_cosine"


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    columns = {col["name"] for col in inspector.get_columns("text_segment")}
    embed_dim = int(os.getenv("EMBED_DIM", "1536"))
    if "emb" not in columns:
        op.add_column("text_segment", sa.Column("emb", Vector(embed_dim), nullable=True))

    if not _has_vector_extension(bind):
        return

    indexes = {idx["name"] for idx in inspector.get_indexes("text_segment")}
    if INDEX_NAME not in indexes:
        bind.execute(
            text(
                f"CREATE INDEX IF NOT EXISTS {INDEX_NAME} "
                "ON text_segment USING ivfflat (emb vector_cosine_ops) WITH (lists = 100)"
            )
        )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)

    indexes = {idx["name"] for idx in inspector.get_indexes("text_segment")}
    if INDEX_NAME in indexes:
        bind.execute(text(f"DROP INDEX IF EXISTS {INDEX_NAME}"))

    columns = {col["name"] for col in inspector.get_columns("text_segment")}
    if "emb" in columns:
        op.drop_column("text_segment", "emb")


def _has_vector_extension(bind) -> bool:
    res = bind.execute(text("SELECT 1 FROM pg_extension WHERE extname = 'vector' LIMIT 1"))
    return bool(res.scalar())
