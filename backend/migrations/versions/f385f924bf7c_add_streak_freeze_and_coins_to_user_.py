"""Add streak freeze and coins to user progress

Revision ID: f385f924bf7c
Revises: 07d42b3b2e57
Create Date: 2025-10-08 19:43:46.106128

"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "f385f924bf7c"
down_revision: Union[str, Sequence[str], None] = "07d42b3b2e57"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add streak_freezes and coins columns to user_progress."""
    # Add coins column (total coins earned)
    op.add_column(
        "user_progress",
        sa.Column("coins", sa.Integer(), nullable=False, server_default="0"),
    )

    # Add streak_freezes column (number of streak freezes owned)
    op.add_column(
        "user_progress",
        sa.Column("streak_freezes", sa.Integer(), nullable=False, server_default="0"),
    )

    # Add streak_freeze_used_today flag
    op.add_column(
        "user_progress",
        sa.Column("streak_freeze_used_today", sa.Boolean(), nullable=False, server_default="false"),
    )


def downgrade() -> None:
    """Remove streak_freezes and coins columns from user_progress."""
    op.drop_column("user_progress", "streak_freeze_used_today")
    op.drop_column("user_progress", "streak_freezes")
    op.drop_column("user_progress", "coins")
