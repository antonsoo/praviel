"""Password reset endpoints for forgotten passwords.

This module provides endpoints for requesting and completing password resets via email tokens.
In production, this would integrate with an email service (SendGrid, AWS SES, etc.).
"""

from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.validation import validate_password_or_raise
from app.db.session import get_session
from app.db.user_models import PasswordResetToken, User
from app.security.auth import hash_password
from app.services.email import create_email_service

router = APIRouter(prefix="/auth", tags=["password-reset"])

# Initialize email service based on environment
_email_service = create_email_service(
    provider=settings.EMAIL_PROVIDER,
    resend_api_key=settings.RESEND_API_KEY,
    sendgrid_api_key=settings.SENDGRID_API_KEY,
    from_address=settings.EMAIL_FROM_ADDRESS,
    from_name=settings.EMAIL_FROM_NAME,
    # AWS SES
    aws_region=settings.AWS_REGION,
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    # Mailgun
    mailgun_domain=settings.MAILGUN_DOMAIN,
    mailgun_api_key=settings.MAILGUN_API_KEY,
    # Postmark
    postmark_server_token=settings.POSTMARK_SERVER_TOKEN,
)


class PasswordResetRequest(BaseModel):
    """Request to initiate password reset."""

    email: EmailStr


class PasswordResetConfirm(BaseModel):
    """Confirm password reset with token."""

    token: str = Field(..., min_length=32, max_length=512, description="Reset token from email")
    new_password: str = Field(
        ..., min_length=8, max_length=128, description="New password (min 8 characters)"
    )


class PasswordResetResponse(BaseModel):
    """Response for password reset request."""

    message: str
    email: str


@router.post("/password-reset/request", response_model=PasswordResetResponse)
async def request_password_reset(
    request: PasswordResetRequest,
    session: AsyncSession = Depends(get_session),
) -> PasswordResetResponse:
    """Request a password reset email.

    This endpoint:
    1. Checks if the email exists
    2. Generates a secure reset token
    3. Stores the token with expiry (15 minutes)
    4. Sends reset email via configured email service

    NOTE: For security, we always return success even if email doesn't exist
    to prevent email enumeration attacks.
    """
    # Look up user by email
    result = await session.execute(select(User).where(User.email == request.email))
    user = result.scalar_one_or_none()

    if user and user.is_active:
        # Generate secure random token
        token = secrets.token_urlsafe(32)

        # Store token in database with 15-minute expiry
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
        reset_token = PasswordResetToken(
            user_id=user.id,
            token=token,
            expires_at=expires_at,
        )
        session.add(reset_token)
        await session.commit()

        # Send password reset email
        reset_url = f"{settings.FRONTEND_URL}/reset-password?token={token}"

        await _email_service.send_password_reset(
            to_email=user.email,
            reset_url=reset_url,
            expires_minutes=15,
        )

        # For development, also log the token
        import logging

        logging.info(f"Password reset requested for {user.email}. Token: {token} (expires in 15 min)")

    # Always return success to prevent email enumeration
    return PasswordResetResponse(
        message="If an account exists with this email, you will receive password reset instructions.",
        email=request.email,
    )


@router.post("/password-reset/confirm")
async def confirm_password_reset(
    request: PasswordResetConfirm,
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    """Complete password reset with token.

    Validates the token and updates the user's password.
    """
    # Look up token in database
    result = await session.execute(
        select(PasswordResetToken).where(
            PasswordResetToken.token == request.token, PasswordResetToken.used_at.is_(None)
        )
    )
    reset_token = result.scalar_one_or_none()

    # Check if token exists and is unused
    if not reset_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token",
        )

    # Check if token is expired
    if datetime.now(timezone.utc) > reset_token.expires_at:
        await session.delete(reset_token)
        await session.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset token has expired. Please request a new one.",
        )

    # Get user
    user_result = await session.execute(select(User).where(User.id == reset_token.user_id))
    user = user_result.scalar_one_or_none()

    if not user:
        await session.delete(reset_token)
        await session.commit()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Validate new password strength using centralized validation
    validate_password_or_raise(request.new_password, username=user.username)

    # Update password
    user.hashed_password = hash_password(request.new_password)

    # Mark token as used
    reset_token.used_at = datetime.now(timezone.utc)

    await session.commit()

    return {"message": "Password reset successfully. You can now log in with your new password."}


@router.get("/password-reset/validate-token/{token}")
async def validate_reset_token(token: str, session: AsyncSession = Depends(get_session)) -> dict[str, bool]:
    """Check if a password reset token is valid.

    Useful for frontend to validate token before showing password form.
    """
    # Look up token in database
    result = await session.execute(
        select(PasswordResetToken).where(
            PasswordResetToken.token == token, PasswordResetToken.used_at.is_(None)
        )
    )
    reset_token = result.scalar_one_or_none()

    if not reset_token:
        return {"valid": False}

    # Check if expired
    is_valid = datetime.now(timezone.utc) <= reset_token.expires_at

    if not is_valid:
        # Clean up expired token
        await session.delete(reset_token)
        await session.commit()

    return {"valid": is_valid}


__all__ = ["router"]
