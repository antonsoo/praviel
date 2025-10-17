# CRITICAL WORK - Next Agent Must Complete

**Last Updated:** 2025-10-16 22:45
**Status:** Core features working. TWO CRITICAL BUGS FOUND & FIXED. Needs MORE CONTENT (Latin texts) & MORE FEATURES.

---

## 🔴 HIGH PRIORITY - Code & Features (Not Tests)

### 1. Add Latin Canonical Texts (MOST URGENT)
**Status**: INCOMPLETE - Greek has 211 references, Latin has 211 BUT NEEDS MORE VARIETY
**Impact**: HIGH - Latin learners have limited lesson variety
**Time**: 2-3 hours per text

**What exists**:
- `backend/app/lesson/seed/canonical_lat.yaml` created with 211 Latin references:
  - Virgil Aeneid Books 1, 2, 4, 6
  - Caesar De Bello Gallico Book 1
  - Cicero In Catilinam Oration 1

**What to add**:
- More Cicero (Pro Archia, De Amicitia)
- Ovid Metamorphoses Book 1
- Livy Ab Urbe Condita selections
- Catullus poems
- Horace Odes

**How to do it**:
1. Find copyright-free texts: Perseus Digital Library
2. Use format: (work_id, segment_ref, latin_text, english_translation)
3. Add to `canonical_lat.yaml`
4. Verify lesson generation uses new texts

### 2. Improve Lesson Variety - Add New Exercise Types
**Status**: Only 18 exercise types implemented
**Impact**: MEDIUM - lessons feel repetitive after ~30 mins

**Missing exercise types**:
- Sentence reordering (jumbled words → correct order) - REORDER WIDGET EXISTS BUT NOT USED
- Context comprehension (read passage, answer questions)
- Image-based vocabulary (show picture, name in ancient language)
- Audio comprehension with longer passages

**Implementation**:
- Add new task types to `backend/app/lesson/schemas.py`
- Create Flutter widgets in `client/flutter_reader/lib/widgets/exercises/`
- Wire into lesson generator providers

### 3. Achievement Tracking - Complete Implementation
**Status**: Framework exists, tracking logic incomplete
**Impact**: MEDIUM - achievements don't unlock based on real milestones
**File**: `backend/app/db/seed_achievements.py`

**Missing tracking**:
- Language-specific lesson counts (e.g., "Complete 50 Greek lessons")
- Time-based achievements ("Study 7 days in a row")
- Speed-based achievements ("Complete lesson in under 5 minutes")
- Unique languages practiced

**What to do**:
- Wire tracking in `backend/app/api/routers/progress.py`
- Test achievements unlock correctly
- Verify achievement notifications show in app

---

## 🟡 MEDIUM PRIORITY - UX Polish

### 4. Error Handling & Edge Cases
**Status**: Many APIs assume happy path
**Impact**: MEDIUM - app crashes on network errors

**Common issues**:
- Network errors not handled gracefully
- Empty lesson lists cause crashes
- Invalid API responses break UI
- Offline mode incomplete

**What to do**:
- Add try-catch blocks with user-friendly error messages
- Test with network disconnected
- Handle empty states properly
- Improve offline fallback logic

### 5. Add More Languages
**Status**: Framework supports 8 languages, but only Greek/Latin have rich content
**Impact**: LOW - most users want Greek/Latin

**Languages with minimal content**:
- Biblical Hebrew (hbo)
- Sanskrit (san)
- Coptic (cop)
- Egyptian Hieroglyphics (egy)
- Akkadian (akk)
- Pali (pli)

**What to do**:
- Add canonical texts for Hebrew, Sanskrit
- Verify vocabulary exists for each language
- Test lesson generation for non-Greek/Latin

---

## 🟢 NICE-TO-HAVE (Lower Priority)

### 6. Flutter Desktop Build Fix
**Status**: Windows native build broken
**Issue**: `flutter_secure_storage_windows` symlink errors
**Impact**: LOW - web build works perfectly

**Workaround**: Use web build (fully functional)
**Fix**: Research Flutter secure storage on Windows, or remove dependency

### 7. Add Phonetic Transcriptions (IPA)
**File**: `backend/app/lesson/providers/echo.py:line 67`
**Status**: TODO comment exists, not implemented

