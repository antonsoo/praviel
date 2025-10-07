"""Password reset endpoints for forgotten passwords.

This module provides endpoints for requesting and completing password resets via email tokens.
In production, this would integrate with an email service (SendGrid, AWS SES, etc.).
"""

from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session
from app.db.user_models import User
from app.security.auth import hash_password

router = APIRouter(prefix="/auth", tags=["password-reset"])

# In-memory token storage (in production, use Redis or database table)
# Format: {token: {user_id, expires_at}}
_reset_tokens: dict[str, dict] = {}


class PasswordResetRequest(BaseModel):
    """Request to initiate password reset."""

    email: EmailStr


class PasswordResetConfirm(BaseModel):
    """Confirm password reset with token."""

    token: str
    new_password: str


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
    4. Sends reset email (TODO: integrate email service)

    NOTE: For security, we always return success even if email doesn't exist
    to prevent email enumeration attacks.
    """
    # Look up user by email
    result = await session.execute(select(User).where(User.email == request.email))
    user = result.scalar_one_or_none()

    if user and user.is_active:
        # Generate secure random token
        token = secrets.token_urlsafe(32)

        # Store token with 15-minute expiry
        expires_at = datetime.now(timezone.utc) + timedelta(minutes=15)
        _reset_tokens[token] = {
            "user_id": user.id,
            "expires_at": expires_at,
        }

        # TODO: Send email with reset link
        # In production, integrate with email service:
        # await email_service.send_password_reset(
        #     to_email=user.email,
        #     reset_url=f"https://yourapp.com/reset-password?token={token}",
        #     expires_minutes=15,
        # )

        # For development, log the token (remove in production!)
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
    # Check if token exists
    if request.token not in _reset_tokens:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired reset token",
        )

    token_data = _reset_tokens[request.token]

    # Check if token is expired
    if datetime.now(timezone.utc) > token_data["expires_at"]:
        del _reset_tokens[request.token]
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset token has expired. Please request a new one.",
        )

    # Get user
    result = await session.execute(select(User).where(User.id == token_data["user_id"]))
    user = result.scalar_one_or_none()

    if not user:
        del _reset_tokens[request.token]
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Validate new password strength (basic validation)
    if len(request.new_password) < 8:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 8 characters long",
        )

    # Update password
    user.hashed_password = hash_password(request.new_password)
    await session.commit()

    # Delete used token
    del _reset_tokens[request.token]

    return {"message": "Password reset successfully. You can now log in with your new password."}


@router.get("/password-reset/validate-token/{token}")
async def validate_reset_token(token: str) -> dict[str, bool]:
    """Check if a password reset token is valid.

    Useful for frontend to validate token before showing password form.
    """
    if token not in _reset_tokens:
        return {"valid": False}

    token_data = _reset_tokens[token]
    is_valid = datetime.now(timezone.utc) <= token_data["expires_at"]

    if not is_valid:
        # Clean up expired token
        del _reset_tokens[token]

    return {"valid": is_valid}


__all__ = ["router"]
