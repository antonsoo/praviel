"""add_xp_boost_expires_at_to_user_progress

Revision ID: 286c75c42216
Revises: ee085d991a62
Create Date: 2025-10-16 20:09:50.664709

"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "286c75c42216"
down_revision: Union[str, Sequence[str], None] = "ee085d991a62"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add xp_boost_expires_at column to user_progress table."""
    op.add_column(
        "user_progress", sa.Column("xp_boost_expires_at", sa.DateTime(timezone=True), nullable=True)
    )


def downgrade() -> None:
    """Remove xp_boost_expires_at column from user_progress table."""
    op.drop_column("user_progress", "xp_boost_expires_at")
