"""Unified BYOK (Bring Your Own Key) token resolution.

Priority order:
1. User's database-stored API keys (if authenticated)
2. Request header token (Authorization: Bearer or X-Model-Key)
3. Server default from settings

This allows authenticated users to store their API keys securely in the database,
while still supporting header-based BYOK and server defaults.
"""

from __future__ import annotations

import logging

from fastapi import Depends, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.session import get_session
from app.db.user_models import User, UserAPIConfig
from app.security.byok import extract_byok_token
from app.security.encryption import decrypt_api_key

_LOGGER = logging.getLogger("app.security.unified_byok")

# Optional bearer scheme - doesn't raise 401 if missing
bearer_scheme = HTTPBearer(auto_error=False)

# Provider name mapping (standardized names)
PROVIDER_MAP = {
    "openai": "openai",
    "anthropic": "anthropic",
    "google": "google",
    "gpt": "openai",  # Alias
    "claude": "anthropic",  # Alias
    "gemini": "google",  # Alias
}


async def get_unified_api_key(
    provider: str,
    *,
    request: Request,
    session: AsyncSession = Depends(get_session),
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> str | None:
    """Get API key with priority: user DB > request header > server default.

    Args:
        provider: Provider name (openai, anthropic, google, etc.)
        request: FastAPI request object
        session: Database session
        credentials: Optional JWT bearer token for authentication

    Returns:
        API key string or None if not found

    Priority order:
    1. Check if user is authenticated - if yes, try to get their stored API key from database
    2. Check request headers for BYOK token (Authorization: Bearer or X-Model-Key)
    3. Fall back to server default from settings

    Note: This function does NOT raise errors if keys are missing. It returns None
    and lets the provider decide how to handle missing keys.
    """
    # Normalize provider name
    provider_key = PROVIDER_MAP.get(provider.lower(), provider.lower())

    # Step 1: Try to get user's database-stored API key (highest priority)
    bearer_credentials = credentials if isinstance(credentials, HTTPAuthorizationCredentials) else None

    if bearer_credentials:
        try:
            # Try to extract user ID from JWT token
            from app.security.auth import decode_token

            token = bearer_credentials.credentials
            token_data = decode_token(token)

            if token_data.token_type == "access":
                # Get user from database
                result = await session.execute(select(User).where(User.id == token_data.user_id))
                user = result.scalar_one_or_none()

                if user and user.is_active:
                    # Get user's API config for this provider
                    config_result = await session.execute(
                        select(UserAPIConfig).where(
                            UserAPIConfig.user_id == user.id,
                            UserAPIConfig.provider == provider_key,
                        )
                    )
                    user_config = config_result.scalar_one_or_none()

                    if user_config:
                        # Decrypt and return user's API key
                        try:
                            decrypted_key = decrypt_api_key(user_config.encrypted_api_key)
                            _LOGGER.info(
                                "Using user database API key for provider=%s user_id=%d",
                                provider_key,
                                user.id,
                            )
                            return decrypted_key
                        except Exception as e:
                            _LOGGER.error(
                                "Failed to decrypt user API key for provider=%s user_id=%d: %s",
                                provider_key,
                                user.id,
                                e,
                            )
                            # Continue to next priority level
        except Exception as e:
            # JWT decode failed or user not found - this is OK, just means not authenticated
            _LOGGER.debug("User authentication failed, falling back to header/server keys: %s", e)

    # Step 2: Try to get token from request headers (BYOK)
    if settings.BYOK_ENABLED:
        header_token = extract_byok_token(
            request.headers,
            allowed=settings.BYOK_ALLOWED_HEADERS,
        )
        if header_token and bearer_credentials and header_token == bearer_credentials.credentials:
            header_token = None
        if header_token:
            _LOGGER.info("Using header BYOK token for provider=%s", provider_key)
            return header_token

    # Step 3: Fall back to server default from settings (lowest priority)
    server_key = None
    if provider_key == "openai":
        server_key = settings.OPENAI_API_KEY
    elif provider_key == "anthropic":
        server_key = settings.ANTHROPIC_API_KEY
    elif provider_key == "google":
        server_key = settings.GOOGLE_API_KEY

    if server_key:
        _LOGGER.info("Using server default API key for provider=%s", provider_key)
        return server_key

    _LOGGER.debug(
        "No API key found for provider=%s (checked user DB, headers, server defaults)", provider_key
    )
    return None


async def get_openai_key(
    request: Request,
    session: AsyncSession = Depends(get_session),
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> str | None:
    """Get OpenAI API key with unified priority resolution."""
    return await get_unified_api_key("openai", request=request, session=session, credentials=credentials)


async def get_anthropic_key(
    request: Request,
    session: AsyncSession = Depends(get_session),
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> str | None:
    """Get Anthropic API key with unified priority resolution."""
    return await get_unified_api_key("anthropic", request=request, session=session, credentials=credentials)


async def get_google_key(
    request: Request,
    session: AsyncSession = Depends(get_session),
    credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> str | None:
    """Get Google API key with unified priority resolution."""
    return await get_unified_api_key("google", request=request, session=session, credentials=credentials)
