"""API endpoints for script display preferences.

These endpoints allow users to configure how ancient language texts are rendered,
including options for scriptio continua, interpuncts, nomina sacra, etc.
"""

from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.schemas.script_preferences import (
    ScriptPreferences,
    ScriptPreferencesUpdate,
)
from app.db.session import get_session
from app.db.user_models import User, UserPreferences
from app.security.auth import get_current_user

router = APIRouter(prefix="/users/me/script-preferences", tags=["script-preferences"])


@router.get("", response_model=ScriptPreferences)
async def get_script_preferences(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> ScriptPreferences:
    """Get the current user's script display preferences.

    Returns preferences for how ancient language texts should be rendered,
    including settings for scriptio continua, interpuncts, nomina sacra, etc.

    If no preferences exist, returns default values.
    """
    result = await session.execute(select(UserPreferences).where(UserPreferences.user_id == current_user.id))
    prefs = result.scalar_one_or_none()

    if not prefs or not prefs.settings:
        # Return defaults
        return ScriptPreferences()

    # Extract script_preferences from settings JSON
    script_prefs_dict = prefs.settings.get("script_preferences", {})
    return ScriptPreferences(**script_prefs_dict)


@router.put("", response_model=ScriptPreferences)
async def update_script_preferences(
    updates: ScriptPreferencesUpdate,
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> ScriptPreferences:
    """Update the current user's script display preferences.

    Updates preferences for how ancient language texts should be rendered.
    Only provided fields will be updated (partial updates supported).

    Returns the complete updated preferences object.
    """
    result = await session.execute(select(UserPreferences).where(UserPreferences.user_id == current_user.id))
    prefs = result.scalar_one_or_none()

    if not prefs:
        # Create new preferences record
        prefs = UserPreferences(user_id=current_user.id, settings={})
        session.add(prefs)
        await session.flush()

    # Ensure settings dict exists
    if not prefs.settings:
        prefs.settings = {}

    # Get current script preferences or create default
    current_script_prefs = prefs.settings.get("script_preferences", {})
    current_prefs_obj = ScriptPreferences(**current_script_prefs)

    # Apply updates (only non-None values)
    update_data = updates.model_dump(exclude_unset=True, exclude_none=True)

    # Update the preferences object
    for field, value in update_data.items():
        setattr(current_prefs_obj, field, value)

    # Save back to settings JSON
    prefs.settings["script_preferences"] = current_prefs_obj.model_dump()

    # Mark as modified for SQLAlchemy to detect changes in JSONB
    from sqlalchemy.orm.attributes import flag_modified

    flag_modified(prefs, "settings")

    await session.commit()
    await session.refresh(prefs)

    # Return updated preferences
    return current_prefs_obj


@router.post("/reset", response_model=ScriptPreferences)
async def reset_script_preferences(
    current_user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> ScriptPreferences:
    """Reset script preferences to defaults.

    Clears all custom script preferences and returns to default values.
    """
    result = await session.execute(select(UserPreferences).where(UserPreferences.user_id == current_user.id))
    prefs = result.scalar_one_or_none()

    if prefs and prefs.settings:
        # Remove script_preferences from settings
        if "script_preferences" in prefs.settings:
            del prefs.settings["script_preferences"]

            # Mark as modified
            from sqlalchemy.orm.attributes import flag_modified

            flag_modified(prefs, "settings")

            await session.commit()

    # Return defaults
    return ScriptPreferences()


__all__ = ["router"]
