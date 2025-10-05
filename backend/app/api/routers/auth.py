"""Authentication endpoints for user registration, login, and token management."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.schemas.user_schemas import (
    TokenRefreshRequest,
    TokenResponse,
    UserLoginRequest,
    UserProfilePublic,
    UserRegisterRequest,
)
from app.db.session import get_session
from app.db.user_models import User, UserPreferences, UserProfile, UserProgress
from app.security.auth import (
    create_token_pair,
    decode_token,
    hash_password,
    verify_password,
)

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register", response_model=UserProfilePublic, status_code=status.HTTP_201_CREATED)
async def register(
    request: UserRegisterRequest,
    session: AsyncSession = Depends(get_session),
) -> User:
    """Register a new user account.

    Creates a user with hashed password and initializes related tables:
    - UserProfile (empty, user can fill in later)
    - UserPreferences (with defaults)
    - UserProgress (starting at 0 XP, level 0, 0 streak)
    """
    # Check if username already exists
    result = await session.execute(select(User).where(User.username == request.username))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already registered",
        )

    # Check if email already exists
    result = await session.execute(select(User).where(User.email == request.email))
    if result.scalar_one_or_none():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered",
        )

    # Create user
    hashed_pwd = hash_password(request.password)
    user = User(
        username=request.username,
        email=request.email,
        hashed_password=hashed_pwd,
        is_active=True,
        is_superuser=False,
    )

    session.add(user)
    await session.flush()  # Get user.id

    # Create related tables
    profile = UserProfile(user_id=user.id)
    preferences = UserPreferences(user_id=user.id)
    progress = UserProgress(user_id=user.id, xp_total=0, level=0, streak_days=0, max_streak=0)

    session.add(profile)
    session.add(preferences)
    session.add(progress)

    await session.commit()
    await session.refresh(user)

    return user


@router.post("/login", response_model=TokenResponse)
async def login(
    request: UserLoginRequest,
    session: AsyncSession = Depends(get_session),
) -> TokenResponse:
    """Log in with username/email and password.

    Returns JWT access and refresh tokens.
    """
    # Find user by username or email
    result = await session.execute(
        select(User).where(
            or_(
                User.username == request.username_or_email,
                User.email == request.username_or_email,
            )
        )
    )
    user = result.scalar_one_or_none()

    # Verify user exists and password is correct
    if not user or not verify_password(request.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Check if user is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Inactive user account",
        )

    # Create token pair
    tokens = create_token_pair(user.id)
    return tokens


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: TokenRefreshRequest,
    session: AsyncSession = Depends(get_session),
) -> TokenResponse:
    """Refresh access token using a refresh token.

    Returns a new access token and refresh token.
    """
    # Decode and validate refresh token
    try:
        token_data = decode_token(request.refresh_token)
    except HTTPException:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify it's a refresh token
    if token_data.token_type != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify user still exists and is active
    result = await session.execute(select(User).where(User.id == token_data.sub))
    user = result.scalar_one_or_none()

    if not user or not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found or inactive",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Create new token pair
    tokens = create_token_pair(user.id)
    return tokens


@router.post("/logout")
async def logout() -> dict[str, str]:
    """Log out (client should discard tokens).

    Since we use stateless JWT tokens, logout is handled client-side
    by discarding the tokens. This endpoint exists for API completeness
    and could be extended to support token blacklisting if needed.
    """
    return {"message": "Successfully logged out. Please discard your tokens."}


__all__ = ["router"]
