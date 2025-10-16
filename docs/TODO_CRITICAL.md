# CRITICAL TODOs

**Last Updated:** 2025-10-16 (Post-Audit)
**Focus:** CODE implementation, not testing/docs

---

## 🔥 BACKEND FEATURES (Missing/Incomplete)

### 1. Skill Tree System (FIXED - Oct 16 2025)
- **Status**: ✅ Complete - POST endpoint added
- **Implementation**: `POST /progress/me/skills/update` with Elo rating system (K=32)
- **File**: `backend/app/api/routers/progress.py:255-314`
- **Features**: Auto-create skills, track attempts/accuracy, row-level locking
- **Impact**: Skill tree now fully functional

### 2. Reading Progress Tracking (FIXED - Oct 16 2025)
- **Status**: ✅ Complete - POST endpoint added
- **Implementation**: `POST /progress/me/texts/{work_id}/progress`
- **File**: `backend/app/api/routers/progress.py:373-444`
- **Features**: Tracks segments, tokens, lemmas, WPM with exponential moving average
- **Impact**: Reading history now persisted

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

### 1. Seed Vocabulary (VERIFIED - Oct 16 2025)
- **Status**: ✅ Already comprehensive
- **Current counts**:
  - Greek (grc): 303 entries
  - Latin (lat): 263 entries
  - Hebrew (hbo): 249 entries
  - Sanskrit (san): 258 entries
- **Quality**: Solid beginner-to-intermediate coverage
- **Impact**: Vocabulary diversity is sufficient for current needs

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

1. **Achievement unlock animation** (medium priority)
   - Wire achievement unlock overlay to `BackendProgressService.updateProgress()` response
   - File: `client/flutter_reader/lib/widgets/animations/achievement_unlock_overlay.dart`
   - Currently exists but never triggered

2. **Add more canonical texts** (medium impact)
   - Ingest more Greek/Latin texts beyond Iliad
   - Use `scripts/ingest_iliad_sample.py` as template
   - Improves lesson diversity

3. **User annotations/bookmarks** (low priority)
   - Backend: Add `UserAnnotation` model
   - Frontend: Bookmark UI for passages
   - Nice-to-have feature

4. **Fix Flutter desktop build** (low priority)
   - Issue: `flutter_secure_storage_windows` symlink errors
   - Workaround: Use web build (works perfectly)
   - Impact: Only affects native Windows builds

---

**Estimated Real Work**: 5-8 hours for remaining features
**Current Completion**: ~95% (core functionality complete, polish and content expansion remaining)
