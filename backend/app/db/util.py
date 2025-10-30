# backend/app/db/util.py
from __future__ import annotations

import os

from sqlalchemy import bindparam, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy.sql.elements import TextClause

from app.db.engine import create_asyncpg_engine

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://app:app@localhost:5433/app")

# Detect test runs in two ways: explicit env var and pytest's own marker
USE_TEST_POOL = os.getenv("TESTING") == "1" or "PYTEST_CURRENT_TEST" in os.environ

engine = create_asyncpg_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    poolclass=NullPool if USE_TEST_POOL else None,
    future=True,
)

SessionLocal = async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False, autoflush=False)


def text_with_json(sql: str, *json_param_names: str) -> TextClause:
    """
    Build a SQLAlchemy text() with selected parameters bound as PostgreSQL JSONB.
    IMPORTANT: in the SQL string, reference the parameter as `:name` (no ::jsonb cast);
    the JSONB bindparam handles the type.
    """
    stmt = text(sql)
    if json_param_names:
        stmt = stmt.bindparams(*(bindparam(n, type_=JSONB) for n in json_param_names))
    return stmt
