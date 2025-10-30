"""add social features and leaderboard tables

Revision ID: f5c31c93de18
Revises: e4b20b82db07
Create Date: 2025-10-08 12:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "f5c31c93de18"
down_revision: Union[str, None] = "e4b20b82db07"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add social features tables: friendship, challenges, leaderboard, power-ups."""

    # Friendship table
    op.create_table(
        "friendship",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("friend_id", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("initiated_by_user_id", sa.Integer(), nullable=False),
        sa.Column("accepted_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name=op.f("fk_friendship_user_id_user")),
        sa.ForeignKeyConstraint(["friend_id"], ["user.id"], name=op.f("fk_friendship_friend_id_user")),
        sa.ForeignKeyConstraint(
            ["initiated_by_user_id"], ["user.id"], name=op.f("fk_friendship_initiated_by_user_id_user")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_friendship")),
        sa.UniqueConstraint("user_id", "friend_id", name="uq_friendship"),
    )
    op.create_index(op.f("ix_friendship_user_id"), "friendship", ["user_id"], unique=False)
    op.create_index(op.f("ix_friendship_friend_id"), "friendship", ["friend_id"], unique=False)
    op.create_index("ix_friendship_user_status", "friendship", ["user_id", "status"], unique=False)

    # Friend Challenge table
    op.create_table(
        "friend_challenge",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("initiator_user_id", sa.Integer(), nullable=False),
        sa.Column("opponent_user_id", sa.Integer(), nullable=False),
        sa.Column("challenge_type", sa.String(length=50), nullable=False),
        sa.Column("target_value", sa.Integer(), nullable=False),
        sa.Column("initiator_progress", sa.Integer(), nullable=False),
        sa.Column("opponent_progress", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("winner_user_id", sa.Integer(), nullable=True),
        sa.Column("starts_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(
            ["initiator_user_id"], ["user.id"], name=op.f("fk_friend_challenge_initiator_user_id_user")
        ),
        sa.ForeignKeyConstraint(
            ["opponent_user_id"], ["user.id"], name=op.f("fk_friend_challenge_opponent_user_id_user")
        ),
        sa.ForeignKeyConstraint(
            ["winner_user_id"], ["user.id"], name=op.f("fk_friend_challenge_winner_user_id_user")
        ),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_friend_challenge")),
    )
    op.create_index(
        op.f("ix_friend_challenge_initiator_user_id"), "friend_challenge", ["initiator_user_id"], unique=False
    )
    op.create_index(
        op.f("ix_friend_challenge_opponent_user_id"), "friend_challenge", ["opponent_user_id"], unique=False
    )
    op.create_index("ix_challenge_status", "friend_challenge", ["status"], unique=False)
    op.create_index(
        "ix_challenge_participants",
        "friend_challenge",
        ["initiator_user_id", "opponent_user_id"],
        unique=False,
    )

    # Leaderboard Entry table
    op.create_table(
        "leaderboard_entry",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("board_type", sa.String(length=20), nullable=False),
        sa.Column("region", sa.String(length=50), nullable=True),
        sa.Column("rank", sa.Integer(), nullable=False),
        sa.Column("xp_total", sa.Integer(), nullable=False),
        sa.Column("level", sa.Integer(), nullable=False),
        sa.Column(
            "calculated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False
        ),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name=op.f("fk_leaderboard_entry_user_id_user")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_leaderboard_entry")),
    )
    op.create_index(op.f("ix_leaderboard_entry_user_id"), "leaderboard_entry", ["user_id"], unique=False)
    op.create_index(
        op.f("ix_leaderboard_entry_board_type"), "leaderboard_entry", ["board_type"], unique=False
    )
    op.create_index(
        op.f("ix_leaderboard_entry_calculated_at"), "leaderboard_entry", ["calculated_at"], unique=False
    )
    op.create_index("ix_leaderboard_type_rank", "leaderboard_entry", ["board_type", "rank"], unique=False)
    op.create_index("ix_leaderboard_user_type", "leaderboard_entry", ["user_id", "board_type"], unique=False)
    op.create_index(
        "ix_leaderboard_region", "leaderboard_entry", ["board_type", "region", "rank"], unique=False
    )

    # Power-Up Inventory table
    op.create_table(
        "power_up_inventory",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("power_up_type", sa.String(length=50), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("active_count", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name=op.f("fk_power_up_inventory_user_id_user")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_power_up_inventory")),
        sa.UniqueConstraint("user_id", "power_up_type", name="uq_user_powerup"),
    )
    op.create_index(op.f("ix_power_up_inventory_user_id"), "power_up_inventory", ["user_id"], unique=False)

    # Power-Up Usage table
    op.create_table(
        "power_up_usage",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("power_up_type", sa.String(length=50), nullable=False),
        sa.Column(
            "activated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False
        ),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name=op.f("fk_power_up_usage_user_id_user")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_power_up_usage")),
    )
    op.create_index(op.f("ix_power_up_usage_user_id"), "power_up_usage", ["user_id"], unique=False)
    op.create_index(
        op.f("ix_power_up_usage_power_up_type"), "power_up_usage", ["power_up_type"], unique=False
    )
    op.create_index("ix_powerup_usage_active", "power_up_usage", ["user_id", "is_active"], unique=False)


def downgrade() -> None:
    """Remove social features tables."""
    op.drop_table("power_up_usage")
    op.drop_table("power_up_inventory")
    op.drop_table("leaderboard_entry")
    op.drop_table("friend_challenge")
    op.drop_table("friendship")
