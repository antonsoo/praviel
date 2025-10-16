# CRITICAL TODOs

**Last Updated:** 2025-10-16
**Focus:** CODE implementation, not testing/docs

---

## 🔥 BACKEND FEATURES (Incomplete)

### 1. Text Reading System (0% done)
- **Models exist but NO endpoints**: `TextWork`, `TextSegment`, `Token` in database
- **Need**: API endpoints to fetch texts, track reading progress, save vocabulary
- **Files**: Create `backend/app/api/routers/texts.py`
- **Impact**: High - core feature is completely missing

### 2. Skill Tree System (Database only)
- **Models exist**: `UserSkill` table exists
- **Need**: Endpoints to get/update skills, unlock progression
- **Files**: Wire up skill tracking in `backend/app/api/routers/progress.py`
- **Impact**: Medium - gamification feature incomplete

### 3. Achievement System (Partially done)
- **Done**: 50+ achievements defined in `backend/app/db/seed_achievements.py`
- **Missing**: Many unlock triggers not wired to actual events
- **Need**: Complete event-based unlocking for all achievement types
- **Impact**: Medium - users can't earn most achievements

### 4. Vocabulary Tracking (Missing)
- **Need**: Add `words_learned` field to UserProgress
- **Need**: Track unique vocabulary items across lessons
- **Need**: Display in profile page (currently hardcoded "47 words")
- **Impact**: Low - nice-to-have metric

---

## 🎨 FLUTTER UI/UX (Incomplete)

### 1. Speaking Exercise (FAKE)
- **Current**: Always marks answers as correct (no speech recognition)
- **File**: `client/flutter_reader/lib/widgets/exercises/vibrant_speaking_exercise.dart:77-79`
- **Need**: Real speech-to-text comparison or remove exercise type
- **Impact**: High - dishonest to users

### 2. Profile Page Hardcoded Stats
- **Current**: "47 words learned", "3/15 achievements" are fake
- **File**: `client/flutter_reader/lib/pages/vibrant_profile_page.dart:366,375`
- **Need**: Connect to real `/progress/me` API data
- **Impact**: Medium - breaks trust

### 3. Achievement Unlock Animation (Not triggered)
- **Current**: Animation exists but never shown to users
- **Files**: `client/flutter_reader/lib/widgets/animations/achievement_unlock_overlay.dart`
- **Need**: Wire to `BackendProgressService.updateProgress()` achievements response
- **Impact**: Low - polish

---

## 📚 CONTENT EXPANSION

### 1. Expand Seed Vocabulary
- **Current**: ~50-100 words per language in `backend/app/lesson/seed/daily_*.yaml`
- **Need**: 500+ core vocabulary items for Greek, Latin, Hebrew, Sanskrit
- **Impact**: High - lessons are repetitive

### 2. Add Canonical Texts
- **Current**: Only Iliad sample in database
- **Need**: More Greek/Latin texts for cloze/translation exercises
- **Files**: Use `scripts/ingest_iliad_sample.py` as template
- **Impact**: Medium - improves lesson quality

---

## 🐛 CRITICAL BUGS

### 1. Flutter Desktop Build Broken
- **Issue**: `flutter_secure_storage_windows` symlink errors
- **Doc**: `client/flutter_reader/FLUTTER_GUIDE.md`
- **Impact**: High - Windows builds fail

### 2. Pytest Crashes
- **Issue**: `ValueError: I/O operation on closed file` during teardown
- **Impact**: Medium - blocks automated testing

---

## ✅ COMPLETED (Don't redo)

- ✅ Historical script generation (Greek capitals, Latin with V, etc.)
- ✅ Language-agnostic lesson system (works for all 4 languages)
- ✅ Offline queue service implementation
- ✅ Level-up event streaming
- ✅ Lesson history API endpoint (`GET /progress/me/history`)
- ✅ Time tracking fixes
- ✅ Chat API endpoints (working at `/chat/converse`)
- ✅ 21 database migrations (complete)

---

## 🚫 DO NOT DO

- ❌ Write more documentation/reports/summaries
- ❌ Create test scripts that just validate what already works
- ❌ Downgrade APIs to older versions
- ❌ Add TODO comments without implementing the feature

---

**NEXT AGENT: Focus on implementing the incomplete backend features (text reading, skill tree) and fixing the Flutter speaking exercise.**
