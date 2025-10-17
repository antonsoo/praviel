# CRITICAL WORK - Next Agent Must Complete

**Last Updated:** 2025-10-17 01:40
**Status:** Core features working & tested. Needs MORE CONTENT (Latin texts) & MORE FEATURES (new exercise types)

---

## 🔴 HIGH PRIORITY - Code & Features (Not Tests)

### 1. Add More Canonical Texts for Lesson Diversity
**Status**: PARTIALLY COMPLETE - 177 Greek references now loaded (Iliad, Odyssey, Plato)
**Impact**: MEDIUM - still need Latin texts
**Time**: 2-3 hours per Latin text

**What to do**:
1. Use `scripts/ingest_iliad_sample.py` as template
2. Find copyright-free Latin texts: Perseus Digital Library, Project Gutenberg
3. Convert to format: (work_id, segment_ref, latin_text, english_translation)
4. Run ingestion script to populate DB
5. Create `backend/app/lesson/seed/canonical_lat.yaml` similar to canonical_grc.yaml

**Suggested texts** (Latin):
- Virgil Aeneid Book 1 (HIGH PRIORITY - most requested)
- Caesar Gallic Wars Book 1
- Cicero First Catiline Oration

### 2. Improve Lesson Variety - More Exercise Types
**Status**: Only 18 exercise types implemented
**Impact**: MEDIUM - lessons feel repetitive after ~30 mins

**Missing exercise types** (check FUTURE_FEATURES.md):
- Image-based vocabulary (show picture, name in Greek)
- Sentence reordering (jumbled words → correct order)
- Morphology drills (decline nouns, conjugate verbs)
- Context comprehension (read passage, answer questions)

**Implementation**:
- Add new task types to `backend/app/lesson/schemas.py`
- Create Flutter widgets in `client/flutter_reader/lib/widgets/exercises/`
- Update lesson generator to include new types

### 3. Speaking Exercise - Real Pronunciation Checking
**Status**: Currently a placeholder with disclaimer (no real checking)
**Impact**: MEDIUM - users expect real feedback

**Current state**:
- `vibrant_speaking_exercise.dart` line 212: "This is practice-only"
- Always marks answers as correct (dishonest UX)

**What to do**:
- Integrate real speech-to-text API (OpenAI Whisper, Google Speech)
- Compare user pronunciation to expected phonetics
- Give actual feedback: "Good!" vs "Try pronouncing alpha as 'ah'"

---

## 🟡 MEDIUM PRIORITY - UX Polish

### 5. Achievement Tracking Improvements
**Status**: Partially implemented, missing tracking logic
**File**: `backend/app/db/seed_achievements.py`

**Missing**:
- Track language-specific lesson counts (line ~50)
- Track time-based achievements (line ~75)
- Track lesson completion times (line ~100)
- Track unique languages practiced (line ~125)

**What to do**:
- Implement tracking in `backend/app/api/routers/progress.py`
- Update achievement check logic to use real data
- Test that achievements actually unlock correctly

### 6. Error Handling & Edge Cases
**Status**: Many APIs assume happy path

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

---

## 🟢 NICE-TO-HAVE (Lower Priority)

### 7. Flutter Desktop Build Fix
**Status**: Windows native build broken
**Issue**: `flutter_secure_storage_windows` symlink errors
**Impact**: LOW - web build works perfectly

**Workaround**: Use web build (fully functional)
**Fix**: Research Flutter secure storage on Windows, or remove dependency

### 8. Add Phonetic Transcriptions
**File**: `backend/app/lesson/providers/echo.py:line 67`
**TODO**: Add phonetic guides for words

**What to do**:
- Add IPA transcriptions to vocab database
- Display in exercises to help pronunciation
- Especially important for Greek, Hebrew, Sanskrit

---

## ✅ COMPLETED (Don't Redo)

**Oct 16 2025** (latest session - bug hunting & testing):
- ✅ **CRITICAL BUG FIX**: User registration completely broken - missing perfect_lessons column
  - Database was out of sync with SQLAlchemy models
  - Created migration 103232290532_add_perfect_lessons_to_user_progress.py
  - Tested end-to-end with real curl commands
- ✅ **CRITICAL BUG FIX**: XP boost expiration not persisting (missing xp_boost_expires_at column)
  - Migration file existed but was never applied to database
  - Manually added column and synced alembic_version
- ✅ Database migration system fixed (alembic was out of sync)
- ✅ Comprehensive API testing with real curl calls:
  - Daily challenges: generation, completion, rewards (100% working)
  - XP boost: purchase, activation, expiration persistence (100% working)
  - Quest system: activation, progress tracking (100% working)
  - Lesson generation: GPT-5 API (50s response, working)
- ✅ Expanded canonical Greek texts from 20 to 177 references (11x increase)
  - Iliad Books 1, 2, 6, 22, 24
  - Odyssey Books 1, 5, 9, 12
  - Plato: Apology, Republic, Symposium
- ✅ Wired language preference backend sync (vibrant_profile_page.dart)

**Oct 16 2025** (evening session):
- ✅ Fixed lesson generation crash in echo provider (line.grc → line.text)
- ✅ Created migration for xp_boost_expires_at column (enables XP boost persistence)

**Oct 16 2025** (earlier):
- ✅ Fixed 10 broken exercises (Check button not enabling)
- ✅ Achievement unlock animation wired and working
- ✅ Sound service file extensions fixed (.wav)
- ✅ Resource leaks fixed (HTTP clients, TTS cache)
- ✅ Memory leaks fixed (ChatPage message history)
- ✅ Multi-language support (selectedLanguageProvider)
- ✅ Loading screen with fun facts
- ✅ Profile page shows real data (no hardcoded stats)
- ✅ Backend skill tree + reading progress endpoints
- ✅ Perfect lesson tracking
- ✅ Greek/Latin text in CAPITALS (historically accurate)

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

**DO MORE FEATURES, LESS TESTING!** Previous agent spent too much time testing existing features.

**1. ADD LATIN TEXTS** (2-3 hrs) - MOST IMPORTANT - Greek is done, Latin is empty
   - Create canonical_lat.yaml with Virgil Aeneid references
   - Ingest into database
   - Test lesson generation uses Latin texts

**2. IMPLEMENT NEW EXERCISE TYPES** (3-4 hrs) - Reduces repetition
   - Sentence reordering widget
   - Morphology drills (decline/conjugate)
   - Context comprehension questions
   - Image-based vocabulary

**3. FIX SPEAKING EXERCISE** (1-2 hrs) - Currently dishonest (always says correct)
   - Integrate OpenAI Whisper or Google Speech API
   - Compare pronunciation to expected phonetics
   - Give real feedback

**4. ACHIEVEMENT TRACKING** (1-2 hrs) - Wire tracking logic
   - Language-specific lesson counts
   - Time-based achievements
   - Test achievements unlock properly

**Focus on CODE, not TESTS or DOCS. The app works - it needs MORE CONTENT and MORE FEATURES.**
