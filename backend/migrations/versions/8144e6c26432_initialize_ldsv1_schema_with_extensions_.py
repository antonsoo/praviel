from alembic import op

# revision identifiers, used by Alembic.
revision = "8144e6c26432"
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")
    op.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm")


def downgrade():
    # Note: dropping may fail if anything depends on these extensions; safe path is no-op.
    # Uncomment only if you really need to drop:
    # op.execute("DROP EXTENSION IF EXISTS pg_trgm")
    # op.execute("DROP EXTENSION IF EXISTS vector")
    pass
