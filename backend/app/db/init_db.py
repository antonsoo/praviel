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
    core_languages = [
        ("grc-cls", "Classical Greek"),
        ("grc-koi", "Koine Greek"),
        ("lat", "Classical Latin"),
        ("hbo", "Biblical Hebrew"),
    ]

    for code, name in core_languages:
        await db.execute(
            text(
                "INSERT INTO language (code, name) VALUES (:code, :name) "
                "ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name"
            ),
            {"code": code, "name": name},
        )
    await db.commit()
    logger.info("Initial language seed check complete for top launch languages.")


async def initialize_database(db: AsyncSession) -> None:
    """
    Run at app startup (FastAPI lifespan). Check extensions and seed languages.
    Logs warnings instead of crashing if database is not fully initialized.
    Health endpoints must remain read‑only.
    """
    logger.info("Initializing database...")
    try:
        ext = await check_db_extensions(db)
        if not all(ext.values()):
            missing = ", ".join([k for k, v in ext.items() if not v])
            logger.warning(
                "Missing PostgreSQL extensions: %s. Run 'alembic upgrade head' to install them. "
                "Some features may not work until migrations are applied.",
                missing,
            )
        else:
            logger.info("All required database extensions are installed.")

        await seed_initial_languages(db)
        logger.info("Database initialization complete.")
    except Exception as exc:
        logger.error(
            "Database initialization failed: %s. The app will start but database features may not work. "
            "Check DATABASE_URL and ensure migrations have been run.",
            exc,
            exc_info=True,
        )
