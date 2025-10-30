"""add_check_constraints

Revision ID: b2686b3025d2
Revises: 211231d6b6f2
Create Date: 2025-10-06 11:12:56.869522

"""

from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "b2686b3025d2"
down_revision: Union[str, Sequence[str], None] = "211231d6b6f2"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Add CHECK constraints for data validation.

    Based on actual database column names:
    - user_progress has: streak_days, max_streak (NOT current_streak, longest_streak)
    - text_segment has no position column
    """
    # User progress constraints - XP and level cannot be negative
    op.create_check_constraint("user_progress_xp_total_positive", "user_progress", "xp_total >= 0")
    op.create_check_constraint("user_progress_level_positive", "user_progress", "level >= 0")
    op.create_check_constraint("user_progress_streak_days_nonnegative", "user_progress", "streak_days >= 0")
    op.create_check_constraint("user_progress_max_streak_nonnegative", "user_progress", "max_streak >= 0")
    op.create_check_constraint(
        "user_progress_totals_nonnegative",
        "user_progress",
        "total_lessons >= 0 AND total_exercises >= 0 AND total_time_minutes >= 0",
    )

    # User email should be valid format (basic check)
    op.create_check_constraint(
        "user_email_format", "user", "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'"
    )


def downgrade() -> None:
    """Remove CHECK constraints."""
    op.drop_constraint("user_email_format", "user", type_="check")
    op.drop_constraint("user_progress_totals_nonnegative", "user_progress", type_="check")
    op.drop_constraint("user_progress_max_streak_nonnegative", "user_progress", type_="check")
    op.drop_constraint("user_progress_streak_days_nonnegative", "user_progress", type_="check")
    op.drop_constraint("user_progress_level_positive", "user_progress", type_="check")
    op.drop_constraint("user_progress_xp_total_positive", "user_progress", type_="check")
