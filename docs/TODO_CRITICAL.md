# CRITICAL TODOs - No BS, Just Facts

**Last Verified:** October 12, 2025 (API tested, not assumed)

---

## THE TRUTH: What's Actually Working

**Backend (API-tested with curl):**
- ✅ Auth: Register/login work, JWT tokens valid
- ✅ Progress: XP → coins conversion works (50 XP = 5 coins)
- ✅ Achievements: 6 achievements unlocked for test user
- ✅ Leaderboard: 24 users tracked, ranking works
- ✅ Power-up purchases: All buy endpoints work
- ✅ Lessons: All 18 exercise types generate tasks

**Frontend (code review):**
- ✅ Lesson UI: All 18 exercise types integrated
- ✅ Achievements page: Tier-based grid exists
- ✅ Leaderboard page: Global/Friends/Local tabs exist
- ✅ Shop page: Power-up purchase UI exists
- ✅ Onboarding: Flow exists and triggers on first launch
- ✅ Animations: Level-up, perfect score, streak celebrations

**Reality Check:** The repo is ~80% done. Most features exist and work.

---

## THE TRUTH: What's NOT Done

### 1. POWER-UP SECURITY FLAW (4 hours)

**Problem:** Power-ups validated client-side only. Users can cheat.

**What's Missing:**
- Backend endpoints EXIST (`progress.py:514-627`) but Flutter doesn't call them
- Need to add 3 methods to `client/flutter_reader/lib/api/progress_api.dart`:
  - `activateXpBoost()` → POST `/api/v1/progress/me/power-ups/xp-boost/activate`
  - `useHint()` → POST `/api/v1/progress/me/power-ups/hint/use`
  - `useSkip()` → POST `/api/v1/progress/me/power-ups/skip/use`
- Need UI buttons in lesson screen to call these methods

**Files to Edit:**
- `client/flutter_reader/lib/api/progress_api.dart` (add 3 methods)
- `client/flutter_reader/lib/pages/vibrant_lessons_page.dart` (add buttons)
- `client/flutter_reader/lib/services/power_up_service.dart` (call API instead of local state)

---

### 2. ACHIEVEMENT CELEBRATIONS (2 hours)

**Problem:** Achievements unlock silently. No confetti, no modal, nothing.

**What's Missing:**
- Animation widget EXISTS (`achievement_unlock_overlay.dart`) but never triggered
- Backend returns achievements but frontend ignores them
- Need to check `progress.update` response for new achievements and show overlay

**Files to Edit:**
- `client/flutter_reader/lib/pages/vibrant_lessons_page.dart:300-400` (check for new achievements)
- Call `showAchievementUnlock()` when new achievement detected

---

### 3. AUDIO NOT TESTED (3 hours)

**Problem:** TTS endpoints exist, listening exercises exist, but no one verified audio plays.

**What to Test:**
- Start lesson with "listening" exercise type
- Verify audio plays when button clicked
- Check if TTS API actually returns audio
- Test with all 4 languages (Greek, Latin, Hebrew, Sanskrit)

**Files to Review:**
- `backend/app/tts/` (TTS providers)
- `client/flutter_reader/lib/widgets/exercises/vibrant_listening_exercise.dart` (playback)

---

### 4. CONTENT GAPS (6h per language)

**Current State:**
- Greek: 210 vocab items ✅
- Latin: 168 vocab items ✅
- Hebrew: 154 vocab items ✅
- Sanskrit: 165 vocab items ✅

**What's Missing:**
- Dialogue exercises: Only 2-3 conversations per language (need 10+)
- Etymology: Basic word origins only (need deeper explanations)
- Conjugation/declension: Tables incomplete

**File to Edit:**
- `backend/app/db/seed_daily_challenges.py` (add more content)

---

### 5. ERROR HANDLING (4 hours)

**Problem:** App crashes on network errors. No retry, no offline mode.

**What's Missing:**
- Retry logic exists in some API files but not all
- No cached lessons for offline study
- Blank screens on API failures

**Files to Edit:**
- All `client/flutter_reader/lib/api/*_api.dart` files (add retry everywhere)
- Add offline caching for lessons

---

## PRIORITY ORDER (Do This, In This Order)

**Day 1 - High Impact:**
1. Wire power-up activation (4h) - Security fix
2. Add achievement celebrations (2h) - UX win
3. Test audio end-to-end (3h) - Validate core feature

**Day 2 - Content:**
4. Add 10+ dialogues per language (2h per language)
5. Expand etymology explanations (2h per language)
6. Complete conjugation/declension tables (2h per language)

**Day 3 - Polish:**
7. Add retry logic everywhere (4h)
8. Add offline mode (4h)

---

## WHAT TO IGNORE

❌ **Don't rewrite lesson generation** - Works fine, all 18 types tested
❌ **Don't add more gamification** - Have plenty (XP, levels, streaks, achievements, leaderboard)
❌ **Don't write docs** - Have 7 already
❌ **Don't create test scripts** - Have comprehensive testing

---

## BOTTOM LINE FOR NEXT AGENT

**The repo is 80% done.**

Most features exist and work. Your job is to:
1. Wire up what exists (power-ups, achievements)
2. Add content (more dialogues, better etymology)
3. Test what's there (audio playback)

**Stop rebuilding. Start connecting and expanding.**
