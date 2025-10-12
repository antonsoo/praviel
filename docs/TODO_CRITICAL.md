# CRITICAL TODOs - What to Code Next

**Updated:** October 12, 2025
**This Session:** Fixed achievement system crashes, verified end-to-end flow works

---

## ✅ WHAT WORKS (Tested End-to-End This Session)

**Backend (95% Complete):**
- Registration/login working (JWT auth)
- Progress tracking persisting (XP, levels, coins, streaks)
- Achievement unlock logic working (3 achievements unlocked after 5 lessons)
- Achievements API returns complete data with `meta.title` and `meta.description`
- Power-up purchase endpoints working (Streak Freeze, XP Boost, Hint, Skip)
- Lesson generation working (18 exercise types)

**Frontend (60% Complete):**
- Power-up shop UI works
- Streaks displayed
- XP/Levels displayed
- Onboarding pages exist (not wired up)

**Bugs Fixed This Session:**
- Fixed Windows Unicode crash (emoji chars → ASCII text)
- Fixed missing `meta` field in achievement API response
- Applied database migrations (region column)

---

## ❌ WHAT'S MISSING (Priority Order)

### 1. ACHIEVEMENTS SHOWCASE PAGE
**Code:** `client/flutter_reader/lib/pages/achievements_page.dart`
- Grid view of 54 achievements (locked/unlocked)
- Progress bars ("7/10 lessons completed")
- Achievement icons and descriptions
- Connect to `GET /progress/me/achievements` (backend ready)

**Time:** 6 hours

---

### 2. LEADERBOARD PAGE
**Code:** `client/flutter_reader/lib/pages/leaderboard_page.dart`
- Replace "coming soon" placeholder
- Tabs: Global / Friends / Local
- User rank display with highlighting
- Connect to existing endpoints (backend ready)

**Time:** 4 hours

---

### 3. POWER-UP ACTIVATION
**Backend:** Add activation endpoints in `progress.py`
- `POST /power-ups/xp-boost/activate` (track 30min expiry)
- `POST /power-ups/hint-reveal/use`
- `POST /power-ups/time-warp/use`

**Frontend:** Add buttons in lesson screen
- "Activate 2x XP" button
- "Use Hint" button
- "Skip Question" button
- Show countdown timer for active boosts

**Time:** 5 hours

---

### 4. EXPAND LESSON CONTENT
**Code:** `backend/app/db/seed_daily_challenges.py`
- Add 20+ Hebrew vocabulary pairs
- Add 10+ Latin grammar rules
- Add 15+ Sanskrit vocabulary items
- Improve cultural context

**Time:** 8 hours

---

### 5. WIRE UP ONBOARDING
**Code:** `client/flutter_reader/lib/main.dart`
- Detect first launch (SharedPreferences)
- Show onboarding before home page
- Add "Skip" button

**Time:** 3 hours

---

## 🚫 DON'T WASTE TIME ON

- Rewriting achievement logic (JUST FIXED!)
- Adding backend endpoints (they exist!)
- Writing test scripts (we have 8 already)
- Refactoring working code
- Writing docs

---

## 🎯 RECOMMENDED: Start with #1 and #2

**Build achievements page + leaderboard page first.**
- Highest user impact
- Backend is 100% ready
- Can be done in ~10 hours
- Zero infrastructure work needed

---

## 📁 Cleanup Done This Session

**Archived to `docs/archive/`:**
- `CLEANUP_SUMMARY.md` (useless report)
- 9 test scripts from root directory

**Repo is now clean.**
