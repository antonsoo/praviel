#!/usr/bin/env python3
"""Create a test user for development and testing."""

import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.core.config import settings
from app.db.engine import create_asyncpg_engine
from app.db.user_models import User
from app.security.password import get_password_hash
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import sessionmaker


async def create_test_user():
    """Create a test user with known credentials."""
    engine = create_asyncpg_engine(settings.DATABASE_URL, echo=False)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async with async_session() as session:
        # Check if user exists
        result = await session.execute(select(User).where(User.email == "test@praviel.com"))
        existing_user = result.scalar_one_or_none()

        if existing_user:
            print(f"Test user already exists: {existing_user.email} (ID: {existing_user.id})")
            return existing_user.id

        # Create new user
        hashed_password = get_password_hash("testpassword123")
        new_user = User(
            email="test@praviel.com",
            username="testuser",
            hashed_password=hashed_password,
            is_active=True,
            is_verified=True,
        )

        session.add(new_user)
        await session.commit()
        await session.refresh(new_user)

        print("✓ Created test user:")
        print(f"  Email: {new_user.email}")
        print(f"  Username: {new_user.username}")
        print("  Password: testpassword123")
        print(f"  User ID: {new_user.id}")
        print("\nUse these credentials to test authentication and gamification endpoints.")

        return new_user.id

    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(create_test_user())
