from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.lesson.models import LessonGenerateRequest, LessonResponse
from app.lesson.service import generate_lesson as generate_lesson_service
from app.security.unified_byok import get_unified_api_key

router = APIRouter(prefix="/lesson", tags=["Lesson"])


@router.post("/generate", response_model=LessonResponse, response_model_exclude_none=True)
async def generate_lesson(
    payload: LessonGenerateRequest,
    request: Request,
    settings: Settings = Depends(get_settings),
    session: AsyncSession = Depends(get_db),
) -> LessonResponse:
    if not getattr(settings, "LESSONS_ENABLED", False):
        raise HTTPException(status_code=404, detail="Lesson endpoint is disabled")

    # Get API key with unified priority: user DB > header > server default
    token = await get_unified_api_key(payload.provider, request=request, session=session)

    return await generate_lesson_service(
        request=payload,
        session=session,
        settings=settings,
        token=token,
    )
