"""Add personalization fields for onboarding and chat

Revision ID: 20251029_personalization
Revises: c72c2e76959b
Create Date: 2025-10-29 23:50:00.000000

"""

from typing import Sequence, Union

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "20251029_personalization"
down_revision: Union[str, Sequence[str], None] = "c72c2e76959b"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ------------------------------------------------------------------
    # User profile enhancements (display name, pronouns, demographics)
    # ------------------------------------------------------------------
    op.add_column(
        "user_profile",
        sa.Column("display_name", sa.String(length=100), nullable=True),
    )
    op.add_column(
        "user_profile",
        sa.Column("preferred_pronouns", sa.String(length=32), nullable=True),
    )
    op.add_column(
        "user_profile",
        sa.Column("gender_identity", sa.String(length=32), nullable=True),
    )
    op.add_column(
        "user_profile",
        sa.Column("age_bracket", sa.String(length=16), nullable=True),
    )
    op.add_column(
        "user_profile",
        sa.Column("country_code", sa.String(length=2), nullable=True),
    )
    op.add_column(
        "user_profile",
        sa.Column("interests", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    )
    op.add_column(
        "user_profile",
        sa.Column("bio", sa.Text(), nullable=True),
    )

    op.create_index(
        "ix_user_profile_country_code",
        "user_profile",
        ["country_code"],
    )

    # ------------------------------------------------------------------
    # User preference extensions (ui/ux & personalization controls)
    # ------------------------------------------------------------------
    op.add_column(
        "user_preferences",
        sa.Column("primary_language", sa.String(length=20), nullable=True),
    )
    op.add_column(
        "user_preferences",
        sa.Column("daily_goal_minutes", sa.Integer(), nullable=False, server_default="15"),
    )
    op.add_column(
        "user_preferences",
        sa.Column("sound_enabled", sa.Boolean(), nullable=False, server_default="true"),
    )
    op.add_column(
        "user_preferences",
        sa.Column("haptics_enabled", sa.Boolean(), nullable=False, server_default="true"),
    )
    op.add_column(
        "user_preferences",
        sa.Column("notifications_enabled", sa.Boolean(), nullable=False, server_default="true"),
    )
    op.add_column(
        "user_preferences",
        sa.Column("notification_time", sa.String(length=8), nullable=True),
    )
    op.add_column(
        "user_preferences",
        sa.Column("font_size", sa.Numeric(precision=4, scale=2), nullable=False, server_default="1.00"),
    )
    op.add_column(
        "user_preferences",
        sa.Column("show_translations", sa.Boolean(), nullable=False, server_default="true"),
    )
    op.add_column(
        "user_preferences",
        sa.Column("show_grammar_hints", sa.Boolean(), nullable=False, server_default="true"),
    )
    op.add_column(
        "user_preferences",
        sa.Column("tts_voice", sa.String(length=120), nullable=True),
    )
    op.add_column(
        "user_preferences",
        sa.Column("tts_speed", sa.Numeric(precision=4, scale=2), nullable=False, server_default="1.00"),
    )
    op.add_column(
        "user_preferences",
        sa.Column("persona_preferences", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    )


def downgrade() -> None:
    # ------------------------------------------------------------------
    # User preference fields
    # ------------------------------------------------------------------
    op.drop_column("user_preferences", "persona_preferences")
    op.drop_column("user_preferences", "tts_speed")
    op.drop_column("user_preferences", "tts_voice")
    op.drop_column("user_preferences", "show_grammar_hints")
    op.drop_column("user_preferences", "show_translations")
    op.drop_column("user_preferences", "font_size")
    op.drop_column("user_preferences", "notification_time")
    op.drop_column("user_preferences", "notifications_enabled")
    op.drop_column("user_preferences", "haptics_enabled")
    op.drop_column("user_preferences", "sound_enabled")
    op.drop_column("user_preferences", "daily_goal_minutes")
    op.drop_column("user_preferences", "primary_language")

    # ------------------------------------------------------------------
    # User profile fields
    # ------------------------------------------------------------------
    op.drop_index("ix_user_profile_country_code", table_name="user_profile")
    op.drop_column("user_profile", "bio")
    op.drop_column("user_profile", "interests")
    op.drop_column("user_profile", "country_code")
    op.drop_column("user_profile", "age_bracket")
    op.drop_column("user_profile", "gender_identity")
    op.drop_column("user_profile", "preferred_pronouns")
    op.drop_column("user_profile", "display_name")
