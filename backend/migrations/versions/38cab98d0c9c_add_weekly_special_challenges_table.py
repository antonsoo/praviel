"""Add weekly special challenges table

Revision ID: 38cab98d0c9c
Revises: 9ce67c0564da
Create Date: 2025-10-08 20:09:50.438406

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "38cab98d0c9c"
down_revision: Union[str, Sequence[str], None] = "9ce67c0564da"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add weekly_challenge table for limited-time special challenges with 5-10x rewards."""
    op.create_table(
        "weekly_challenge",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("challenge_type", sa.String(50), nullable=False),  # weekly_warrior, perfect_week, etc.
        sa.Column("difficulty", sa.String(20), nullable=False),  # easy, medium, hard, epic
        sa.Column("title", sa.String(200), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("target_value", sa.Integer(), nullable=False),  # e.g., 7 days of daily goals
        sa.Column("current_progress", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("coin_reward", sa.Integer(), nullable=False),  # 5-10x normal rewards
        sa.Column("xp_reward", sa.Integer(), nullable=False),
        sa.Column("is_completed", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),  # Sunday midnight UTC
        sa.Column("week_start", sa.DateTime(timezone=True), nullable=False),  # Monday 00:00 UTC
        sa.Column("reward_multiplier", sa.Float(), nullable=False, server_default="5.0"),  # 5x to 10x
        sa.Column(
            "is_special_event", sa.Boolean(), nullable=False, server_default="false"
        ),  # Holiday bonuses
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name=op.f("fk_weekly_challenge_user_id_user")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_weekly_challenge")),
    )
    op.create_index(op.f("ix_weekly_challenge_user_id"), "weekly_challenge", ["user_id"], unique=False)
    op.create_index(
        "ix_weekly_challenge_active", "weekly_challenge", ["user_id", "is_completed"], unique=False
    )
    op.create_index("ix_weekly_challenge_week", "weekly_challenge", ["user_id", "week_start"], unique=False)


def downgrade() -> None:
    """Remove weekly_challenge table."""
    op.drop_index("ix_weekly_challenge_week", table_name="weekly_challenge")
    op.drop_index("ix_weekly_challenge_active", table_name="weekly_challenge")
    op.drop_index(op.f("ix_weekly_challenge_user_id"), table_name="weekly_challenge")
    op.drop_table("weekly_challenge")
