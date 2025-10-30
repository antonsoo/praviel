"""merge heads

Revision ID: ee085d991a62
Revises: 38cab98d0c9c, 3c4d5e6f7g8h
Create Date: 2025-10-11 21:23:54.642964

"""

from typing import Sequence, Union

# revision identifiers, used by Alembic.
revision: str = "ee085d991a62"
down_revision: Union[str, Sequence[str], None] = ("38cab98d0c9c", "3c4d5e6f7g8h")
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
