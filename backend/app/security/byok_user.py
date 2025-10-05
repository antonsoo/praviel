"""User-specific BYOK (Bring Your Own Key) utilities.

Integrates user API key management with the existing BYOK middleware system.
"""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.user_models import User, UserAPIConfig
from app.security.encryption import decrypt_api_key


async def get_user_api_key(
    user: User | None,
    provider: str,
    session: AsyncSession,
) -> str | None:
    """Get a user's API key for a specific provider.

    Args:
        user: The authenticated user (or None for anonymous)
        provider: Provider name (openai, anthropic, google, elevenlabs)
        session: Database session

    Returns:
        Decrypted API key or None if not configured
    """
    if not user:
        return None

    result = await session.execute(
        select(UserAPIConfig).where(
            UserAPIConfig.user_id == user.id,
            UserAPIConfig.provider == provider,
        )
    )
    config = result.scalar_one_or_none()

    if not config:
        return None

    try:
        return decrypt_api_key(config.encrypted_api_key)
    except Exception:
        # If decryption fails, return None (don't crash the request)
        return None


async def get_api_key_with_fallback(
    user: User | None,
    provider: str,
    session: AsyncSession,
    header_key: str | None = None,
    server_key: str | None = None,
) -> str | None:
    """Get API key with fallback priority: user DB > header > server default.

    This implements the BYOK priority:
    1. User's stored API key (if authenticated)
    2. Header-provided API key (BYOK via request header)
    3. Server-configured API key (fallback)

    Args:
        user: Authenticated user or None
        provider: Provider name
        session: Database session
        header_key: API key from request header (BYOK)
        server_key: Server-configured default API key

    Returns:
        API key to use, or None if none available
    """
    # Priority 1: User's stored API key
    if user:
        user_key = await get_user_api_key(user, provider, session)
        if user_key:
            return user_key

    # Priority 2: Header-provided key (BYOK)
    if header_key:
        return header_key

    # Priority 3: Server default
    return server_key


__all__ = [
    "get_user_api_key",
    "get_api_key_with_fallback",
]
