"""Ensure GIN trigram index on text_segment.text_fold."""

from __future__ import annotations

from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy import text

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "3a1c83d19243"
down_revision: Union[str, Sequence[str], None] = "3c0e8fb40e2c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

INDEX_NAME = "ix_text_segment_text_fold_trgm"


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    indexes = {idx["name"] for idx in inspector.get_indexes("text_segment")}
    if INDEX_NAME in indexes:
        return

    bind.execute(
        text(f"CREATE INDEX IF NOT EXISTS {INDEX_NAME} ON text_segment USING gin (text_fold gin_trgm_ops)")
    )


def downgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    indexes = {idx["name"] for idx in inspector.get_indexes("text_segment")}
    if INDEX_NAME in indexes:
        bind.execute(text(f"DROP INDEX IF EXISTS {INDEX_NAME}"))
