import asyncio
from pathlib import Path

from app.core.config import settings
from app.db.init_db import initialize_database
from app.db.session import SessionLocal
from app.ingestion.jobs import ingest_iliad_sample


async def main():
    tei = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1.xml"
    tok = Path(settings.DATA_VENDOR_ROOT) / "perseus" / "iliad" / "book1_tokens.xml"
    async with SessionLocal() as db:
        await initialize_database(db)
        res = await ingest_iliad_sample(db, tei, tok if tok.exists() else tei)
        print(res)


if __name__ == "__main__":
    asyncio.run(main())
