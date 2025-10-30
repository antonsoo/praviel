"""add region to user profile and track perfect lessons

Revision ID: 2b1f34b76dcb
Revises: f5c31c93de18
Create Date: 2025-02-15 12:00:00.000000
"""

from __future__ import annotations

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "2b1f34b76dcb"
down_revision = "f5c31c93de18"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("user_profile", sa.Column("region", sa.String(length=64), nullable=True))
    op.create_index("ix_user_profile_region", "user_profile", ["region"])

    op.add_column(
        "user_progress",
        sa.Column("perfect_lessons", sa.Integer(), nullable=False, server_default="0"),
    )
    # Remove server default after backfilling existing rows
    op.alter_column("user_progress", "perfect_lessons", server_default=None)


def downgrade() -> None:
    op.drop_index("ix_user_profile_region", table_name="user_profile")
    op.drop_column("user_profile", "region")
    op.drop_column("user_progress", "perfect_lessons")
