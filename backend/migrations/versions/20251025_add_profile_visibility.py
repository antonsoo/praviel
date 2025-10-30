"""Add profile visibility setting to user profiles

Revision ID: 20251025_profile_visibility
Revises: 20251022_grc_cls
Create Date: 2025-10-25 09:15:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20251025_profile_visibility"
down_revision: Union[str, None] = "20251022_grc_cls"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "user_profile",
        sa.Column("profile_visibility", sa.String(length=20), nullable=False, server_default="friends"),
    )
    op.create_check_constraint(
        "ck_user_profile_visibility",
        "user_profile",
        "profile_visibility IN ('public', 'friends', 'private')",
    )
    op.create_index(
        "ix_user_profile_profile_visibility",
        "user_profile",
        ["profile_visibility"],
    )


def downgrade() -> None:
    op.drop_index("ix_user_profile_profile_visibility", table_name="user_profile")
    op.drop_constraint("ck_user_profile_visibility", "user_profile", type_="check")
    op.drop_column("user_profile", "profile_visibility")
