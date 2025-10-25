"""add revoked_token table for JWT blacklist

Revision ID: 20251024_revoked_token
Revises: 20251025_profile_visibility
Create Date: 2025-10-24

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = "20251024_revoked_token"
down_revision = "20251025_profile_visibility"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Create revoked_token table for JWT token blacklist."""
    op.create_table(
        "revoked_token",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("jti", sa.String(length=255), nullable=False),
        sa.Column("token_type", sa.String(length=20), nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("revoked_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("reason", sa.String(length=255), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("jti"),
    )

    # Create indexes for performance
    op.create_index("ix_revoked_token_user_id", "revoked_token", ["user_id"])
    op.create_index("ix_revoked_token_jti", "revoked_token", ["jti"])
    op.create_index("ix_revoked_token_expires_at", "revoked_token", ["expires_at"])


def downgrade() -> None:
    """Drop revoked_token table."""
    op.drop_index("ix_revoked_token_expires_at", "revoked_token")
    op.drop_index("ix_revoked_token_jti", "revoked_token")
    op.drop_index("ix_revoked_token_user_id", "revoked_token")
    op.drop_table("revoked_token")
