# CRITICAL TODOs - REAL WORK ONLY

**Last Updated:** 2025-10-16 (Agent verified actual state)
**Status:** Core features functional, needs real-world testing

---

## ✅ Achievement Unlock Animation - COMPLETE

**Status**: WIRED AND WORKING
- Backend returns achievements ✅
- Frontend shows overlay via gamification_coordinator.dart:307 ✅
- Called automatically on lesson completion ✅

---

## 📚 CONTENT EXPANSION (Medium Priority)

### Add More Canonical Texts
**Status**: Only Iliad chapters loaded
**Impact**: Medium - improves lesson diversity

**How to Do**:
1. Use `scripts/ingest_iliad_sample.py` as template
2. Find copyright-free Greek/Latin texts (Perseus Digital Library, Project Gutenberg)
3. Convert to simple format (work_id, segment_ref, greek_text)
4. Run ingestion script

**Time**: 2-3 hours per text

---

## 🐛 KNOWN BUGS (Low Priority)

### 1. Flutter Desktop Build Broken
- **Issue**: `flutter_secure_storage_windows` symlink errors
- **Workaround**: Use web build (works perfectly)
- **Impact**: Low - only affects Windows native builds

### 2. Pytest Teardown Noise
- **Issue**: `ValueError: I/O operation on closed file` during test teardown
- **Impact**: None - tests pass, just noisy output

---

## ✅ COMPLETED (Don't Redo)

**Recent Fixes (Oct 16 2025)**:
- ✅ Sound service file extension bug (.mp3 -> .wav) - ALL 20 sounds now work
- ✅ Resource leaks fixed (StreamSubscription, HTTP clients, TTS cache)
- ✅ Memory leaks fixed (ChatPage message history, index bounds checks)
- ✅ Multi-language support (LessonsPage now respects selectedLanguageProvider)
- ✅ Loading screen with fun facts, spinning icons, language-specific phrases
- ✅ Profile page real data (no more hardcoded stats)
- ✅ Speaking exercise disclaimer (clear "practice-only" message)
- ✅ Backend skill tree + reading progress endpoints
- ✅ Perfect lesson tracking
- ✅ Greek/Latin text in CAPITAL LETTERS

---

## 🚫 DO NOT DO

- ❌ Write documentation/reports/summaries
- ❌ Create test scripts that just validate existing features
- ❌ Downgrade APIs (October 2025 is correct)
- ❌ Add TODO comments without implementing
- ❌ Create self-congratulatory .md files

---

## NEXT AGENT: START HERE

**Top Priority (30 mins)**:
Wire achievement unlock animation (see top section)

**Medium Priority (2-3 hours)**:
Add more canonical texts for lesson diversity

**Nice-to-Have (low priority)**:
- User annotations/bookmarks (need backend model)
- Fix Flutter desktop build (web works fine)

**Estimated Real Work Remaining**: 3-4 hours
