"""User API key (BYOK) management endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.schemas.user_schemas import (
    UserAPIKeyCreate,
    UserAPIKeyResponse,
)
from app.db.session import get_session
from app.db.user_models import User, UserAPIConfig
from app.security.auth import get_current_user
from app.security.encryption import decrypt_api_key, encrypt_api_key

router = APIRouter(prefix="/api-keys", tags=["api-keys"])


@router.get("/", response_model=list[UserAPIKeyResponse])
async def list_api_keys(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> list[UserAPIConfig]:
    """List all configured API keys for the current user.

    Returns provider names and metadata only - does NOT return the actual keys.
    """
    result = await session.execute(select(UserAPIConfig).where(UserAPIConfig.user_id == current_user.id))
    configs = result.scalars().all()
    return list(configs)


@router.post("/", response_model=UserAPIKeyResponse, status_code=status.HTTP_201_CREATED)
async def create_or_update_api_key(
    request: UserAPIKeyCreate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserAPIConfig:
    """Add or update an API key for a specific provider.

    The API key is encrypted before storage.
    """
    # Encrypt the API key
    encrypted_key = encrypt_api_key(request.api_key)

    # Check if config already exists for this provider
    result = await session.execute(
        select(UserAPIConfig).where(
            UserAPIConfig.user_id == current_user.id,
            UserAPIConfig.provider == request.provider,
        )
    )
    existing_config = result.scalar_one_or_none()

    if existing_config:
        # Update existing
        existing_config.encrypted_api_key = encrypted_key
        await session.commit()
        await session.refresh(existing_config)
        return existing_config
    else:
        # Create new
        config = UserAPIConfig(
            user_id=current_user.id,
            provider=request.provider,
            encrypted_api_key=encrypted_key,
        )
        session.add(config)
        await session.commit()
        await session.refresh(config)
        return config


@router.delete("/{provider}", status_code=status.HTTP_204_NO_CONTENT, response_model=None)
async def delete_api_key(
    provider: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Delete an API key for a specific provider."""
    result = await session.execute(
        select(UserAPIConfig).where(
            UserAPIConfig.user_id == current_user.id,
            UserAPIConfig.provider == provider,
        )
    )
    config = result.scalar_one_or_none()

    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No API key configured for provider: {provider}",
        )

    await session.delete(config)
    await session.commit()


@router.get("/{provider}/test", response_model=dict)
async def test_api_key(
    provider: str,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> dict[str, str]:
    """Test if an API key is configured (does not validate if it works).

    Returns a masked version of the key for verification.
    """
    result = await session.execute(
        select(UserAPIConfig).where(
            UserAPIConfig.user_id == current_user.id,
            UserAPIConfig.provider == provider,
        )
    )
    config = result.scalar_one_or_none()

    if not config:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No API key configured for provider: {provider}",
        )

    # Decrypt and mask the key
    try:
        decrypted_key = decrypt_api_key(config.encrypted_api_key)
        # Show first 8 and last 4 characters
        if len(decrypted_key) > 12:
            masked = f"{decrypted_key[:8]}...{decrypted_key[-4:]}"
        else:
            masked = f"{decrypted_key[:4]}...{decrypted_key[-2:]}"

        return {
            "provider": provider,
            "configured": True,
            "masked_key": masked,
            "length": len(decrypted_key),
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to decrypt API key: {str(e)}",
        )


__all__ = ["router"]
