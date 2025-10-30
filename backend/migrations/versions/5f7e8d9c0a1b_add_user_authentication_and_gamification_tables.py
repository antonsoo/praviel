"""add_user_authentication_and_gamification_tables

Revision ID: 5f7e8d9c0a1b
Revises: a1f23b4c5d6e
Create Date: 2025-10-05 00:00:00.000000

This migration adds comprehensive user authentication, profile management,
and gamification tracking tables to support the Ancient Languages learning platform.

Tables created:
- user: Core user authentication
- user_profile: Optional profile information
- user_api_config: BYOK API key management
- user_preferences: App preferences and defaults
- user_progress: Overall progress metrics (XP, level, streak)
- user_skill: Per-topic skill tracking (Elo ratings)
- user_achievement: Badges and milestones
- user_text_stats: Per-work reading statistics
- user_srs_card: SRS flashcard state (FSRS algorithm)
- learning_event: Event log for analytics
- user_quest: Active and completed quests/challenges
"""

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

# revision identifiers, used by Alembic.
revision = "5f7e8d9c0a1b"
down_revision = "a1f23b4c5d6e"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create user table
    op.create_table(
        "user",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("username", sa.String(length=50), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("hashed_password", sa.String(length=255), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
        sa.Column("is_superuser", sa.Boolean(), nullable=False, server_default="false"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_user_username", "user", ["username"], unique=True)
    op.create_index("ix_user_email", "user", ["email"], unique=True)

    # Create user_profile table
    op.create_table(
        "user_profile",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("real_name", sa.String(length=100), nullable=True),
        sa.Column("discord_username", sa.String(length=50), nullable=True),
        sa.Column("phone", sa.String(length=20), nullable=True),
        sa.Column("payment_provider", sa.String(length=50), nullable=True),
        sa.Column("payment_customer_id", sa.String(length=255), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_user_profile_user_id", "user_profile", ["user_id"], unique=True)

    # Create user_api_config table
    op.create_table(
        "user_api_config",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("provider", sa.String(length=50), nullable=False),
        sa.Column("encrypted_api_key", sa.Text(), nullable=False),
        sa.Column("meta", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "provider", name="uq_user_provider"),
    )
    op.create_index("ix_user_api_config_user_id", "user_api_config", ["user_id"])

    # Create user_preferences table
    op.create_table(
        "user_preferences",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("default_llm_provider", sa.String(length=50), nullable=True),
        sa.Column("default_chat_model", sa.String(length=100), nullable=True),
        sa.Column("default_lesson_model", sa.String(length=100), nullable=True),
        sa.Column("default_tts_model", sa.String(length=100), nullable=True),
        sa.Column("theme", sa.String(length=20), nullable=True, server_default="auto"),
        sa.Column("language_focus", sa.String(length=20), nullable=True),
        sa.Column("daily_xp_goal", sa.Integer(), nullable=False, server_default="50"),
        sa.Column("srs_daily_new_cards", sa.Integer(), nullable=False, server_default="10"),
        sa.Column("srs_daily_review_limit", sa.Integer(), nullable=False, server_default="100"),
        sa.Column("settings", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_user_preferences_user_id", "user_preferences", ["user_id"], unique=True)

    # Create user_progress table
    op.create_table(
        "user_progress",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("xp_total", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("level", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("streak_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("max_streak", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_lessons", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_exercises", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("total_time_minutes", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_lesson_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_streak_update", sa.DateTime(timezone=True), nullable=True),
        sa.Column("stats", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_user_progress_user_id", "user_progress", ["user_id"], unique=True)

    # Create user_skill table
    op.create_table(
        "user_skill",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("topic_type", sa.String(length=50), nullable=False),
        sa.Column("topic_id", sa.String(length=200), nullable=False),
        sa.Column("elo_rating", sa.Float(), nullable=False, server_default="1000.0"),
        sa.Column("accuracy", sa.Float(), nullable=True),
        sa.Column("total_attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("correct_attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_practiced_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("meta", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "topic_type", "topic_id", name="uq_user_topic"),
    )
    op.create_index("ix_user_skill_user_id", "user_skill", ["user_id"])
    op.create_index("ix_user_skill_user_topic", "user_skill", ["user_id", "topic_type"])

    # Create user_achievement table
    op.create_table(
        "user_achievement",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("achievement_type", sa.String(length=50), nullable=False),
        sa.Column("achievement_id", sa.String(length=200), nullable=False),
        sa.Column("unlocked_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("progress_current", sa.Integer(), nullable=True),
        sa.Column("progress_target", sa.Integer(), nullable=True),
        sa.Column("meta", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "achievement_type", "achievement_id", name="uq_user_achievement"),
    )
    op.create_index("ix_user_achievement_user_id", "user_achievement", ["user_id"])

    # Create user_text_stats table
    op.create_table(
        "user_text_stats",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("work_id", sa.Integer(), nullable=False),
        sa.Column("lemma_coverage_pct", sa.Float(), nullable=True),
        sa.Column("tokens_seen", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("unique_lemmas_known", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("avg_wpm", sa.Float(), nullable=True),
        sa.Column("comprehension_pct", sa.Float(), nullable=True),
        sa.Column("segments_completed", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_segment_ref", sa.String(length=100), nullable=True),
        sa.Column("max_hintless_run", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("stats", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["work_id"], ["text_work.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "work_id", name="uq_user_work"),
    )
    op.create_index("ix_user_text_stats_user_id", "user_text_stats", ["user_id"])
    op.create_index("ix_user_text_stats_work_id", "user_text_stats", ["work_id"])

    # Create user_srs_card table
    op.create_table(
        "user_srs_card",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("card_type", sa.String(length=50), nullable=False),
        sa.Column("content_id", sa.String(length=200), nullable=False),
        sa.Column("stability", sa.Float(), nullable=False, server_default="1.0"),
        sa.Column("difficulty", sa.Float(), nullable=False, server_default="5.0"),
        sa.Column("elapsed_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("scheduled_days", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("reps", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("lapses", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("state", sa.String(length=20), nullable=False, server_default="new"),
        sa.Column("p_recall", sa.Float(), nullable=True),
        sa.Column("due_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("last_review_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("fsrs_params", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "card_type", "content_id", name="uq_user_card"),
    )
    op.create_index("ix_user_srs_card_user_id", "user_srs_card", ["user_id"])
    op.create_index("ix_user_srs_due", "user_srs_card", ["user_id", "due_at"])
    op.create_index("ix_user_srs_state", "user_srs_card", ["user_id", "state"])

    # Create learning_event table
    op.create_table(
        "learning_event",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("event_type", sa.String(length=50), nullable=False),
        sa.Column(
            "event_timestamp", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False
        ),
        sa.Column("data", postgresql.JSONB(astext_type=sa.Text()), nullable=False),
        sa.Column("lesson_id", sa.String(length=100), nullable=True),
        sa.Column("work_id", sa.Integer(), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["work_id"], ["text_work.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_learning_event_user_id", "learning_event", ["user_id"])
    op.create_index("ix_learning_event_event_type", "learning_event", ["event_type"])
    op.create_index("ix_learning_event_user_type", "learning_event", ["user_id", "event_type"])
    op.create_index("ix_learning_event_user_time", "learning_event", ["user_id", "event_timestamp"])

    # Create user_quest table
    op.create_table(
        "user_quest",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("quest_type", sa.String(length=50), nullable=False),
        sa.Column("quest_id", sa.String(length=200), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("progress_current", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("progress_target", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="active"),
        sa.Column("started_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("xp_reward", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("coin_reward", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("achievement_reward", sa.String(length=200), nullable=True),
        sa.Column("meta", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["user.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_user_quest_user_id", "user_quest", ["user_id"])
    op.create_index("ix_user_quest_status", "user_quest", ["user_id", "status"])


def downgrade() -> None:
    op.drop_table("user_quest")
    op.drop_table("learning_event")
    op.drop_table("user_srs_card")
    op.drop_table("user_text_stats")
    op.drop_table("user_achievement")
    op.drop_table("user_skill")
    op.drop_table("user_progress")
    op.drop_table("user_preferences")
    op.drop_table("user_api_config")
    op.drop_table("user_profile")
    op.drop_table("user")
