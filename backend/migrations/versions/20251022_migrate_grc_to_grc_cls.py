"""Migrate language code from 'grc' to 'grc-cls' for Classical Greek

Revision ID: 20251022_grc_cls
Revises: cdae5ec4a2e9
Create Date: 2025-10-22

This migration updates the language code for Classical Greek from 'grc' to 'grc-cls'
to maintain consistency with Koine Greek ('grc-koi') and future Greek variants.

BREAKING CHANGE: This will affect all existing users with Classical Greek data.

Tables affected:
- language (primary key change)
- user_vocabulary (language_code field)
- user_proficiency (language_code field)
- vocabulary_mastery_timeline (language_code field)
- generated_vocabulary (language_code field)
"""

import sqlalchemy as sa
from alembic import op

# revision identifiers, used by Alembic.
revision = "20251022_grc_cls"
down_revision = "cdae5ec4a2e9"
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Migrate 'grc' to 'grc-cls' across all tables."""

    # Use a connection to execute raw SQL for data updates
    connection = op.get_bind()

    # Helper function to check if a table exists
    def table_exists(table_name: str) -> bool:
        result = connection.execute(
            sa.text(
                "SELECT EXISTS (SELECT FROM information_schema.tables "
                "WHERE table_schema = 'public' AND table_name = :name)"
            ),
            {"name": table_name},
        )
        return result.scalar()

    # 1. Update language table (if exists)
    if table_exists("language"):
        connection.execute(sa.text("UPDATE language SET code = 'grc-cls' WHERE code = 'grc'"))
        print("Updated language table")

    # 2. Update user_vocabulary table (if exists)
    if table_exists("user_vocabulary"):
        connection.execute(
            sa.text("UPDATE user_vocabulary SET language_code = 'grc-cls' WHERE language_code = 'grc'")
        )
        print("Updated user_vocabulary table")

    # 3. Update user_proficiency table (if exists)
    if table_exists("user_proficiency"):
        connection.execute(
            sa.text("UPDATE user_proficiency SET language_code = 'grc-cls' WHERE language_code = 'grc'")
        )
        print("Updated user_proficiency table")

    # 4. Update vocabulary_mastery_timeline table (if exists)
    if table_exists("vocabulary_mastery_timeline"):
        connection.execute(
            sa.text(
                "UPDATE vocabulary_mastery_timeline SET language_code = 'grc-cls' WHERE language_code = 'grc'"
            )
        )
        print("Updated vocabulary_mastery_timeline table")

    # 5. Update generated_vocabulary table (if exists)
    if table_exists("generated_vocabulary"):
        connection.execute(
            sa.text("UPDATE generated_vocabulary SET language_code = 'grc-cls' WHERE language_code = 'grc'")
        )
        print("Updated generated_vocabulary table")

    print("Successfully migrated 'grc' to 'grc-cls' across all existing tables")


def downgrade() -> None:
    """Rollback 'grc-cls' to 'grc' (in case needed)."""

    connection = op.get_bind()

    # Helper function to check if a table exists
    def table_exists(table_name: str) -> bool:
        result = connection.execute(
            sa.text(
                "SELECT EXISTS (SELECT FROM information_schema.tables "
                "WHERE table_schema = 'public' AND table_name = :name)"
            ),
            {"name": table_name},
        )
        return result.scalar()

    # Reverse all changes (only for tables that exist)
    if table_exists("language"):
        connection.execute(sa.text("UPDATE language SET code = 'grc' WHERE code = 'grc-cls'"))

    if table_exists("user_vocabulary"):
        connection.execute(
            sa.text("UPDATE user_vocabulary SET language_code = 'grc' WHERE language_code = 'grc-cls'")
        )

    if table_exists("user_proficiency"):
        connection.execute(
            sa.text("UPDATE user_proficiency SET language_code = 'grc' WHERE language_code = 'grc-cls'")
        )

    if table_exists("vocabulary_mastery_timeline"):
        connection.execute(
            sa.text(
                "UPDATE vocabulary_mastery_timeline SET language_code = 'grc' WHERE language_code = 'grc-cls'"
            )
        )

    if table_exists("generated_vocabulary"):
        connection.execute(
            sa.text("UPDATE generated_vocabulary SET language_code = 'grc' WHERE language_code = 'grc-cls'")
        )

    print("Successfully rolled back 'grc-cls' to 'grc'")
