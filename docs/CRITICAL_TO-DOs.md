# Critical TO-DOs

**Last updated:** 2025-10-31 (afternoon)

## 🔴 P0 — Blocking Launch

### Reader Corpus Data (CRITICAL)
**Problem**: Reader shows only 3 placeholder lines per text. No actual classical texts available.

**Root Cause**: `backend/scripts/seed_reader_texts.py` inserts placeholder data only.

**Solution**:
1. Download Perseus corpus: `bash scripts/download_perseus_corpus.sh`
2. Create TEI XML parser for Perseus format
3. Ingest full texts into database (TextWork, SourceDoc, TextSegment tables)

**Resources**:
- Greek: https://github.com/PerseusDL/canonical-greekLit
- Latin: https://github.com/PerseusDL/canonical-latinLit
- License: CC-BY-SA-4.0
- Existing parser: `backend/app/ingestion/sources/perseus.py` (needs expansion)

**Priority**: Top 4 languages: Classical Latin, Koine Greek, Classical Greek, Biblical Hebrew

---

## 🟡 P1 — UX Improvements

### Latin/Greek Interpunct Display
**Problem**: Reader doesn't show interpunct (·) to separate words in Latin/Ancient Greek.

**Files to modify**:
- `client/flutter_reader/lib/pages/reading_page.dart:128` (display logic)
- `backend/app/ingestion/sources/perseus.py:280` (ingestion normalization)

**Notes**: Interpunct should appear between words for `lat` and `grc-*` language codes.

---

## 📝 Notes

**Recent Fixes (Oct 31)**:
- ✅ Auth token race condition fixed (commit `f421a62`)
- ✅ Lesson generation error logging improved
- ⚠️ Lesson generation may still fail (check backend logs for diagnostics)

*(Remove items as soon as resolved; archive historical context in `docs/archive/`.)*
