"""add daily challenges and challenge streak tables

Revision ID: c7d82a4f9e15
Revises: f5c31c93de18
Create Date: 2025-10-08 20:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "c7d82a4f9e15"
down_revision: Union[str, None] = "f5c31c93de18"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add daily challenges and challenge streak tables for engagement boost."""

    # Daily Challenge table
    op.create_table(
        "daily_challenge",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("challenge_type", sa.String(length=50), nullable=False),
        sa.Column("difficulty", sa.String(length=20), nullable=False),
        sa.Column("title", sa.String(length=100), nullable=False),
        sa.Column("description", sa.String(length=255), nullable=False),
        sa.Column("target_value", sa.Integer(), nullable=False),
        sa.Column("current_progress", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("coin_reward", sa.Integer(), nullable=False),
        sa.Column("xp_reward", sa.Integer(), nullable=False),
        sa.Column("is_completed", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("is_weekend_bonus", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name=op.f("fk_daily_challenge_user_id_user")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_daily_challenge")),
    )
    op.create_index(op.f("ix_daily_challenge_user_id"), "daily_challenge", ["user_id"], unique=False)
    op.create_index(
        "ix_daily_challenge_user_active",
        "daily_challenge",
        ["user_id", "is_completed", "expires_at"],
        unique=False,
    )

    # Challenge Streak table
    op.create_table(
        "challenge_streak",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("current_streak", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("longest_streak", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_days_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column(
            "last_completion_date",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column("is_active_today", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name=op.f("fk_challenge_streak_user_id_user")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_challenge_streak")),
        sa.UniqueConstraint("user_id", name=op.f("uq_challenge_streak_user_id")),
    )
    op.create_index(op.f("ix_challenge_streak_user_id"), "challenge_streak", ["user_id"], unique=True)


def downgrade() -> None:
    """Remove daily challenges and challenge streak tables."""

    op.drop_index("ix_challenge_streak_user_id", table_name="challenge_streak")
    op.drop_table("challenge_streak")

    op.drop_index("ix_daily_challenge_user_active", table_name="daily_challenge")
    op.drop_index("ix_daily_challenge_user_id", table_name="daily_challenge")
    op.drop_table("daily_challenge")
