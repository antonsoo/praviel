"""Pytest fixtures for authentication testing.

Provides test client and database session fixtures for auth tests.
"""

from __future__ import annotations

from typing import AsyncGenerator

import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.db.engine import create_asyncpg_engine
from app.db.models import Base as CoreBase
from app.db.user_models import Base as UserBase
from app.main import app

# Use a separate test database (matches docker-compose.yml settings: app:app on port 5433)
TEST_DATABASE_URL = "postgresql+asyncpg://app:app@localhost:5433/ancient_languages_test"

# Test engine and session factory
test_engine = create_asyncpg_engine(TEST_DATABASE_URL, echo=False, future=True, pool_pre_ping=True)
TestSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
)


@pytest_asyncio.fixture(scope="function", autouse=True)
async def _create_tables():
    """Ensure database tables exist before any tests run."""
    # Create extensions - each in its own transaction to avoid abort propagation
    try:
        async with test_engine.connect() as conn:
            # Try to create vector extension
            try:
                await conn.execute(text("CREATE EXTENSION IF NOT EXISTS vector"))
                await conn.commit()
            except Exception:
                # Vector extension not available - this is OK for CI environments
                await conn.rollback()

            # Try to create pg_trgm extension
            try:
                await conn.execute(text("CREATE EXTENSION IF NOT EXISTS pg_trgm"))
                await conn.commit()
            except Exception:
                # pg_trgm extension not available - this is OK for some CI environments
                await conn.rollback()
    except Exception as exc:
        pytest.skip(f"Test PostgreSQL instance unavailable: {exc}")
        return

    # Create tables in transaction that commits
    async with test_engine.begin() as conn:
        try:
            await conn.run_sync(CoreBase.metadata.create_all)
            await conn.run_sync(UserBase.metadata.create_all)
        except Exception as e:
            if "already exists" not in str(e):
                raise
        # Transaction auto-commits on successful exit

    yield


@pytest_asyncio.fixture(scope="function")
async def session() -> AsyncGenerator[AsyncSession, None]:
    """Provide a database session for tests.

    Each test gets a fresh session.
    """
    async with TestSessionLocal() as session:
        yield session
        await session.rollback()


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

    # Use transport parameter for newer httpx versions
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
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
    from app.db.user_models import User, UserProfile, UserProgress
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
    profile = UserProfile(user_id=user.id, region="USA")
    session.add(profile)

    progress = UserProgress(user_id=user.id, xp_total=800, level=8)
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
