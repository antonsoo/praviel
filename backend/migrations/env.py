# backend/migrations/env.py
from __future__ import annotations

import os
import sys
import time
from logging.config import fileConfig
from pathlib import Path

from alembic import context
from sqlalchemy import create_engine, pool, text
from sqlalchemy.exc import OperationalError

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

# First check if orchestrate.sh detected the actual database host/port
detected_host = os.environ.get("DETECTED_DB_HOST")
detected_port = os.environ.get("DETECTED_DB_PORT")

if detected_host and detected_port:
    # Use the detected values from orchestrate.sh (most reliable)
    engine_url = f"postgresql+psycopg://app:app@{detected_host}:{detected_port}/app"
else:
    # Fallback to environment variables or config
    engine_url = (
        os.environ.get("DATABASE_URL_SYNC")  # Use sync URL if available
        or os.environ.get("DATABASE_URL")  # Fallback to main URL (for local dev)
        or config.get_main_option("sqlalchemy.url")
        or "postgresql+psycopg://app:app@localhost:5433/app"
    )

    # Railway auto-provides DATABASE_URL with asyncpg driver, but Alembic needs psycopg
    # Auto-convert if needed (when DATABASE_URL_SYNC is not explicitly set)
    if engine_url and "+asyncpg" in engine_url:
        engine_url = engine_url.replace("+asyncpg", "+psycopg")


# ------------------------------------------------------------------------------
# Database connection with retry logic for CI environments
# ------------------------------------------------------------------------------
def connect_with_retry(engine, max_retries: int = 15, retry_delay: float = 2.0):
    """Connect to database with retry logic for transient connection failures.

    In CI environments, PostgreSQL container may be accepting connections but
    still initializing internally. This function retries connection attempts
    to handle such transient failures.
    """
    last_error = None
    for attempt in range(1, max_retries + 1):
        try:
            conn = engine.connect()
            # Test the connection
            conn.execute(text("SELECT 1"))
            conn.close()
            return engine.connect()  # Return a fresh connection
        except OperationalError as e:
            last_error = e
            if attempt < max_retries:
                print(f"Database connection attempt {attempt}/{max_retries} failed: {e}")
                print(f"Retrying in {retry_delay} seconds...")
                time.sleep(retry_delay)
            else:
                print(f"Database connection failed after {max_retries} attempts")
                raise
    # Should never reach here, but satisfy type checker
    raise last_error  # type: ignore[misc]


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
    connectable = create_engine(engine_url, poolclass=pool.NullPool)

    with connect_with_retry(connectable) as connection:
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
