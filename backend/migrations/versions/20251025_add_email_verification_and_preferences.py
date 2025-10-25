"""Add email verification and notification preferences

Revision ID: 20251025_email_prefs
Revises: 20251025_profile_visibility
Create Date: 2025-10-25

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '20251025_email_prefs'
down_revision: Union[str, None] = '20251025_profile_visibility'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add email_verified to user table
    op.add_column('user', sa.Column('email_verified', sa.Boolean(), nullable=False, server_default='false'))

    # Create email_verification_token table
    op.create_table(
        'email_verification_token',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('user_id', sa.Integer(), nullable=False),
        sa.Column('token', sa.String(length=255), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('used_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['user.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('token')
    )
    op.create_index('ix_email_verification_token_user_id', 'email_verification_token', ['user_id'])
    op.create_index('ix_email_verification_token_token', 'email_verification_token', ['token'])

    # Add email notification preferences to user_preferences table
    op.add_column('user_preferences', sa.Column('email_streak_reminders', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('user_preferences', sa.Column('email_srs_reminders', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('user_preferences', sa.Column('email_achievement_notifications', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('user_preferences', sa.Column('email_weekly_digest', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('user_preferences', sa.Column('email_onboarding_series', sa.Boolean(), nullable=False, server_default='true'))
    op.add_column('user_preferences', sa.Column('email_new_content_alerts', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('user_preferences', sa.Column('email_social_notifications', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('user_preferences', sa.Column('email_re_engagement', sa.Boolean(), nullable=False, server_default='true'))

    # SRS reminder timing preference (hour of day, 0-23)
    op.add_column('user_preferences', sa.Column('srs_reminder_time', sa.Integer(), nullable=False, server_default='9'))

    # Streak reminder timing preference (hour of day, 0-23)
    op.add_column('user_preferences', sa.Column('streak_reminder_time', sa.Integer(), nullable=False, server_default='18'))

    # Onboarding tracking
    op.add_column('user_preferences', sa.Column('onboarding_day1_sent', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('user_preferences', sa.Column('onboarding_day3_sent', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('user_preferences', sa.Column('onboarding_day7_sent', sa.Boolean(), nullable=False, server_default='false'))

    # Last reminder sent timestamps (to prevent duplicates)
    op.add_column('user_preferences', sa.Column('last_streak_reminder_sent', sa.DateTime(timezone=True), nullable=True))
    op.add_column('user_preferences', sa.Column('last_srs_reminder_sent', sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    # Remove preferences columns
    op.drop_column('user_preferences', 'last_srs_reminder_sent')
    op.drop_column('user_preferences', 'last_streak_reminder_sent')
    op.drop_column('user_preferences', 'onboarding_day7_sent')
    op.drop_column('user_preferences', 'onboarding_day3_sent')
    op.drop_column('user_preferences', 'onboarding_day1_sent')
    op.drop_column('user_preferences', 'streak_reminder_time')
    op.drop_column('user_preferences', 'srs_reminder_time')
    op.drop_column('user_preferences', 'email_re_engagement')
    op.drop_column('user_preferences', 'email_social_notifications')
    op.drop_column('user_preferences', 'email_new_content_alerts')
    op.drop_column('user_preferences', 'email_onboarding_series')
    op.drop_column('user_preferences', 'email_weekly_digest')
    op.drop_column('user_preferences', 'email_achievement_notifications')
    op.drop_column('user_preferences', 'email_srs_reminders')
    op.drop_column('user_preferences', 'email_streak_reminders')

    # Drop email verification token table
    op.drop_index('ix_email_verification_token_token', table_name='email_verification_token')
    op.drop_index('ix_email_verification_token_user_id', table_name='email_verification_token')
    op.drop_table('email_verification_token')

    # Remove email_verified from user
    op.drop_column('user', 'email_verified')
