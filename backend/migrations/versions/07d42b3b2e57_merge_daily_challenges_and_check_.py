"""merge daily challenges and check constraints branches

Revision ID: 07d42b3b2e57
Revises: b2686b3025d2, c7d82a4f9e15
Create Date: 2025-10-08 19:28:59.502158

"""

from typing import Sequence, Union

# revision identifiers, used by Alembic.
revision: str = "07d42b3b2e57"
down_revision: Union[str, Sequence[str], None] = ("b2686b3025d2", "c7d82a4f9e15")
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
