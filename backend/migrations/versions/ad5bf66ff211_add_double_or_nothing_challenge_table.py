"""Add double or nothing challenge table

Revision ID: ad5bf66ff211
Revises: f385f924bf7c
Create Date: 2025-10-08 19:45:52.572960

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "ad5bf66ff211"
down_revision: Union[str, Sequence[str], None] = "f385f924bf7c"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add double_or_nothing table for 7-day commitment challenges."""
    op.create_table(
        "double_or_nothing",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("wager_amount", sa.Integer(), nullable=False),  # Coins wagered
        sa.Column("days_required", sa.Integer(), nullable=False),  # Usually 7, 14, or 30
        sa.Column("days_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("is_won", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("is_lost", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("started_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], name=op.f("fk_double_or_nothing_user_id_user")),
        sa.PrimaryKeyConstraint("id", name=op.f("pk_double_or_nothing")),
    )
    op.create_index(op.f("ix_double_or_nothing_user_id"), "double_or_nothing", ["user_id"], unique=False)
    op.create_index(
        "ix_double_or_nothing_active", "double_or_nothing", ["user_id", "is_active"], unique=False
    )


def downgrade() -> None:
    """Remove double_or_nothing table."""
    op.drop_index("ix_double_or_nothing_active", table_name="double_or_nothing")
    op.drop_index(op.f("ix_double_or_nothing_user_id"), table_name="double_or_nothing")
    op.drop_table("double_or_nothing")
