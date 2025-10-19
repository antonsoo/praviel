"""Languages API endpoint - lists available languages with metadata."""

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.models import Language, TextWork, TextSegment
from app.db.session import get_db
from app.lesson.language_config import get_language_config, LANGUAGE_CONFIGS

router = APIRouter(prefix="/languages", tags=["Languages"])


@router.get("")
async def list_languages(session: AsyncSession = Depends(get_db)):
    """List all available languages with text content status.

    Returns metadata about each language including:
    - Basic info (code, name, native name)
    - Whether texts are available for reading
    - Text content statistics
    """
    # Query languages with text work counts
    stmt = (
        select(
            Language,
            func.count(func.distinct(TextWork.id)).label("work_count"),
            func.count(TextSegment.id).label("segment_count"),
        )
        .outerjoin(TextWork, Language.id == TextWork.language_id)
        .outerjoin(TextSegment, TextWork.id == TextSegment.work_id)
        .group_by(Language.id)
        .order_by(Language.name)
    )

    result = await session.execute(stmt)
    rows = result.all()

    languages = []
    for lang, work_count, segment_count in rows:
        # Get language config for additional metadata
        lang_config = get_language_config(lang.code)

        languages.append({
            "code": lang.code,
            "name": lang_config.name,
            "native_name": lang_config.native_name,
            "emoji": lang_config.emoji,
            "script_name": lang_config.script.case if lang_config.script else None,
            "has_accents": lang_config.script.has_accents if lang_config.script else None,
            "has_texts": segment_count > 0,
            "work_count": work_count,
            "segment_count": segment_count,
        })

    return languages
