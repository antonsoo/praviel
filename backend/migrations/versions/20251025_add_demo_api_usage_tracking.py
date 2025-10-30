"""Add demo API usage tracking table

Revision ID: 20251025_demo_usage
Revises: 20251025_profile_visibility
Create Date: 2025-10-25 12:00:00.000000

Tracks demo API usage per user per provider for free tier rate limiting.
"""

import sqlalchemy as sa

from alembic import op

# revision identifiers, used by Alembic.
revision = "20251025_demo_usage"
down_revision = "20251025_profile_visibility"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add demo_api_usage table for tracking free tier usage (supports both users and guests)."""
    op.create_table(
        "demo_api_usage",
        sa.Column("id", sa.Integer(), nullable=False),
        # Either user_id OR ip_address must be set (for authenticated vs guest users)
        sa.Column("user_id", sa.Integer(), nullable=True),  # Nullable for guest users
        sa.Column("ip_address", sa.String(length=45), nullable=True),  # For guest users (IPv6 max length)
        sa.Column("provider", sa.String(length=50), nullable=False),
        # Daily tracking
        sa.Column("requests_today", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("tokens_today", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("daily_reset_at", sa.DateTime(timezone=True), nullable=False),
        # Weekly tracking
        sa.Column("requests_this_week", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("tokens_this_week", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("weekly_reset_at", sa.DateTime(timezone=True), nullable=False),
        # Metadata
        sa.Column("last_request_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        # Unique constraints for both authenticated and guest users
        sa.UniqueConstraint("user_id", "provider", name="uq_demo_usage_user_provider"),
        sa.UniqueConstraint("ip_address", "provider", name="uq_demo_usage_ip_provider"),
    )
    # Indexes for common queries
    op.create_index("ix_demo_api_usage_user_id", "demo_api_usage", ["user_id"])
    op.create_index("ix_demo_api_usage_ip_address", "demo_api_usage", ["ip_address"])
    op.create_index("ix_demo_api_usage_provider", "demo_api_usage", ["provider"])
    op.create_index("ix_demo_api_usage_user_provider", "demo_api_usage", ["user_id", "provider"])
    op.create_index("ix_demo_api_usage_ip_provider", "demo_api_usage", ["ip_address", "provider"])


def downgrade() -> None:
    """Remove demo_api_usage table."""
    op.drop_index("ix_demo_api_usage_ip_provider", table_name="demo_api_usage")
    op.drop_index("ix_demo_api_usage_user_provider", table_name="demo_api_usage")
    op.drop_index("ix_demo_api_usage_provider", table_name="demo_api_usage")
    op.drop_index("ix_demo_api_usage_ip_address", table_name="demo_api_usage")
    op.drop_index("ix_demo_api_usage_user_id", table_name="demo_api_usage")
    op.drop_table("demo_api_usage")
