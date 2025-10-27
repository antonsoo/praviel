from alembic import op
from sqlalchemy import text

# revision identifiers, used by Alembic.
revision = "8144e6c26432"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Try to create vector extension, but continue if not available (e.g., in CI)
    bind = op.get_bind()
    try:
        bind.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
    except Exception:
        # Vector extension not available - this is OK for testing environments
        # Vector-dependent features will be skipped by later migrations
        pass

    # pg_trgm is more commonly available and required for text search
    bind.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))


def downgrade():
    # Note: dropping may fail if anything depends on these extensions; safe path is no-op.
    # Uncomment only if you really need to drop:
    # op.execute("DROP EXTENSION IF EXISTS pg_trgm")
    # op.execute("DROP EXTENSION IF EXISTS vector")
    pass
