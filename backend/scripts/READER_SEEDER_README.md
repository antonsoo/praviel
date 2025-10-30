# Reader Texts Database Seeder

## Overview

This seeder populates the database with **71 classical texts across 7 languages** for the Reader feature.

## Languages Covered

- **Latin** (lat): 10 texts (Virgil, Ovid, Caesar, Tacitus, etc.)
- **Koine Greek** (grc-koi): 10 texts (Septuagint, NT, Josephus, Plutarch, etc.)
- **Classical Greek** (grc-cls): 10 texts (Homer, Hesiod, Sophocles, Plato, etc.)
- **Biblical Hebrew** (hbo): 10 texts (Genesis, Exodus, Isaiah, Psalms, etc.)
- **Classical Chinese** (lzh): 10 texts (Analects, Tao Te Ching, Art of War, etc.)
- **Pali** (pli): 10 texts (Dīgha Nikāya, Dhammapada, Jātaka Tales, etc.)
- **Classical Sanskrit** (san): 11 texts (Mahābhārata, Rāmāyaṇa, Bhagavad Gītā, etc.)

## How to Run

### Recommended Method

```bash
source praviel-env/bin/activate
python backend/scripts/seed_reader_texts.py
```

### Alternative (from backend directory)

```bash
cd backend
source ../praviel-env/bin/activate
python scripts/seed_reader_texts.py
```

## What Gets Created

- 1 source document ("reader-fallback") with CC BY-SA 3.0 license
- 71 text works (TextWork table)
- ~220 sample text segments (TextSegment table)
- Each text has 3-4 sample segments from the opening of the work

## Verification

After running the seeder, verify it worked:

```bash
# Test the Reader API
curl "http://127.0.0.1:8002/reader/texts?language=lat"
curl "http://127.0.0.1:8002/reader/texts?language=grc-koi"
curl "http://127.0.0.1:8002/reader/texts?language=lzh"
```

Each should return a JSON list of texts for that language.

## Troubleshooting

**Error: Language not found**
- Run database migrations first: `alembic upgrade head`
- Ensure languages are seeded: Check app/db/init_db.py runs on startup

**Error: Source already exists**
- The seeder is idempotent - it skips existing works
- Safe to run multiple times

**Connection errors**
- Verify PostgreSQL is running
- Check DATABASE_URL in .env file

## Next Steps

After seeding:

1. Test Reader API endpoints (see Verification above)
2. Launch Flutter app - Reader catalog should now work
3. Browse texts in the app's Reader page
4. Text structure and segments endpoints should return real data

## Note

This creates **sample content only**. For production:
- Replace with real full-text sources (Perseus, Project Gutenberg, etc.)
- Add complete metadata (dates, manuscript info, etc.)
- Include full morphological annotations
- Add vector embeddings for semantic search
