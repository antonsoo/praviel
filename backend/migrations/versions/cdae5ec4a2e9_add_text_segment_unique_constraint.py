"""add_text_segment_unique_constraint

Revision ID: cdae5ec4a2e9
Revises: a31bf4e97248
Create Date: 2025-10-18 02:07:05.432709

"""

from typing import Sequence, Union

from alembic import op

# revision identifiers, used by Alembic.
revision: str = "cdae5ec4a2e9"
down_revision: Union[str, Sequence[str], None] = "a31bf4e97248"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    # Add unique constraint on (work_id, ref) if it doesn't exist
    op.execute("""
        DO $$
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM pg_constraint
                WHERE conname = 'uq_segment_ref'
            ) THEN
                ALTER TABLE text_segment
                ADD CONSTRAINT uq_segment_ref UNIQUE (work_id, ref);
            END IF;
        END $$;
    """)


def downgrade() -> None:
    """Downgrade schema."""
    op.execute("ALTER TABLE text_segment DROP CONSTRAINT IF EXISTS uq_segment_ref")
