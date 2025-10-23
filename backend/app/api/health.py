import logging

from fastapi import APIRouter, Depends, HTTPException, status

# Use modern SQLAlchemy 2.0 imports
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.db.init_db import check_db_extensions
from app.db.models import Language
from app.db.session import get_db

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("/health")
def health_check():
    return {
        "status": "ok",
        "project": settings.PROJECT_NAME,
        "features": {"lessons": settings.LESSONS_ENABLED, "tts": settings.TTS_ENABLED},
    }


@router.get("/health/db")
async def health_check_db(db: AsyncSession = Depends(get_db)):
    """Detailed database health check."""
    try:
        # 1. Check Connectivity
        await db.execute(select(1))

        # 2. Check Extensions
        extensions = await check_db_extensions(db)

        # 3. Check Seed Data (Modern 2.0 style query: select().where())
        stmt = select(Language).where(Language.code.in_(["grc-cls", "lat"]))
        result = await db.execute(stmt)
        seeded_count = len(result.scalars().all())
        seed_data_ok = seeded_count == 2

        health_status = {
            "status": "ok",
            "extensions": extensions,
            "seed_data": seed_data_ok,
        }

        if not all(extensions.values()) or not seed_data_ok:
            health_status["status"] = "degraded"

        return health_status

    except Exception as e:
        logger.error(f"Database health check failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database connection or check failed.",
        )
