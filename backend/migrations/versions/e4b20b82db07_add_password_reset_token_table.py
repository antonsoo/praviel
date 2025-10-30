"""add password reset token table

Revision ID: e4b20b82db07
Revises: d3a30a71ca06
Create Date: 2025-10-07 16:00:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "e4b20b82db07"
down_revision: Union[str, None] = "d3a30a71ca06"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add password_reset_token table for persistent token storage."""
    op.create_table(
        "password_reset_token",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("token", sa.String(length=255), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_password_reset_token_token"), "password_reset_token", ["token"], unique=True)
    op.create_index(
        op.f("ix_password_reset_token_user_id"), "password_reset_token", ["user_id"], unique=False
    )


def downgrade() -> None:
    """Remove password_reset_token table."""
    op.drop_index(op.f("ix_password_reset_token_user_id"), table_name="password_reset_token")
    op.drop_index(op.f("ix_password_reset_token_token"), table_name="password_reset_token")
    op.drop_table("password_reset_token")
