import logging

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

REQUIRED_EXTENSIONS = ("vector", "pg_trgm")


async def check_db_extensions(db: AsyncSession) -> dict[str, bool]:
    """
    Return a dict {ext: bool} for required PostgreSQL extensions.
    Extensions are created by Alembic migrations, not here.
    """
    stmt = text("SELECT extname FROM pg_extension WHERE extname = ANY(:exts)")
    rows = (await db.execute(stmt, {"exts": list(REQUIRED_EXTENSIONS)})).all()
    installed = {r[0] for r in rows}
    status = {ext: (ext in installed) for ext in REQUIRED_EXTENSIONS}
    for ext, ok in status.items():
        if not ok:
            logger.error("Missing required DB extension: %s", ext)
    return status


async def seed_initial_languages(db: AsyncSession) -> None:
    """
    Idempotently ensure baseline languages exist.
    Uses server defaults for timestamp fields.
    """
    await db.execute(
        text(
            "INSERT INTO language (code, name) VALUES ('grc', 'Ancient Greek') ON CONFLICT (code) DO NOTHING"
        )
    )
    await db.execute(
        text("INSERT INTO language (code, name) VALUES ('lat', 'Latin') ON CONFLICT (code) DO NOTHING")
    )
    await db.commit()
    logger.info("Initial language seed check complete.")


async def initialize_database(db: AsyncSession) -> None:
    """
    Run at app startup (FastAPI lifespan). Fail fast if extensions are missing,
    then seed languages. Health endpoints must remain read‑only.
    """
    logger.info("Initializing database...")
    ext = await check_db_extensions(db)
    if not all(ext.values()):
        missing = ", ".join([k for k, v in ext.items() if not v])
        raise RuntimeError(
            f"Missing PostgreSQL extensions: {missing}. Run Alembic migrations to install them."
        )
    await seed_initial_languages(db)
    logger.info("Database initialization complete.")