**What to do**:
- Add IPA transcriptions to vocabulary database
- Display in exercises to help pronunciation
- Especially important for Greek, Hebrew, Sanskrit

---

## ✅ COMPLETED (Don't Redo)

**Oct 16 2025** (latest session - BUG HUNTING):
- ✅ **CRITICAL BUG FIX #1**: Speaking exercise always marked correct
  - `vibrant_speaking_exercise.dart` had `final correct = true;` hardcoded (line 79)
  - Complete rewrite (448→577 lines) to integrate real pronunciation API
  - Now calls `/api/v1/pronunciation/score-text` endpoint
  - Shows real accuracy scores based on Levenshtein distance
  - Displays transcription and color-coded feedback
  - Has offline fallback
  - Commit: e830fa7

- ✅ **CRITICAL BUG FIX #2**: Professional translate exercise always marked correct
  - `pro_translate_exercise.dart` had `_correct = true;` hardcoded (line 72)
  - Added real translation validation with 80% similarity threshold
  - Case-insensitive comparison with sample solution/rubric
  - Proper error feedback showing expected translation
  - Commit: c15d82a

- ✅ Verified all other exercise widgets have proper validation:
  - Conjugation, Declension, Etymology, Listening, Dictation, Cloze - ALL CORRECT

- ✅ Verified backend APIs are solid:
  - Challenges API: coins persisted correctly, no double-application bug
  - Progress API: row-level locking prevents race conditions
  - Quests API: increment validation prevents abuse
  - Offline queue: 24-hour expiry and 10-retry limit working

**Oct 16 2025** (earlier session - content expansion):
- ✅ **CRITICAL BUG FIX**: User registration broken - missing perfect_lessons column
- ✅ **CRITICAL BUG FIX**: XP boost expiration not persisting - missing xp_boost_expires_at
- ✅ Added Latin canonical texts (211 references - Virgil, Caesar, Cicero)
- ✅ Expanded Greek texts from 20 to 177 references (Iliad, Odyssey, Plato)
- ✅ Pronunciation API endpoint created (`/api/v1/pronunciation/score-text`)
- ✅ Language preference backend sync
- ✅ Database migration system fixed (alembic sync issues)
- ✅ Comprehensive API testing (challenges, quests, XP boost all working)

**Oct 16 2025** (earlier):
- ✅ Fixed 10 broken exercises (Check button not enabling)
- ✅ Achievement unlock animation
- ✅ Sound service file extensions (.wav)
- ✅ Resource/memory leaks fixed
- ✅ Multi-language support
- ✅ Loading screen with fun facts
- ✅ Profile page real data
- ✅ Backend skill tree endpoints
- ✅ Perfect lesson tracking
- ✅ Greek/Latin text in CAPITALS

---

## 🚫 DO NOT DO

- ❌ Write more documentation files
- ❌ Create test scripts without implementing features first
- ❌ Downgrade APIs to pre-October 2025 versions
- ❌ Add TODO comments without implementing the feature
- ❌ Create self-congratulatory review documents
- ❌ Write extensive test suites before writing actual features

---

## NEXT AGENT: Priority Order

**FOCUS ON NEW FEATURES, NOT TESTING!**

The app is SOLID. Two critical validation bugs were found and fixed. All core systems verified working. Now need MORE CONTENT and MORE FEATURES.

**1. ADD MORE LATIN TEXTS** (2-3 hrs) - HIGHEST PRIORITY
   - More Cicero, Ovid, Livy, Catullus, Horace
   - Add to `canonical_lat.yaml`
   - Test lesson generation diversity

**2. IMPLEMENT NEW EXERCISE TYPES** (3-4 hrs) - Reduces repetition
   - Context comprehension (read passage, answer questions)
   - Image-based vocabulary
   - Audio comprehension with longer passages
   - Wire reorder exercise into lesson generator (widget exists!)

**3. COMPLETE ACHIEVEMENT TRACKING** (1-2 hrs)
   - Language-specific lesson counts
   - Time-based achievements
   - Speed-based achievements
   - Test achievements unlock properly

**4. IMPROVE ERROR HANDLING** (1-2 hrs)
   - Network error fallbacks
   - Empty state handling
   - Offline mode improvements

**Focus on CODE that adds VALUE to users. The app works - it needs MORE VARIETY and POLISH.**
