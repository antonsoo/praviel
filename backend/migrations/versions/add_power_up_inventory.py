"""add power-up inventory columns to user_progress

Revision ID: 3c4d5e6f7g8h
Revises: 2b1f34b76dcb
Create Date: 2025-01-11 18:00:00.000000

"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "3c4d5e6f7g8h"
down_revision = "2b1f34b76dcb"
branch_labels = None
depends_on = None


def upgrade():
    # Add power-up inventory columns to user_progress table
    op.add_column("user_progress", sa.Column("xp_boost_2x", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("user_progress", sa.Column("xp_boost_5x", sa.Integer(), nullable=False, server_default="0"))
    op.add_column("user_progress", sa.Column("time_warp", sa.Integer(), nullable=False, server_default="0"))
    op.add_column(
        "user_progress", sa.Column("coin_doubler", sa.Integer(), nullable=False, server_default="0")
    )
    op.add_column(
        "user_progress", sa.Column("perfect_protection", sa.Integer(), nullable=False, server_default="0")
    )


def downgrade():
    # Remove power-up inventory columns
    op.drop_column("user_progress", "perfect_protection")
    op.drop_column("user_progress", "coin_doubler")
    op.drop_column("user_progress", "time_warp")
    op.drop_column("user_progress", "xp_boost_5x")
    op.drop_column("user_progress", "xp_boost_2x")
