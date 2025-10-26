"""merge multiple heads

Revision ID: c72c2e76959b
Revises: 20251024_revoked_token, 20251025_demo_usage, 20251025_email_prefs
Create Date: 2025-10-26 15:37:54.573499

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c72c2e76959b'
down_revision: Union[str, Sequence[str], None] = ('20251024_revoked_token', '20251025_demo_usage', '20251025_email_prefs')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    pass


def downgrade() -> None:
    """Downgrade schema."""
    pass
