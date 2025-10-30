"""merge auth and vector branches

Revision ID: d3a30a71ca06
Revises: 3a1c83d19243, 5f7e8d9c0a1b
Create Date: 2025-10-06 02:01:03.589724

"""

from typing import Sequence, Union

# revision identifiers, used by Alembic.
revision: str = "d3a30a71ca06"
down_revision: Union[str, Sequence[str], None] = ("3a1c83d19243", "5f7e8d9c0a1b")
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
