from pathlib import Path

from arq import cron
from arq.connections import RedisSettings

from app.core.config import settings
from app.db.session import SessionLocal
from app.ingestion.jobs import ingest_iliad_sample


async def run_ingest_sample(ctx):
    tei = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1.xml"
    tok = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1_tokens.xml"  # optional
    async with SessionLocal() as db:
        return await ingest_iliad_sample(db, tei, tok)


class WorkerSettings:
    functions = [run_ingest_sample]
    redis_settings = RedisSettings.from_dsn(settings.REDIS_URL)
    cron_jobs = [cron(run_ingest_sample, minute=0, run_at_startup=False)]
