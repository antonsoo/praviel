"""Pytest fixtures for authentication testing.

Provides test client and database session fixtures for auth tests.
"""

from __future__ import annotations

import asyncio
from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.db.models import Base as CoreBase
from app.db.user_models import Base as UserBase
from app.main import app

# Use a separate test database
TEST_DATABASE_URL = "postgresql+asyncpg://postgres:postgres@localhost:5432/ancient_languages_test"


@pytest.fixture(scope="session")
def event_loop():
    """Create event loop for async tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


# Test engine and session factory
test_engine = create_async_engine(TEST_DATABASE_URL, echo=False, future=True)
TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


@pytest_asyncio.fixture(scope="session", autouse=True)
async def setup_test_database():
    """Create test database schema before tests, drop after."""
    # Create all tables
    async with test_engine.begin() as conn:
        # Ensure extensions exist
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
        await conn.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))

        # Drop existing tables (clean slate)
        await conn.run_sync(UserBase.metadata.drop_all)
        await conn.run_sync(CoreBase.metadata.drop_all)

        # Create tables
        await conn.run_sync(CoreBase.metadata.create_all)
        await conn.run_sync(UserBase.metadata.create_all)

    yield

    # Cleanup after all tests
    async with test_engine.begin() as conn:
        await conn.run_sync(UserBase.metadata.drop_all)
        await conn.run_sync(CoreBase.metadata.drop_all)


@pytest_asyncio.fixture
async def session() -> AsyncGenerator[AsyncSession, None]:
    """Provide a database session for tests.

    Each test gets a fresh transaction that rolls back at the end.
    """
    async with TestSessionLocal() as session:
        async with session.begin():
            yield session
            # Rollback happens automatically when context exits


async def get_test_session_override():
    """Override dependency for database session."""
    async with TestSessionLocal() as session:
        yield session


@pytest_asyncio.fixture
async def client(session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    """Provide an async HTTP client for testing FastAPI endpoints.

    Overrides the database dependency to use test database.
    """
    from app.db.session import get_db

    # Override the database dependency
    app.dependency_overrides[get_db] = get_test_session_override

    async with AsyncClient(app=app, base_url="http://test") as ac:
        yield ac

    # Clear overrides after test
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def db_session(session: AsyncSession) -> AsyncSession:
    """Alias for session fixture to match test expectations."""
    return session


@pytest_asyncio.fixture
async def test_user(session: AsyncSession) -> dict:
    """Create a test user and return credentials."""
    from app.db.user_models import User, UserProgress
    from app.security.auth import hash_password

    # Create test user
    user = User(
        username="testuser",
        email="test@example.com",
        hashed_password=hash_password("testpass123"),
        is_active=True,
        is_superuser=False,
    )
    session.add(user)
    await session.flush()

    # Create user progress record
    progress = UserProgress(user_id=user.id)
    session.add(progress)
    await session.commit()

    return {"id": user.id, "username": "testuser", "password": "testpass123"}


@pytest_asyncio.fixture
async def auth_headers(client: AsyncClient, test_user: dict) -> dict:
    """Get auth headers with valid JWT token."""
    # Login to get token
    response = await client.post(
        "/api/v1/auth/login",
        json={
            "username_or_email": test_user["username"],
            "password": test_user["password"],
        },
    )
    assert response.status_code == 200
    data = response.json()
    token = data["access_token"]

    return {"Authorization": f"Bearer {token}"}
