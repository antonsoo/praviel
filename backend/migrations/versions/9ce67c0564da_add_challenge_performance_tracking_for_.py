"""Add challenge performance tracking for adaptive difficulty

Revision ID: 9ce67c0564da
Revises: ad5bf66ff211
Create Date: 2025-10-08 20:00:41.084231

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "9ce67c0564da"
down_revision: Union[str, Sequence[str], None] = "ad5bf66ff211"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add adaptive difficulty columns to user_progress and challenge completion tracking."""
    # Add adaptive difficulty fields to user_progress
    op.add_column(
        "user_progress",
        sa.Column("challenge_success_rate", sa.Float(), nullable=False, server_default="0.0"),
    )
    op.add_column(
        "user_progress",
        sa.Column("avg_completion_time_seconds", sa.Float(), nullable=False, server_default="0.0"),
    )
    op.add_column(
        "user_progress",
        sa.Column("preferred_difficulty", sa.String(20), nullable=False, server_default="medium"),
    )
    op.add_column(
        "user_progress",
        sa.Column("total_challenges_attempted", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "user_progress",
        sa.Column("total_challenges_completed", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "user_progress",
        sa.Column("consecutive_failures", sa.Integer(), nullable=False, server_default="0"),
    )
    op.add_column(
        "user_progress",
        sa.Column("consecutive_successes", sa.Integer(), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    """Remove adaptive difficulty columns."""
    op.drop_column("user_progress", "consecutive_successes")
    op.drop_column("user_progress", "consecutive_failures")
    op.drop_column("user_progress", "total_challenges_completed")
    op.drop_column("user_progress", "total_challenges_attempted")
    op.drop_column("user_progress", "preferred_difficulty")
    op.drop_column("user_progress", "avg_completion_time_seconds")
    op.drop_column("user_progress", "challenge_success_rate")
