"""add_perfect_lessons_to_user_progress

Revision ID: 103232290532
Revises: 286c75c42216
Create Date: 2025-10-16 21:32:16.899633

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "103232290532"
down_revision: Union[str, Sequence[str], None] = "286c75c42216"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add perfect_lessons column to user_progress table."""
    # Check if column exists first (idempotent migration)
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    columns = [col["name"] for col in inspector.get_columns("user_progress")]

    if "perfect_lessons" not in columns:
        op.add_column(
            "user_progress", sa.Column("perfect_lessons", sa.Integer(), nullable=False, server_default="0")
        )


def downgrade() -> None:
    """Remove perfect_lessons column from user_progress table."""
    op.drop_column("user_progress", "perfect_lessons")
