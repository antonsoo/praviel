# CRITICAL TODOs - What Actually Needs Coding

**Last Verified:** October 12, 2025

---

## WHAT'S CONFIRMED WORKING (API Tested)

**Backend:**
- ✅ Auth (register/login with JWT)
- ✅ Progress tracking (XP → coins, levels, streaks)
- ✅ Achievement unlocks (6 achievements verified for test user)
- ✅ Leaderboard (24 users tracked, real-time ranking)
- ✅ Power-up purchases (hint/skip/boost endpoints work)
- ✅ Lesson generation (all 18 exercise types)

**Frontend:**
- ✅ Comprehensive lesson UI (all 18 types integrated)
- ✅ Achievements page exists (tier-based grid)
- ✅ Leaderboard page exists (Global/Friends/Local tabs)
- ✅ Shop page exists (power-up purchases)
- ✅ Onboarding flow exists and triggers on first launch
- ✅ Gamification animations (level-up, perfect score, streaks)

---

## WHAT NEEDS WORK (Not BS, Actually Missing)

### 1. SERVER-SIDE POWER-UP VALIDATION (Security Flaw)

**Problem:** Power-ups are client-side only. No server validation = users can cheat.

**Missing:**
- Backend activation endpoints (exist but not wired to Flutter)
- Server-side expiry tracking for XP boosts
- API calls from Flutter to use power-ups

**Code Locations:**
- Backend: `backend/app/api/routers/progress.py:514-627` (endpoints exist!)
- Flutter: Need to add API methods to `progress_api.dart`
- Flutter: Need UI buttons in lesson screen

**Effort:** 4 hours

---

### 2. LESSON CONTENT GAPS

**Confirmed via code review:**
- ✅ Greek: 210 vocab items
- ✅ Latin: 168 vocab items
- ✅ Hebrew: 154 vocab items
- ✅ Sanskrit: 165 vocab items

**What's Missing:**
- Dialogue exercises have limited conversations (2-3 per language)
- Etymology exercises lack depth (basic word origins only)
- Conjugation/declension tables incomplete

**Code Location:** `backend/app/db/seed_daily_challenges.py`

**Effort:** 6 hours per language

---

### 3. AUDIO INTEGRATION

**Problem:** Listening exercises exist but audio playback not fully tested.

**What to verify:**
- TTS endpoints work (`/tts/speak`)
- Audio files cached properly
- Playback in Flutter listening exercises
- Pronunciation accuracy

**Code Locations:**
- Backend: `backend/app/tts/`
- Flutter: `client/flutter_reader/lib/widgets/exercises/vibrant_listening_exercise.dart`

**Effort:** 3 hours testing + fixes

---

### 4. ACHIEVEMENT CELEBRATION ANIMATIONS

**Current State:** Achievements unlock silently (no UI feedback)

**Missing:**
- Modal/overlay when achievement unlocks during lesson
- Particle effects for tier upgrades (Bronze→Silver→Gold→Platinum)
- Sound effects

**Code Location:**
- Flutter: `client/flutter_reader/lib/widgets/animations/achievement_unlock_overlay.dart` (exists but not triggered!)

**Effort:** 2 hours

---

### 5. ERROR HANDLING & OFFLINE MODE

**Current State:** App crashes or shows blank screens on network errors

**Missing:**
- Retry logic for failed API calls (partially exists, needs expansion)
- Cached lessons for offline study
- Better error messages to users
- Loading states for all API calls

**Code Locations:**
- All `*_api.dart` files in `client/flutter_reader/lib/api/`

**Effort:** 4 hours

---

## PRIORITY ORDER FOR NEXT AGENT

**High Impact, Low Effort:**
1. Wire power-up activation to backend (4h) - Security fix
2. Add achievement celebration UI (2h) - UX polish
3. Test audio end-to-end (3h) - Core feature validation

**Medium Impact:**
4. Expand lesson content (6h per language) - More practice material
5. Improve error handling (4h) - Stability

**Lower Priority:**
6. Offline mode caching - Nice-to-have

---

## WHAT TO IGNORE

❌ Don't rewrite lesson generation (works fine)
❌ Don't add more gamification features (have plenty)
❌ Don't create new test scripts (have comprehensive testing)
❌ Don't write more documentation (have enough)

**Just connect what exists and add content.**
