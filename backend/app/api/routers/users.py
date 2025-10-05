"""User profile and preferences management endpoints."""

from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.schemas.user_schemas import (
    UserPreferencesResponse,
    UserPreferencesUpdate,
    UserProfilePublic,
    UserProfileUpdate,
)
from app.db.session import get_session
from app.db.user_models import User, UserPreferences, UserProfile
from app.security.auth import get_current_user

router = APIRouter(prefix="/users", tags=["users"])


# ---------------------------------------------------------------------
# User Profile Endpoints
# ---------------------------------------------------------------------


@router.get("/me", response_model=UserProfilePublic)
async def get_current_user_profile(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> User:
    """Get the current authenticated user's profile."""
    # Eagerly load profile relationship
    result = await session.execute(
        select(User).where(User.id == current_user.id).options(selectinload(User.profile))
    )
    user = result.scalar_one()
    return user


@router.patch("/me", response_model=UserProfilePublic)
async def update_current_user_profile(
    updates: UserProfileUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> User:
    """Update the current user's profile information."""
    # Get or create profile
    result = await session.execute(select(UserProfile).where(UserProfile.user_id == current_user.id))
    profile = result.scalar_one_or_none()

    if not profile:
        profile = UserProfile(user_id=current_user.id)
        session.add(profile)

    # Update fields (only non-None values from request)
    update_data = updates.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(profile, field, value)

    await session.commit()

    # Return updated user with profile
    result = await session.execute(
        select(User).where(User.id == current_user.id).options(selectinload(User.profile))
    )
    user = result.scalar_one()
    return user


@router.delete("/me", status_code=status.HTTP_204_NO_CONTENT, response_model=None)
async def delete_current_user(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
):
    """Delete the current user's account (soft delete by deactivating)."""
    current_user.is_active = False
    await session.commit()


# ---------------------------------------------------------------------
# User Preferences Endpoints
# ---------------------------------------------------------------------


@router.get("/me/preferences", response_model=UserPreferencesResponse)
async def get_user_preferences(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserPreferences:
    """Get the current user's preferences."""
    result = await session.execute(select(UserPreferences).where(UserPreferences.user_id == current_user.id))
    prefs = result.scalar_one_or_none()

    if not prefs:
        # Create default preferences if they don't exist
        prefs = UserPreferences(user_id=current_user.id)
        session.add(prefs)
        await session.commit()
        await session.refresh(prefs)

    return prefs


@router.patch("/me/preferences", response_model=UserPreferencesResponse)
async def update_user_preferences(
    updates: UserPreferencesUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> UserPreferences:
    """Update the current user's preferences."""
    result = await session.execute(select(UserPreferences).where(UserPreferences.user_id == current_user.id))
    prefs = result.scalar_one_or_none()

    if not prefs:
        prefs = UserPreferences(user_id=current_user.id)
        session.add(prefs)
        await session.flush()

    # Update fields (only non-None values from request)
    update_data = updates.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(prefs, field, value)

    await session.commit()
    await session.refresh(prefs)

    return prefs


__all__ = ["router"]
