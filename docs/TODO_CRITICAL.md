# CRITICAL WORK - Next Agent Must Complete

**Last Updated:** 2025-10-16 23:57
**Status:** Core features working, needs UX polish & content expansion

---

## 🔴 HIGH PRIORITY - Code & Features (Not Tests)

### 1. Add More Canonical Texts for Lesson Diversity
**Status**: Only Iliad chapters 1-2 currently loaded
**Impact**: HIGH - lessons repeat same vocab, users get bored
**Time**: 2-3 hours per text

**What to do**:
1. Use `scripts/ingest_iliad_sample.py` as template
2. Find copyright-free texts: Perseus Digital Library, Project Gutenberg
3. Convert to format: (work_id, segment_ref, greek_text, english_translation)
4. Run ingestion script to populate DB
5. Verify lessons pull from new texts

**Suggested texts** (Greek):
- Homer Odyssey Book 1-2
- Hesiod Theogony (first 200 lines)
- Xenophon Anabasis Book 1

**Suggested texts** (Latin):
- Virgil Aeneid Book 1
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

### 4. Profile Page Language Preference Persistence
**Status**: Language selection not saved to backend
**File**: `client/flutter_reader/lib/pages/vibrant_profile_page.dart`
**TODO comment**: "Save language preference to secure storage"

**What to do**:
- Save to backend user preferences when changed
- Load on app startup
- Sync across devices

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

**Oct 16 2025** (evening session):
- ✅ **CRITICAL BUG FIX**: Fixed lesson generation crash in echo provider (line.grc → line.text)
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

**1. Add canonical texts** (2-3 hrs) - MOST IMPORTANT for user experience
**2. Implement missing exercise types** (3-4 hrs) - Reduces repetition
**3. Fix speaking exercise** (1-2 hrs) - Honest UX
**4. Achievement tracking** (1-2 hrs) - Gamification works properly
**5. Error handling** (ongoing) - Polish & robustness

**Focus on CODE, not TESTS or DOCS.**
