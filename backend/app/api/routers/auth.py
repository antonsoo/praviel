"""Authentication endpoints for user registration, login, and token management."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.schemas.user_schemas import (
    PasswordChangeRequest,
    TokenRefreshRequest,
    TokenResponse,
    UserLoginRequest,
    UserProfilePublic,
    UserRegisterRequest,
)
from app.core.validation import (
    validate_email_or_raise,
    validate_password_or_raise,
    validate_username_or_raise,
)
from app.db.session import get_session
from app.db.user_models import User, UserPreferences, UserProfile, UserProgress
from app.security.auth import (
    create_token_pair,
    decode_token,
    get_current_user,
    hash_password,
    verify_password,
)

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/register", response_model=UserProfilePublic, status_code=status.HTTP_201_CREATED)
async def register(
    http_request: Request,
    request: UserRegisterRequest,
    session: AsyncSession = Depends(get_session),
) -> User:
    """Register a new user account.

    Creates a user with hashed password and initializes related tables:
    - UserProfile (empty, user can fill in later)
    - UserPreferences (with defaults)
    - UserProgress (starting at 0 XP, level 0, 0 streak)
    """
    # Validate input format FIRST
    validate_username_or_raise(request.username)
    validate_email_or_raise(request.email)
    validate_password_or_raise(request.password, username=request.username)

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
    progress = UserProgress(
        user_id=user.id,
        xp_total=0,
        level=0,
        streak_days=0,
        max_streak=0,
        # Initialize adaptive difficulty stats to prevent NULL values
        challenge_success_rate=0.0,
        avg_completion_time_seconds=0.0,
        preferred_difficulty="medium",
        total_challenges_attempted=0,
        total_challenges_completed=0,
        consecutive_failures=0,
        consecutive_successes=0,
    )

    session.add(profile)
    session.add(preferences)
    session.add(progress)

    await session.commit()
    await session.refresh(user)

    # Send email verification
    try:
        from app.api.routers.email_verification import _send_verification_email

        await _send_verification_email(user, session)
        logger.info(f"Sent verification email to {user.email}")
    except Exception as exc:
        # Don't fail registration if email fails
        logger.error(f"Failed to send verification email to {user.email}: {exc}")

    return user


@router.post("/login", response_model=TokenResponse)
async def login(
    http_request: Request,
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
        token_data = await decode_token(request.refresh_token, session)
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


@router.post("/change-password")
async def change_password(
    http_request: Request,
    request: PasswordChangeRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    """Change password for the authenticated user.

    Requires:
    - Current password (for verification)
    - New password (must meet complexity requirements)

    Returns success message on successful password change.
    """
    # Verify current password
    if not verify_password(request.old_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect current password",
        )

    # Validate new password
    validate_password_or_raise(request.new_password, username=current_user.username)

    # Hash and update to new password
    current_user.hashed_password = hash_password(request.new_password)

    await session.commit()

    # Send password changed notification
    try:
        from app.core.config import settings
        from app.services.email import create_email_service
        from app.services.email_templates import EmailTemplates

        email_service = create_email_service(
            provider=settings.EMAIL_PROVIDER,
            resend_api_key=settings.RESEND_API_KEY,
            sendgrid_api_key=settings.SENDGRID_API_KEY,
            aws_access_key=settings.AWS_ACCESS_KEY_ID,
            aws_secret_key=settings.AWS_SECRET_ACCESS_KEY,
            aws_region=settings.AWS_REGION,
            mailgun_api_key=settings.MAILGUN_API_KEY,
            mailgun_domain=settings.MAILGUN_DOMAIN,
            postmark_api_key=settings.POSTMARK_API_KEY,
            from_address=settings.EMAIL_FROM_ADDRESS,
            from_name=settings.EMAIL_FROM_NAME,
        )

        subject, html_body, text_body = EmailTemplates.password_changed(
            username=current_user.username,
            support_url=f"{settings.FRONTEND_URL}/support",
        )

        await email_service.send_email(
            to_email=current_user.email,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )
        logger.info(f"Sent password changed notification to {current_user.email}")
    except Exception as exc:
        # Don't fail password change if email fails
        logger.error(f"Failed to send password changed notification to {current_user.email}: {exc}")

    return {"message": "Password changed successfully"}


__all__ = ["router"]
