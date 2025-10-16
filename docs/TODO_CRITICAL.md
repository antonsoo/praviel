# CRITICAL TODOs

**Last Updated:** 2025-10-16 (Post-Audit)
**Focus:** CODE implementation, not testing/docs

---

## 🔥 BACKEND FEATURES (Missing/Incomplete)

### 1. Skill Tree System (Database exists, endpoints missing)
- **Models exist**: `UserSkill` table in database
- **Need**: Create endpoints to get/update skills, display skill progression
- **Files**: Add routes to `backend/app/api/routers/progress.py`
- **Impact**: Medium - gamification feature incomplete, users can't see skill tree

### 2. Reading Progress Tracking (Missing)
- **Current**: Users can read texts but progress isn't saved
- **Need**: Track which passages user has read, vocabulary extraction
- **Files**: Enhance `backend/app/api/routers/reader.py` with progress tracking
- **Impact**: Medium - users lose reading history

### 3. User Annotations/Bookmarks (Missing)
- **Need**: Let users bookmark passages and add notes
- **Impact**: Low - nice-to-have feature

---

## 🎨 FLUTTER UI/UX (Fake/Hardcoded)

### 1. Speaking Exercise (FIXED - Oct 16 2025)
- **Status**: ✅ Fixed with clear disclaimer
- **Changes**: Added prominent info box stating "practice-only, no pronunciation checking"
- **File**: `client/flutter_reader/lib/widgets/exercises/vibrant_speaking_exercise.dart:398-427`
- **Note**: Speaking exercises are NOT in default exercise types, only appear if explicitly requested
- **Impact**: User expectations now correctly set

### 2. Profile Page Stats (FIXED - Oct 16 2025)
- **Status**: ✅ Fixed - now shows real data
- **Changes**: Replaced hardcoded "47 words" with actual `totalLessons` and `perfectLessons` from ProgressService
- **File**: `client/flutter_reader/lib/pages/vibrant_profile_page.dart:362-381`
- **Impact**: Users now see their real progress

### 3. Achievement Unlock Animation (Low Priority)
- **Current**: Animation exists but never shown
- **Files**: `client/flutter_reader/lib/widgets/animations/achievement_unlock_overlay.dart`
- **Need**: Wire to `BackendProgressService.updateProgress()` response
- **Impact**: Low - polish

---

## 📚 CONTENT EXPANSION

### 1. Expand Seed Vocabulary (High Impact)
- **Current**: ~50-100 words per language in `backend/app/lesson/seed/daily_*.yaml`
- **Need**: 500+ core vocabulary for each language (Greek, Latin, Hebrew, Sanskrit)
- **Why**: Lessons become repetitive with small vocabulary pool
- **Impact**: HIGH - directly affects lesson quality

### 2. Add More Canonical Texts (Medium Impact)
- **Current**: Only Iliad loaded in database
- **Need**: More Greek/Latin texts for diverse lesson material
- **Files**: Use `scripts/ingest_iliad_sample.py` as template
- **Impact**: Medium - improves lesson diversity

---

## 🐛 KNOWN BUGS

### 1. Flutter Desktop Build Broken
- **Issue**: `flutter_secure_storage_windows` symlink errors
- **Status**: Documented in `client/flutter_reader/FLUTTER_GUIDE.md`
- **Workaround**: Use web build instead
- **Impact**: Medium - Windows native builds fail

### 2. Pytest Teardown Crashes (Non-blocking)
- **Issue**: `ValueError: I/O operation on closed file` during teardown
- **Impact**: Low - tests still pass, just noisy output

---

## ✅ COMPLETED (Recent fixes - don't redo)

- ✅ **Perfect lessons tracking** (Oct 16 2025) - Backend now tracks perfect lessons
- ✅ **Online status** (Oct 16 2025) - Friends show as online if active in last 15min
- ✅ **Reader API** (Oct 16 2025) - Fixed segment ordering bug
- ✅ **`.env` parsing** (Oct 16 2025) - Removed inline comments that broke Pydantic
- ✅ Language-agnostic lesson system (works for all 4 languages)
- ✅ Offline queue service implementation
- ✅ Level-up event streaming
- ✅ Lesson history API endpoint
- ✅ Chat API endpoints
- ✅ 21 database migrations (all synced)

---

## 🚫 DO NOT DO

- ❌ Write more documentation/reports/summaries
- ❌ Create test scripts that just validate what already works
- ❌ Downgrade APIs to older versions (October 2025 is correct)
- ❌ Add TODO comments without implementing the feature
- ❌ Create "HONEST_REVIEW.md" or similar self-congratulatory docs

---

## NEXT AGENT PRIORITIES (Ranked)

1. **Fix fake speaking exercise** (high priority, breaks trust)
   - Simplest: Remove it or mark "Coming Soon"
   - Best: Implement simple phonetic matching

2. **Expand vocabulary seed data** (high impact on quality)
   - Add 500+ words per language to `backend/app/lesson/seed/`

3. **Fix hardcoded profile stats** (medium priority)
   - Wire to real API data in `vibrant_profile_page.dart`

4. **Implement skill tree endpoints** (medium priority)
   - Add GET/POST routes to `backend/app/api/routers/progress.py`

5. **Add reading progress tracking** (medium priority)
   - Track which passages users have read

---

**Estimated Real Work**: 10-15 hours of focused coding
**Current Completion**: ~85% (core systems work, content and polish needed)
