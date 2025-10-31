# Prompt for Next AI Agent Session

**Context**: Web Reader currently shows only 3 placeholder lines per text. Users cannot read actual classical texts. This is the #1 blocking issue for launch.

---

## Task: Ingest Perseus Classical Text Corpus

### Objective
Download and ingest complete classical texts from Perseus Digital Library into the Reader database, prioritizing the top 4 languages (Classical Latin, Koine Greek, Classical Greek, Biblical Hebrew).

### Step 1: Download Perseus Corpus
```bash
cd /home/antonsoloviev/work/projects/praviel_files/praviel
bash scripts/download_perseus_corpus.sh
```

This downloads:
- `data/vendor/perseus/canonical-greekLit/` (Greek Literature)
- `data/vendor/perseus/canonical-latinLit/` (Latin Literature)

### Step 2: Parse and Ingest Texts

**Requirements**:
1. Parse TEI XML files from Perseus repos
2. Extract work metadata (author, title, language)
3. Extract all text segments with proper citation structure (book.line, book.chapter, etc.)
4. Store in database: `TextWork`, `SourceDoc`, `TextSegment` tables
5. Include lemma/morphology attributes from XML (`@lemma`, `@ana`) for morphology lookup

**Key Files**:
- `backend/app/ingestion/sources/perseus.py` - Existing parser (needs expansion)
- `backend/app/db/models.py:129-153` - Database schema
- `backend/scripts/seed_reader_texts.py` - Reference for DB insertion

**TEI XML Structure** (Perseus format):
```xml
<TEI>
  <text>
    <body>
      <div type="edition" n="urn:cts:greekLit:tlg0012.tlg001:">
        <div type="textpart" subtype="book" n="1">
          <l n="1">μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος</l>
          <l n="2">οὐλομένην, ἣ μυρί' Ἀχαιοῖς ἄλγε' ἔθηκε</l>
        </div>
      </div>
    </body>
  </text>
</TEI>
```

**Priority Texts** (from `docs/TOP_TEN_WORKS_PER_LANGUAGE.md`):
- **Latin**: Aeneid, Metamorphoses, Gallic Wars, Annals
- **Classical Greek**: Iliad, Odyssey, Histories (Herodotus), Republic (Plato)
- **Koine Greek**: New Testament, Septuagint, Parallel Lives

### Step 3: Add Latin/Greek Interpunct Display

After corpus is ingested, add interpunct (·) rendering:

**Frontend** (`client/flutter_reader/lib/pages/reading_page.dart`):
- Around line 128, modify word display logic
- Insert interpunct between words for Latin/Greek variants
- Only for languages: `lat`, `grc-cls`, `grc-koine`

**Backend** (`backend/app/ingestion/sources/perseus.py`):
- Around line 280, handle interpunct during normalization
- Prevent interpunct from becoming separate token

### Testing
```bash
# After ingestion
cd backend
source praviel-env/bin/activate
python -c "
from app.db.engine import create_asyncpg_engine
from app.db.models import TextWork
from sqlalchemy import select
import asyncio

async def check():
    engine = create_asyncpg_engine()
    async with engine.begin() as conn:
        result = await conn.execute(select(TextWork))
        works = result.all()
        print(f'Total works: {len(works)}')
        for work in works[:5]:
            print(f'  - {work.author}: {work.title}')

asyncio.run(check())
"
```

### Success Criteria
1. Database contains 50+ complete texts (not just 3 lines)
2. Reader shows full chapters/books when browsing
3. Morphology data available (lemma/morph fields populated)
4. Latin/Greek texts display with interpuncts

### Resources
- Perseus TEI Guidelines: https://www.tei-c.org/release/doc/tei-p5-doc/en/html/
- Existing ingestion: `backend/app/ingestion/sources/perseus.py`
- Database schema: `backend/app/db/models.py`

---

**Estimated time**: 4-6 hours

**Note**: Focus on Latin and Greek first (top priority languages). Hebrew/Sanskrit can be added later.
