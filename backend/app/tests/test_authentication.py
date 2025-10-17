"""Tests for user authentication endpoints."""

from __future__ import annotations

import pytest
from fastapi import status
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.user_models import User, UserPreferences, UserProfile, UserProgress
from app.security.auth import create_token_pair, hash_password, verify_password


class TestPasswordHashing:
    """Test password hashing utilities."""

    def test_hash_password(self):
        """Test password hashing produces different hashes."""
        password = "TestPassword123"
        hash1 = hash_password(password)
        hash2 = hash_password(password)

        # Hashes should be different (due to salt)
        assert hash1 != hash2
        assert len(hash1) > 0

    def test_verify_password_correct(self):
        """Test password verification with correct password."""
        password = "TestPassword123"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True

    def test_verify_password_incorrect(self):
        """Test password verification with incorrect password."""
        password = "TestPassword123"
        wrong_password = "WrongPassword456"
        hashed = hash_password(password)

        assert verify_password(wrong_password, hashed) is False


class TestTokenGeneration:
    """Test JWT token generation."""

    def test_create_token_pair(self):
        """Test creating access and refresh tokens."""
        user_id = 123
        tokens = create_token_pair(user_id)

        assert tokens.access_token
        assert tokens.refresh_token
        assert tokens.token_type == "bearer"
        assert tokens.access_token != tokens.refresh_token


@pytest.mark.asyncio
class TestUserRegistration:
    """Test user registration endpoint."""

    async def test_register_success(self, client: AsyncClient, session: AsyncSession):
        """Test successful user registration."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "TestPassword123!",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["username"] == "testuser"
        assert data["email"] == "test@example.com"
        assert "password" not in data
        assert "hashed_password" not in data

        # Verify user was created in database
        result = await session.execute(select(User).where(User.username == "testuser"))
        user = result.scalar_one_or_none()
        assert user is not None
        assert user.email == "test@example.com"
        assert user.is_active is True
        assert user.is_superuser is False

        # Verify related tables were created
        result = await session.execute(select(UserProfile).where(UserProfile.user_id == user.id))
        assert result.scalar_one_or_none() is not None

        result = await session.execute(select(UserPreferences).where(UserPreferences.user_id == user.id))
        assert result.scalar_one_or_none() is not None

        result = await session.execute(select(UserProgress).where(UserProgress.user_id == user.id))
        progress = result.scalar_one_or_none()
        assert progress is not None
        assert progress.xp_total == 0
        assert progress.level == 0
        assert progress.streak_days == 0

    async def test_register_duplicate_username(self, client: AsyncClient, session: AsyncSession):
        """Test registration with duplicate username."""
        # Create first user
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "duplicate",
                "email": "user1@example.com",
                "password": "Password123!",
            },
        )

        # Try to create second user with same username
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "duplicate",
                "email": "user2@example.com",
                "password": "Password123!",
            },
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "username already registered" in response.json()["detail"].lower()

    async def test_register_duplicate_email(self, client: AsyncClient, session: AsyncSession):
        """Test registration with duplicate email."""
        # Create first user
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "user1",
                "email": "duplicate@example.com",
                "password": "Password123!",
            },
        )

        # Try to create second user with same email
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "user2",
                "email": "duplicate@example.com",
                "password": "Password123!",
            },
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "email already registered" in response.json()["detail"].lower()

    async def test_register_weak_password(self, client: AsyncClient):
        """Test registration with weak password."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "weak",  # Too short
            },
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    async def test_register_password_no_uppercase(self, client: AsyncClient):
        """Test registration with password missing uppercase."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "testpassword123",  # No uppercase
            },
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    async def test_register_password_no_lowercase(self, client: AsyncClient):
        """Test registration with password missing lowercase."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "TESTPASSWORD123",  # No lowercase
            },
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY

    async def test_register_password_no_digit(self, client: AsyncClient):
        """Test registration with password missing digit."""
        response = await client.post(
            "/api/v1/auth/register",
            json={
                "username": "testuser",
                "email": "test@example.com",
                "password": "TestPassword",  # No digit
            },
        )

        assert response.status_code == status.HTTP_422_UNPROCESSABLE_ENTITY


@pytest.mark.asyncio
class TestUserLogin:
    """Test user login endpoint."""

    async def test_login_with_username(self, client: AsyncClient, session: AsyncSession):
        """Test login with username."""
        # Register user first
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "logintest",
                "email": "login@example.com",
                "password": "LoginPassword123!",
            },
        )

        # Login
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "logintest",
                "password": "LoginPassword123!",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["token_type"] == "bearer"

    async def test_login_with_email(self, client: AsyncClient, session: AsyncSession):
        """Test login with email."""
        # Register user first
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "emaillogin",
                "email": "emaillogin@example.com",
                "password": "EmailPassword123!",
            },
        )

        # Login with email
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "emaillogin@example.com",
                "password": "EmailPassword123!",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data

    async def test_login_wrong_password(self, client: AsyncClient, session: AsyncSession):
        """Test login with wrong password."""
        # Register user first
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "wrongpass",
                "email": "wrongpass@example.com",
                "password": "CorrectPassword123!",
            },
        )

        # Try to login with wrong password
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "wrongpass",
                "password": "WrongPassword456!",
            },
        )

        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    async def test_login_nonexistent_user(self, client: AsyncClient):
        """Test login with nonexistent user."""
        response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "nonexistent",
                "password": "Password123!",
            },
        )

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.asyncio
class TestProtectedEndpoints:
    """Test protected endpoints require authentication."""

    async def test_access_profile_without_token(self, client: AsyncClient):
        """Test accessing profile without authentication."""
        response = await client.get("/api/v1/users/me")

        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    async def test_access_profile_with_token(self, client: AsyncClient):
        """Test accessing profile with valid token."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "protected",
                "email": "protected@example.com",
                "password": "Protected123!",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "protected",
                "password": "Protected123!",
            },
        )

        token = login_response.json()["access_token"]

        # Access protected endpoint
        response = await client.get(
            "/api/v1/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["username"] == "protected"
        assert data["email"] == "protected@example.com"

    async def test_access_with_invalid_token(self, client: AsyncClient):
        """Test accessing protected endpoint with invalid token."""
        response = await client.get(
            "/api/v1/users/me",
            headers={"Authorization": "Bearer invalid_token_here"},
        )

        assert response.status_code == status.HTTP_401_UNAUTHORIZED


@pytest.mark.asyncio
class TestTokenRefresh:
    """Test token refresh endpoint."""

    async def test_refresh_token(self, client: AsyncClient):
        """Test refreshing access token."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "refreshtest",
                "email": "refresh@example.com",
                "password": "Refresh123!",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "refreshtest",
                "password": "Refresh123!",
            },
        )

        refresh_token = login_response.json()["refresh_token"]

        # Refresh token
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": refresh_token},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        # New tokens should be different
        assert data["access_token"] != login_response.json()["access_token"]
        assert data["refresh_token"] != login_response.json()["refresh_token"]

    async def test_refresh_with_access_token_fails(self, client: AsyncClient):
        """Test that using access token for refresh fails."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "accesstest",
                "email": "access@example.com",
                "password": "Access123!",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "accesstest",
                "password": "Access123!",
            },
        )

        access_token = login_response.json()["access_token"]

        # Try to use access token for refresh
        response = await client.post(
            "/api/v1/auth/refresh",
            json={"refresh_token": access_token},  # Wrong token type
        )

        assert response.status_code == status.HTTP_401_UNAUTHORIZED
