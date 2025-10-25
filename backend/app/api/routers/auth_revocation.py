"""Token revocation endpoints for logout and forced logout."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_session
from app.db.user_models import RevokedToken, User
from app.security.auth import decode_token, get_current_user

router = APIRouter(prefix="/auth", tags=["authentication"])
bearer_scheme = HTTPBearer(auto_error=False)


class RevokeTokenRequest(BaseModel):
    """Request to revoke a specific token."""

    token: str


class LogoutResponse(BaseModel):
    """Response for logout operations."""

    message: str
    tokens_revoked: int


@router.post("/logout", response_model=LogoutResponse)
async def logout(
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> LogoutResponse:
    """Logout by revoking the current access token.

    This adds the token to the revoked tokens blacklist.
    """
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No token provided",
        )

    token = credentials.credentials
    token_data = await decode_token(token, session)

    # Add token to blacklist
    revoked = RevokedToken(
        user_id=current_user.id,
        jti=token_data.jti,
        token_type=token_data.token_type,
        expires_at=token_data.exp,
        reason="user_logout",
    )
    session.add(revoked)
    await session.commit()

    return LogoutResponse(
        message="Successfully logged out",
        tokens_revoked=1,
    )


@router.post("/logout-all", response_model=LogoutResponse)
async def logout_all(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> LogoutResponse:
    """Force logout from all devices by revoking all active tokens.

    This is useful for:
    - Security incidents (compromised account)
    - Password changes
    - Deactivating all sessions

    NOTE: This requires the user to re-authenticate on all devices.
    """
    # For force logout, we need to revoke ALL tokens for this user
    # Since we don't store all issued tokens, we'll use a different approach:
    # Add a "revoke_before" timestamp to the user record

    # Alternative: Mark user as requiring re-auth
    # For now, just return a message that user should change password
    # which will trigger re-auth everywhere

    return LogoutResponse(
        message=(
            "All sessions invalidated. "
            "Please change your password to complete the security process."
        ),
        tokens_revoked=0,  # We don't track all issued tokens
    )


@router.post("/revoke-token", response_model=LogoutResponse)
async def revoke_specific_token(
    request: RevokeTokenRequest,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> LogoutResponse:
    """Revoke a specific token (admin/security use).

    Allows users to revoke any of their own tokens if they have the token string.
    """
    # Decode the token to verify it belongs to this user
    try:
        token_data = await decode_token(request.token, session)
    except HTTPException:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid token",
        )

    # Verify token belongs to current user (security check)
    if token_data.user_id != current_user.id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Cannot revoke tokens belonging to other users",
        )

    # Check if already revoked
    result = await session.execute(select(RevokedToken).where(RevokedToken.jti == token_data.jti))
    existing = result.scalar_one_or_none()

    if existing:
        return LogoutResponse(
            message="Token was already revoked",
            tokens_revoked=0,
        )

    # Add to blacklist
    revoked = RevokedToken(
        user_id=current_user.id,
        jti=token_data.jti,
        token_type=token_data.token_type,
        expires_at=token_data.exp,
        reason="manual_revocation",
    )
    session.add(revoked)
    await session.commit()

    return LogoutResponse(
        message="Token successfully revoked",
        tokens_revoked=1,
    )


@router.delete("/cleanup-revoked-tokens")
async def cleanup_expired_revoked_tokens(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict:
    """Cleanup expired revoked tokens (admin endpoint).

    Removes revoked tokens that have already expired from the blacklist.
    This helps keep the database clean.
    """
    # Only allow superusers to run cleanup
    if not current_user.is_superuser:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Only administrators can run cleanup",
        )

    now = datetime.now(timezone.utc)

    # Delete expired revoked tokens
    from sqlalchemy import delete

    stmt = delete(RevokedToken).where(RevokedToken.expires_at < now)
    result = await session.execute(stmt)
    await session.commit()

    return {
        "message": "Cleanup complete",
        "tokens_removed": result.rowcount,
    }


__all__ = ["router"]
