# Critical TO-DOs

**Last updated:** 2025-10-31 (evening)

## 🔴 P0 — Blocking Launch

### Token/Morphology Data Extraction
**Problem**: All 791 ingested works show 0 tokens. Morphology lookup unavailable.

**Solution**: Extract `@lemma` and `@ana` attributes from Perseus TEI XML `<w>` elements and populate Token table during ingestion.

**File**: `backend/scripts/ingest_perseus_corpus.py` (modify `extract_all_segments()`)

---

## 📝 Notes

**Completed (Oct 31)**:
- ✅ Perseus corpus ingested: 791 works, 279.6k segments (Greek: 627, Latin: 164)
- ✅ Interpunct display for Latin/Greek texts
- ✅ Session rollback bug fixed in ingestion script

*(Remove items as soon as resolved; archive historical context in `docs/archive/`.)*
