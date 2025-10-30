# Morphology Data Ingestion Guide

**Status:** Infrastructure ready, awaiting Perseus data files

## Overview

The Reader feature's word-tap morphology lookup requires the `token` table to be populated with lemmatized and morphologically tagged words from classical texts.

## Current State

### ✅ Infrastructure Complete

1. **Database Schema**: `token` table exists with proper fields:
   - `surface`, `surface_nfc`, `surface_fold` - word forms
   - `lemma`, `lemma_fold` - dictionary forms
   - `msd` (JSONB) - morphological/syntactic description

2. **Ingestion Code**: [backend/app/ingestion/sources/perseus.py](../backend/app/ingestion/sources/perseus.py)
   - `iter_tokens()` function extracts `<w lemma="..." ana="...">` from TEI XML

3. **Analysis Code**: [backend/app/ling/morph.py](../backend/app/ling/morph.py)
   - `analyze_tokens()` queries token table
   - Falls back to CLTK lemmatizer for Greek

4. **API Endpoint**: `/reader/analyze` uses morphology data

### ❌ Missing: Annotated Perseus Data

The repository only contains unannotated samples:
- `tests/fixtures/perseus_sample_annotated_greek.xml` - has structure but no `<w>` tags

## Required Data Files

### Perseus Digital Library Format

```xml
<TEI xmlns="http://www.tei-c.org/ns/1.0">
  <text xml:lang="grc">
    <body>
      <div type="book" n="1">
        <l n="1">
          <w lemma="μῆνις" ana="n-s---fa-">Μῆνιν</w>
          <w lemma="ἀείδω" ana="v-s---pa-">ἄειδε</w>
          <pc>,</pc>
          <w lemma="θεά" ana="n-s---fv-">θεὰ</w>
        </l>
      </div>
    </body>
  </text>
</TEI>
```

### Key Attributes

- `lemma`: Dictionary form (e.g., "μῆνις" for "Μῆνιν")
- `ana`: Perseus morphological tag (e.g., "n-s---fa-" = noun, singular, feminine, accusative)

## Data Sources

### 1. Perseus Digital Library (Recommended)

**Repository**: https://github.com/PerseusDL/canonical-greekLit
**License**: CC BY-SA 4.0

Contains fully annotated Greek and Latin texts:
- Homer (Iliad, Odyssey)
- Virgil (Aeneid)
- Sophocles, Euripides, etc.

**Download**:
```bash
git clone https://github.com/PerseusDL/canonical-greekLit.git
git clone https://github.com/PerseusDL/canonical-latinLit.git
```

### 2. PROIEL Treebank

**Repository**: https://github.com/proiel/proiel-treebank
**License**: CC BY-NC-SA 3.0

Biblical texts in Greek, Latin, Armenian, Gothic:
- New Testament (Greek)
- Vulgate (Latin)

## Ingestion Pipeline

### Step 1: Download Perseus Data

```bash
cd backend/data
git clone --depth 1 https://github.com/PerseusDL/canonical-greekLit.git
git clone --depth 1 https://github.com/PerseusDL/canonical-latinLit.git
```

### Step 2: Create Ingestion Script

Use existing code from `pipeline/perseus_ingest.py` as template:

```python
# backend/scripts/ingest_perseus_tokens.py
from pathlib import Path
from app.ingestion.sources.perseus import read_tei, iter_tokens
from app.db.models import TextSegment, Token
from sqlalchemy import create_engine

def ingest_tokens_from_tei(tei_path: Path, segment_id: int):
    """Ingest tokens from Perseus TEI XML into token table."""
    root = read_tei(tei_path)

    tokens = []
    for idx, (surf_nfc, surf_fold, lemma_nfc, lemma_fold, msd) in enumerate(iter_tokens(root)):
        tokens.append({
            'segment_id': segment_id,
            'idx': idx,
            'surface': surf_nfc,
            'surface_nfc': surf_nfc,
            'surface_fold': surf_fold,
            'lemma': lemma_nfc,
            'lemma_fold': lemma_fold,
            'msd': msd
        })

    # Bulk insert tokens
    # ...
```

### Step 3: Run Ingestion

```bash
cd backend
source praviel-env/bin/activate
python scripts/ingest_perseus_tokens.py --tei data/canonical-greekLit/data/tlg0012/tlg001/*.xml
```

### Step 4: Verify Data

```sql
-- Check token count
SELECT COUNT(*) FROM token;

-- Sample tokens with lemmas
SELECT surface, lemma, msd->>'ana' as morph
FROM token
WHERE lemma IS NOT NULL
LIMIT 10;
```

## Testing Morphology Lookups

Once data is ingested:

```bash
# Test the analyze endpoint
curl -X POST "http://localhost:8000/reader/analyze" \
  -H "Content-Type: application/json" \
  -d '{"text": "Μῆνιν ἄειδε", "language": "grc-cls"}'
```

Expected response:
```json
{
  "tokens": [
    {"text": "Μῆνιν", "lemma": "μῆνις", "morph": "n-s---fa-"},
    {"text": "ἄειδε", "lemma": "ἀείδω", "morph": "v-s---pa-"}
  ],
  "retrieval": [...]
}
```

## Fallback: CLTK Lemmatizer

If Perseus data is unavailable, the system falls back to CLTK:

```bash
pip install cltk
python -m cltk.download greek_models_cltk
```

CLTK provides lemmas but not full morphological analysis.

## Future Enhancements

1. **Latin Support**: Add PROIEL Latin morphology
2. **Biblical Languages**: Hebrew, Aramaic, Syriac morphology
3. **Sanskrit**: DCS (Digital Corpus of Sanskrit) integration
4. **Machine Learning**: Train custom lemmatizers for less-resourced languages

## References

- Perseus Digital Library: https://www.perseus.tufts.edu/
- Perseus TEI Guidelines: https://github.com/PerseusDL/tei-conversion-tools
- PROIEL Treebank: https://proiel.github.io/
- CLTK Documentation: https://docs.cltk.org/

---

**Next Steps**: Download Perseus canonical texts and run ingestion pipeline.
