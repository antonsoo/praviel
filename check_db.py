#!/usr/bin/env python3
import sys
sys.path.insert(0, "backend")

import asyncio
from sqlalchemy import text
from app.db.session import SessionLocal

async def check():
    try:
        async with SessionLocal() as session:
            # Check text segments
            result = await session.execute(text("SELECT COUNT(*) FROM text_segment"))
            segments = result.scalar()
            print(f"[OK] Database connected")
            print(f"[OK] Text segments: {segments}")

            # Check if there are tokens with lemmas
            result = await session.execute(
                text("SELECT COUNT(*) FROM token WHERE lemma IS NOT NULL")
            )
            tokens_with_lemma = result.scalar()
            print(f"[OK] Tokens with lemma: {tokens_with_lemma}")

            if segments > 0 and tokens_with_lemma > 0:
                print("[OK] Database has data ready for analysis")
                return True
            else:
                print("[WARN] Database may need data ingestion")
                return False

    except Exception as e:
        print(f"[FAIL] Database error: {e}")
        return False

if __name__ == "__main__":
    result = asyncio.run(check())
    sys.exit(0 if result else 1)
