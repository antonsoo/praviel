"""Test password change endpoint."""

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.user_models import User
from app.main import app
from app.security.auth import hash_password, verify_password


@pytest.mark.asyncio
async def test_password_change_success(test_db: AsyncSession):
    """Test successful password change."""
    # Create test user
    user = User(
        username="testuser",
        email="test@example.com",
        hashed_password=hash_password("OldPassword123"),
        is_active=True,
    )
    test_db.add(user)
    await test_db.commit()
    await test_db.refresh(user)

    # Login to get token
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        login_response = await client.post(
            "/auth/login",
            json={"username_or_email": "testuser", "password": "OldPassword123"},
        )
        assert login_response.status_code == 200
        token = login_response.json()["access_token"]

        # Change password
        change_response = await client.post(
            "/auth/change-password",
            headers={"Authorization": f"Bearer {token}"},
            json={"old_password": "OldPassword123", "new_password": "NewPassword456"},
        )
        assert change_response.status_code == 200
        assert change_response.json()["message"] == "Password changed successfully"

    # Verify new password works
    await test_db.refresh(user)
    assert verify_password("NewPassword456", user.hashed_password)
    assert not verify_password("OldPassword123", user.hashed_password)


@pytest.mark.asyncio
async def test_password_change_wrong_old_password(test_db: AsyncSession):
    """Test password change with incorrect old password."""
    # Create test user
    user = User(
        username="testuser2",
        email="test2@example.com",
        hashed_password=hash_password("OldPassword123"),
        is_active=True,
    )
    test_db.add(user)
    await test_db.commit()
    await test_db.refresh(user)

    # Login to get token
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        login_response = await client.post(
            "/auth/login",
            json={"username_or_email": "testuser2", "password": "OldPassword123"},
        )
        token = login_response.json()["access_token"]

        # Try to change password with wrong old password
        change_response = await client.post(
            "/auth/change-password",
            headers={"Authorization": f"Bearer {token}"},
            json={"old_password": "WrongPassword999", "new_password": "NewPassword456"},
        )
        assert change_response.status_code == 401
        assert "Incorrect current password" in change_response.json()["detail"]

    # Verify password unchanged
    await test_db.refresh(user)
    assert verify_password("OldPassword123", user.hashed_password)


@pytest.mark.asyncio
async def test_password_change_weak_new_password(test_db: AsyncSession):
    """Test password change with weak new password."""
    user = User(
        username="testuser3",
        email="test3@example.com",
        hashed_password=hash_password("OldPassword123"),
        is_active=True,
    )
    test_db.add(user)
    await test_db.commit()
    await test_db.refresh(user)

    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        login_response = await client.post(
            "/auth/login",
            json={"username_or_email": "testuser3", "password": "OldPassword123"},
        )
        token = login_response.json()["access_token"]

        # Try weak password (no uppercase)
        response = await client.post(
            "/auth/change-password",
            headers={"Authorization": f"Bearer {token}"},
            json={"old_password": "OldPassword123", "new_password": "weakpassword123"},
        )
        assert response.status_code == 422  # Validation error
