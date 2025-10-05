"""Authentication utilities for JWT-based user authentication.

Provides password hashing, token generation/validation, and dependency injection
for protected endpoints.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, ValidationError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_session
from app.db.user_models import User

# ---------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------

# Password hashing configuration
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT configuration - Use settings with proper fallback
SECRET_KEY = settings.JWT_SECRET_KEY
ALGORITHM = settings.JWT_ALGORITHM
ACCESS_TOKEN_EXPIRE_MINUTES = settings.ACCESS_TOKEN_EXPIRE_MINUTES
REFRESH_TOKEN_EXPIRE_MINUTES = settings.REFRESH_TOKEN_EXPIRE_MINUTES

# Validate secret key is set properly
if SECRET_KEY == "CHANGE_ME_IN_PRODUCTION_USE_RANDOM_STRING":
    import logging

    logging.warning(
        "SECURITY WARNING: JWT_SECRET_KEY is using default value. "
        "Set a secure random secret in .env before production use!"
    )

# HTTP Bearer token scheme
bearer_scheme = HTTPBearer(auto_error=False)


# ---------------------------------------------------------------------
# Token Models
# ---------------------------------------------------------------------


class TokenPayload(BaseModel):
    """JWT token payload."""

    sub: str  # user_id as string (JWT spec requirement)
    exp: datetime
    iat: datetime
    token_type: str  # "access" or "refresh"

    @property
    def user_id(self) -> int:
        """Get user_id as integer."""
        return int(self.sub)


class TokenResponse(BaseModel):
    """Response containing access and refresh tokens."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# ---------------------------------------------------------------------
# Password Utilities
# ---------------------------------------------------------------------


def hash_password(password: str) -> str:
    """Hash a plaintext password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plaintext password against a hashed password."""
    return pwd_context.verify(plain_password, hashed_password)


# ---------------------------------------------------------------------
# JWT Token Utilities
# ---------------------------------------------------------------------


def create_access_token(user_id: int, expires_delta: timedelta | None = None) -> str:
    """Create a JWT access token for a user."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)

    payload = {
        "sub": str(user_id),  # JWT spec requires 'sub' to be a string
        "exp": expire,
        "iat": now,
        "token_type": "access",
    }

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def create_refresh_token(user_id: int, expires_delta: timedelta | None = None) -> str:
    """Create a JWT refresh token for a user."""
    now = datetime.now(timezone.utc)
    if expires_delta:
        expire = now + expires_delta
    else:
        expire = now + timedelta(minutes=REFRESH_TOKEN_EXPIRE_MINUTES)

    payload = {
        "sub": str(user_id),  # JWT spec requires 'sub' to be a string
        "exp": expire,
        "iat": now,
        "token_type": "refresh",
    }

    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def create_token_pair(user_id: int) -> TokenResponse:
    """Create both access and refresh tokens for a user."""
    access_token = create_access_token(user_id)
    refresh_token = create_refresh_token(user_id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
    )


def decode_token(token: str) -> TokenPayload:
    """Decode and validate a JWT token.

    Raises:
        HTTPException: If token is invalid, expired, or malformed.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        token_data = TokenPayload(**payload)
        return token_data
    except (JWTError, ValidationError):
        raise credentials_exception


# ---------------------------------------------------------------------
# Authentication Dependencies
# ---------------------------------------------------------------------


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    session: AsyncSession = Depends(get_session),
) -> User:
    """Dependency to get the current authenticated user from the request.

    Usage in endpoints:
        @router.get("/protected")
        async def protected_route(current_user: User = Depends(get_current_user)):
            return {"user_id": current_user.id, "username": current_user.username}

    Raises:
        HTTPException: If token is missing, invalid, or user not found.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    if not credentials:
        raise credentials_exception

    token = credentials.credentials
    token_data = decode_token(token)

    # Verify it's an access token
    if token_data.token_type != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Fetch user from database
    result = await session.execute(select(User).where(User.id == token_data.user_id))
    user = result.scalar_one_or_none()

    if user is None:
        raise credentials_exception

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user",
        )

    return user


async def get_current_active_user(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dependency to get the current active user (convenience wrapper)."""
    return current_user


async def get_current_superuser(
    current_user: User = Depends(get_current_user),
) -> User:
    """Dependency to require superuser privileges.

    Raises:
        HTTPException: If user is not a superuser.
    """
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Insufficient privileges",
        )
    return current_user


# ---------------------------------------------------------------------
# Optional Authentication (for public endpoints with optional user context)
# ---------------------------------------------------------------------


async def get_optional_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    session: AsyncSession = Depends(get_session),
) -> User | None:
    """Dependency to optionally get the current user if authenticated.

    Returns None if no valid token is provided (does not raise exception).
    Useful for endpoints that work for both authenticated and anonymous users.
    """
    if not credentials:
        return None

    try:
        token = credentials.credentials
        token_data = decode_token(token)

        if token_data.token_type != "access":
            return None

        result = await session.execute(select(User).where(User.id == token_data.sub))
        user = result.scalar_one_or_none()

        if user and user.is_active:
            return user
    except (HTTPException, Exception):
        pass

    return None


__all__ = [
    "hash_password",
    "verify_password",
    "create_access_token",
    "create_refresh_token",
    "create_token_pair",
    "decode_token",
    "get_current_user",
    "get_current_active_user",
    "get_current_superuser",
    "get_optional_user",
    "TokenResponse",
    "TokenPayload",
]
