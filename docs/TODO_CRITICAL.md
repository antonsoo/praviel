# CRITICAL TODOs - What Actually Needs Work

**Last Updated:** December 11, 2024
**Status:** Field parsing bug fixed, lesson generation working for all 4 languages

---

## ✅ ACTUALLY COMPLETED (Verified in Code)

1. **Field Name Mismatch Fixed** - `client/flutter_reader/lib/models/lesson.dart` now accepts both `native` and language-specific fields (`grc`, `lat`, `hbo`, `san`)
2. **All 4 Languages Working** - Greek, Latin, Hebrew, Sanskrit all generate lessons correctly
3. **Flutter Analyzer** - 0 issues
4. **API Exception Handling** - Unified exception class across all API clients
5. **Power-ups Integrated** - Backend returns power-up data, UI displays it
6. **Achievements Working** - Backend tracks and awards achievements
7. **Leaderboard Functional** - Global rankings displayed

---

## 🚨 ACTUAL CODE WORK NEEDED (Not Just Testing!)

### 1. Content Expansion - HIGHEST PRIORITY 🔥

**Why:** Sparse vocab means boring, repetitive lessons

**Current vocab counts (verified in YAML files):**
- Greek: 210 words
- Latin: 168 words
- Hebrew: 154 words
- Sanskrit: 165 words

**What to add:**
- 500+ more vocabulary words per language (daily_grc.yaml, daily_lat.yaml, etc.)
- 20+ dialogue conversations per language with natural flow
- 10+ etymology explanations per language
- Complete conjugation tables (at least 10 verbs per language)
- Complete declension tables (at least 10 nouns per language)
- 50+ grammar examples (correct/incorrect pairs)

**Files to modify:**
- `backend/app/lesson/seed/daily_grc.yaml`
- `backend/app/lesson/seed/daily_lat.yaml`
- `backend/app/lesson/seed/daily_hbo.yaml`
- `backend/app/lesson/seed/daily_san.yaml`

### 2. Improve Lesson Quality - HIGH PRIORITY

**Why:** Content feels templated and mechanical

**What to code:**
- Add difficulty progression logic (beginner content should be easier than advanced)
- Implement spaced repetition algorithm (show previously-failed words more often)
- Add context-aware exercise generation (group related words together)
- Improve dialogue realism (current dialogues are stilted)

**Files to modify:**
- `backend/app/lesson/providers/echo.py` - Make content more dynamic
- `backend/app/lesson/models.py` - Add difficulty/context metadata
- `backend/app/lesson/router.py` - Implement SRS logic

### 3. Fix OpenAI/Anthropic/Google Providers - MEDIUM PRIORITY

**Current status:** OpenAI returns 500 errors, others untested

**What to investigate & fix:**
- Debug OpenAI provider to see actual error message
- Test Anthropic provider with actual API calls
- Test Google provider with actual API calls
- Ensure all 3 providers return consistent JSON structure

**Files:**
- `backend/app/lesson/providers/openai.py`
- `backend/app/lesson/providers/anthropic.py`
- `backend/app/lesson/providers/google.py`

### 4. Improve UI/UX - MEDIUM PRIORITY

**Why:** Flutter app exists but needs polish

**What to code:**
- Add loading states for ALL async operations (lesson generation, achievement unlocks, etc.)
- Improve error messages (show user-friendly text, not "500 Internal Server Error")
- Add animations for achievement celebrations
- Add confetti/particles when leveling up
- Improve exercise feedback (better "correct" / "incorrect" animations)
- Add progress indicators during lesson (e.g., "Question 3 of 10")

**Files to modify:**
- `client/flutter_reader/lib/widgets/exercises/*_exercise.dart` (all 18 files)
- `client/flutter_reader/lib/screens/lesson_screen.dart`
- `client/flutter_reader/lib/widgets/achievement_celebration.dart`

### 5. Add Missing Exercise Type Features - MEDIUM PRIORITY

**What's missing:**
- **Listening exercises**: Audio playback not verified to work
- **Speaking exercises**: No microphone recording implemented
- **Dialogue exercises**: Missing branching conversation logic
- **Etymology exercises**: No interactive word breakdown UI

**Files to create/modify:**
- `client/flutter_reader/lib/widgets/exercises/vibrant_listening_exercise.dart` - Add audio player
- `client/flutter_reader/lib/widgets/exercises/vibrant_speaking_exercise.dart` - Add mic recording
- `client/flutter_reader/lib/widgets/exercises/vibrant_dialogue_exercise.dart` - Add conversation flow
- `client/flutter_reader/lib/widgets/exercises/vibrant_etymology_exercise.dart` - Add word breakdown UI

### 6. Optimize Performance - LOW PRIORITY

**What to optimize:**
- Reduce lesson generation time (currently takes 2-5 seconds)
- Cache previously generated lessons client-side
- Lazy-load vocabulary content instead of loading all at once
- Add database indexes for faster queries

**Files:**
- `backend/app/lesson/router.py` - Add caching
- `backend/app/db/models.py` - Add indexes
- `client/flutter_reader/lib/services/lesson_cache.dart` - Create caching layer

---

## ❌ DO NOT WASTE TIME ON

1. **More test scripts** - We have enough already (moved to docs/archive)
2. **More documentation** - CLAUDE.md, BIG-PICTURE_PROJECT_PLAN.md, AGENTS.md are sufficient
3. **Status reports** - No more INTEGRATION_STATUS.md, SESSION_SUMMARY.md, etc.
4. **Minor refactoring** - Code structure is fine, focus on features
5. **New gamification** - Power-ups, achievements, leaderboard already exist

---

## 🎯 NEXT AGENT: DO THIS

1. **Add 500+ vocab words per language** (2-3 hours) - Real content makes the app actually useful
2. **Fix OpenAI provider** (1 hour) - Debug actual error, ensure GPT-5 API works
3. **Improve UI polish** (2 hours) - Loading states, animations, better error messages
4. **Test audio playback** (30 min) - Verify TTS works end-to-end
5. **Add difficulty progression** (1 hour) - Make beginner lessons easier, advanced harder

**Focus:** CODE, not testing. Write features, not reports.

---

## 📊 WHAT PREVIOUS AGENTS CLAIMED vs REALITY

**They said:** "Everything is integrated and working!"

**Reality:**
- ✅ Basic lesson generation works
- ✅ Field name bug is NOW fixed (this session)
- ❌ Content is sparse (needs 3x more vocab)
- ❌ OpenAI provider broken (500 errors)
- ❌ Audio untested
- ❌ UI needs polish

**Verdict:** Foundation is solid, but needs real content and polish to be investor-ready.

---

**Bottom line:** Stop writing docs and tests. Write CONTENT and FEATURES.
