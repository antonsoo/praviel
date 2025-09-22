from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import Settings, get_settings
from app.db.session import get_db
from app.lesson.models import LessonGenerateRequest, LessonResponse
from app.lesson.service import generate_lesson as generate_lesson_service
from app.security.byok import get_byok_token

router = APIRouter(prefix="/lesson", tags=["Lesson"])


@router.post("/generate", response_model=LessonResponse)
async def generate_lesson(
    payload: LessonGenerateRequest,
    settings: Settings = Depends(get_settings),
    session: AsyncSession = Depends(get_db),
    token: str | None = Depends(get_byok_token),
) -> LessonResponse:
    if not getattr(settings, "LESSONS_ENABLED", False):
        raise HTTPException(status_code=404, detail="Lesson endpoint is disabled")
    return await generate_lesson_service(
        request=payload,
        session=session,
        settings=settings,
        token=token,
    )
