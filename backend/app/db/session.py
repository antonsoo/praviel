from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings
from app.db.engine import create_asyncpg_engine


def _validate_async_url(url: str) -> str:
    if "+asyncpg" not in url:
        raise RuntimeError(
            "SessionLocal requires an asyncpg driver (postgresql+asyncpg://...). "
            "Set DATABASE_URL accordingly or use DATABASE_URL_SYNC for sync tasks."
        )
    return url


class Base(DeclarativeBase):
    pass


database_url = _validate_async_url(settings.DATABASE_URL)

# Database connection pool configuration (environment-configurable)
# For Railway/Heroku free tier: pool_size=5-10 is recommended
# For production with dedicated DB: pool_size=20-50
_pool_size = getattr(settings, "DB_POOL_SIZE", 5)
_max_overflow = getattr(settings, "DB_MAX_OVERFLOW", 5)
_pool_recycle = getattr(settings, "DB_POOL_RECYCLE", 3600)

# Detect if using Neon's pooled connection (PgBouncer)
# Pooled connections have "-pooler" in the hostname
_is_pooled_connection = "-pooler" in database_url.lower()

# PgBouncer compatibility: Disable prepared statements for pooled connections
# This prevents "password authentication failed" errors caused by prepared statement conflicts
# See: https://github.com/sqlalchemy/sqlalchemy/issues/6467
_connect_args = {}
if _is_pooled_connection:
    _connect_args.update(
        {
            "statement_cache_size": 0,  # Disable asyncpg prepared statement cache
            "prepared_statement_cache_size": 0,  # Disable protocol-level prepared statements
        }
    )
    import logging

    logging.getLogger("app.db.session").info(
        "Detected pooled connection (-pooler in hostname). "
        "Disabled prepared statements for PgBouncer compatibility."
    )

engine = create_asyncpg_engine(
    database_url,
    pool_pre_ping=True,  # Verify connections before using (prevents "server closed connection" errors)
    pool_size=_pool_size,  # Number of permanent connections
    max_overflow=_max_overflow,  # Additional connections when pool is full
    pool_recycle=_pool_recycle,  # Recycle connections after N seconds (prevents stale connections)
    pool_timeout=30,  # Wait up to 30s for a connection from pool
    echo=False,
    connect_args=_connect_args,  # Pass asyncpg-specific connection arguments
)
SessionLocal = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)


async def get_db():
    """FastAPI dependency to get database session."""
    async with SessionLocal() as s:
        yield s


# Alias for consistency with router imports
get_session = get_db
