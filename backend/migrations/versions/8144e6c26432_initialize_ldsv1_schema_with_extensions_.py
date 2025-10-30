from sqlalchemy import text

from alembic import op

# revision identifiers, used by Alembic.
revision = "8144e6c26432"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Create extensions outside of transaction to avoid abort propagation on failure
    # Using autocommit_block ensures each statement commits independently
    # This is critical because CREATE EXTENSION may fail in CI environments where
    # extension packages are not installed (e.g., pgvector, pg_trgm)

    with op.get_context().autocommit_block():
        # Try to create vector extension (may not be available in all environments)
        try:
            op.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        except Exception:
            # Vector extension not available - this is OK for testing environments
            # Vector-dependent features will be skipped by later migrations
            pass

        # Try to create pg_trgm extension for text search
        try:
            op.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
        except Exception:
            # pg_trgm extension not available - this is OK for some CI environments
            # Text search features may be limited
            pass


def downgrade():
    # Note: dropping may fail if anything depends on these extensions; safe path is no-op.
    # Uncomment only if you really need to drop:
    # op.execute("DROP EXTENSION IF EXISTS pg_trgm")
    # op.execute("DROP EXTENSION IF EXISTS vector")
    pass
