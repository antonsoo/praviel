from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

from app.core.config import settings


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

engine = create_async_engine(
    database_url,
    pool_pre_ping=True,  # Verify connections before using
    pool_size=20,  # Number of permanent connections
    max_overflow=10,  # Additional connections when pool is full
    pool_recycle=3600,  # Recycle connections after 1 hour (prevents stale connections)
    echo=False,
)
SessionLocal = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)


async def get_db():
    """FastAPI dependency to get database session."""
    async with SessionLocal() as s:
        yield s


# Alias for consistency with router imports
get_session = get_db
