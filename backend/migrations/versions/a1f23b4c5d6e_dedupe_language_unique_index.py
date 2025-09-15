"""Drop redundant unique index on language.code (keep named constraint)."""

from alembic import op

# Revision identifiers, used by Alembic.
revision = "a1f23b4c5d6e"
down_revision = "94f9767a55ea"
branch_labels = None
depends_on = None


def upgrade():
    # Using raw SQL is the most reliable with Alembic for index-only changes
    op.execute("DROP INDEX IF EXISTS public.ix_language_code")


def downgrade():
    # Recreate the unique index if rolling back
    op.execute(
        "CREATE UNIQUE INDEX IF NOT EXISTS ix_language_code "
        "ON public.language (code)"
    )
