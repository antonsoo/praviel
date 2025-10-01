# backend/migrations/env.py
from __future__ import annotations

import os
import sys
from logging.config import fileConfig
from pathlib import Path

from alembic import context
from sqlalchemy import create_engine, pool

# --- Path so "from app.db.models import Base" works when PYTHONPATH isn't set ---
BACKEND_DIR = Path(__file__).resolve().parents[1]  # .../backend
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

# ------------------------------------------------------------------------------
# Alembic Config
# ------------------------------------------------------------------------------
config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# ------------------------------------------------------------------------------
# Target metadata (only needed for autogenerate)
# ------------------------------------------------------------------------------
try:
    # Only needed for autogenerate; upgrade/downgrade scripts don't require it
    from app.db.models import Base  # noqa: WPS433

    target_metadata = Base.metadata
except Exception:
    # If importing models fails (e.g., pgvector not installed in this Python),
    # allow migrations to run; autogenerate will not be available.
    target_metadata = None

# ------------------------------------------------------------------------------
# Database URL: prefer DATABASE_URL_SYNC for Alembic (synchronous driver)
# ------------------------------------------------------------------------------
# Alembic migrations run synchronously, so we need a sync driver (psycopg)
# even if the main app uses async (asyncpg)
engine_url = (
    os.environ.get("DATABASE_URL_SYNC")  # Use sync URL if available
    or os.environ.get("DATABASE_URL")     # Fallback to main URL (for local dev)
    or config.get_main_option("sqlalchemy.url")
    or "postgresql+psycopg://app:app@localhost:5433/app"
)


# ------------------------------------------------------------------------------
# Offline migrations
# ------------------------------------------------------------------------------
def run_migrations_offline() -> None:
    context.configure(
        url=engine_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        include_schemas=True,
        compare_type=True,
        compare_server_default=True,
    )

    with context.begin_transaction():
        context.run_migrations()


# ------------------------------------------------------------------------------
# Online migrations (sync engine)
# ------------------------------------------------------------------------------
def run_migrations_online() -> None:
    connectable = create_engine(
        engine_url,
        poolclass=pool.NullPool,  # keep it simple for CLI runs
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            include_schemas=True,
            compare_type=True,
            compare_server_default=True,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
