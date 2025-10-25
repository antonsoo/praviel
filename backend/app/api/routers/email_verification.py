"""Email verification endpoints.

Provides endpoints for:
- Sending verification emails
- Verifying email addresses with tokens
- Resending verification emails
"""

from __future__ import annotations

import logging
import secrets
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_session
from app.db.user_models import EmailVerificationToken, User
from app.security.auth import get_current_user
from app.services.email import create_email_service
from app.services.email_templates import EmailTemplates

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth/email", tags=["email-verification"])

# Initialize email service
_email_service = create_email_service(
    provider=settings.EMAIL_PROVIDER,
    resend_api_key=settings.RESEND_API_KEY,
    sendgrid_api_key=settings.SENDGRID_API_KEY,
    from_address=settings.EMAIL_FROM_ADDRESS if settings.EMAIL_FROM_ADDRESS else "verify@praviel.com",
    from_name=settings.EMAIL_FROM_NAME,
    aws_region=settings.AWS_REGION,
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    mailgun_domain=settings.MAILGUN_DOMAIN,
    mailgun_api_key=settings.MAILGUN_API_KEY,
    postmark_server_token=settings.POSTMARK_SERVER_TOKEN,
)


class EmailVerificationRequest(BaseModel):
    """Request to send/resend verification email."""

    email: EmailStr


class EmailVerificationResponse(BaseModel):
    """Response after requesting verification email."""

    message: str
    email: str


class VerifyEmailRequest(BaseModel):
    """Request to verify email with token."""

    token: str


async def _send_verification_email(user: User, session: AsyncSession) -> None:
    """Send email verification to user.

    Args:
        user: User to send verification email to
        session: Database session
    """
    # Generate secure token
    token = secrets.token_urlsafe(32)

    # Store token with 24-hour expiry
    expires_at = datetime.now(timezone.utc) + timedelta(hours=24)
    verification_token = EmailVerificationToken(
        user_id=user.id,
        token=token,
        expires_at=expires_at,
    )

    session.add(verification_token)
    await session.commit()

    # Build verification URL
    verification_url = f"{settings.FRONTEND_URL}/verify-email?token={token}"

    # Get email template
    subject, html_body, text_body = EmailTemplates.verification_email(
        username=user.username,
        verification_url=verification_url,
    )

    # Send email
    try:
        await _email_service.send_email(
            to_email=user.email,
            subject=subject,
            html_body=html_body,
            text_body=text_body,
        )
        logger.info(f"Sent verification email to {user.email}")
    except Exception as exc:
        logger.error(f"Failed to send verification email to {user.email}: {exc}")
        # Don't fail the request if email sending fails
        # Token is still created so user can try again


@router.post("/send-verification", response_model=EmailVerificationResponse)
async def send_verification_email(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> EmailVerificationResponse:
    """Send email verification to authenticated user.

    Only sends if email is not already verified.
    Invalidates any previous verification tokens.
    """
    # Check if already verified
    if current_user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is already verified",
        )

    # Invalidate any existing verification tokens
    existing_tokens = await session.execute(
        select(EmailVerificationToken).where(
            EmailVerificationToken.user_id == current_user.id,
            EmailVerificationToken.used_at.is_(None),
        )
    )
    for token in existing_tokens.scalars():
        token.used_at = datetime.now(timezone.utc)

    await session.commit()

    # Send new verification email
    await _send_verification_email(current_user, session)

    return EmailVerificationResponse(
        message="Verification email sent. Please check your inbox.",
        email=current_user.email,
    )


@router.post("/verify")
async def verify_email(
    request: VerifyEmailRequest,
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    """Verify email address with token.

    Marks the user's email as verified.
    """
    # Look up token
    result = await session.execute(
        select(EmailVerificationToken).where(
            EmailVerificationToken.token == request.token,
            EmailVerificationToken.used_at.is_(None),
        )
    )
    verification_token = result.scalar_one_or_none()

    if not verification_token:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired verification token",
        )

    # Check if expired
    if datetime.now(timezone.utc) > verification_token.expires_at:
        await session.delete(verification_token)
        await session.commit()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification token has expired. Please request a new one.",
        )

    # Get user
    user_result = await session.execute(
        select(User).where(User.id == verification_token.user_id)
    )
    user = user_result.scalar_one_or_none()

    if not user:
        await session.delete(verification_token)
        await session.commit()
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    # Mark email as verified
    user.email_verified = True

    # Mark token as used
    verification_token.used_at = datetime.now(timezone.utc)

    await session.commit()

    logger.info(f"Email verified for user {user.username}")

    return {"message": "Email verified successfully"}


@router.get("/status")
async def get_verification_status(
    current_user: User = Depends(get_current_user),
) -> dict[str, bool]:
    """Get current email verification status for authenticated user."""
    return {
        "email_verified": current_user.email_verified,
        "email": current_user.email,
    }


__all__ = ["router", "_send_verification_email"]
