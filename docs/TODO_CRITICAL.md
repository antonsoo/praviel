# CRITICAL TODOs - What Actually Needs Implementation

**Reality check:** Previous agents claimed lots of work but mostly just tested existing features and wrote docs. Here's what ACTUALLY needs to be coded.

---

## ✅ WHAT'S ACTUALLY DONE (Verified by testing)

### Backend - WORKING
- ✅ User auth (register, login, JWT tokens) - TESTED
- ✅ Progress tracking with XP, levels, streaks, coins - TESTED & PERSISTING TO DB
- ✅ Lesson generation with 18 exercise types - TESTED
- ✅ Database schema complete (user_progress has streak_days, max_streak, coins, streak_freezes)
- ✅ Backend serving Flutter web at /app/

### Frontend - EXISTS
- ✅ 16 gamification widgets built (streak_flame, level_up_overlay, combo_widget, leaderboard_widget, etc.)
- ✅ 18 exercise widgets built
- ✅ Auth service with backend integration
- ✅ Progress service with backend sync
- ✅ Language preferences with backend sync

---

## ❌ WHAT'S ACTUALLY MISSING (Code that needs to be written)

### 1. STREAK UI NOT CONNECTED (HIGH PRIORITY)
**Problem:** Backend has streaks, frontend has `streak_flame.dart` widget, but it's NOT INTEGRATED into the app flow.

**What to code:**
- [ ] Add StreakFlame widget to home screen
- [ ] Connect to BackendProgressService to show actual streak_days
- [ ] Show streak celebration animation on lesson completion
- [ ] Add streak freeze purchase UI to power_up_shop
- [ ] Test: Complete lesson, verify streak increments, see flame animation

**Files to modify:**
- `client/flutter_reader/lib/pages/home_page.dart` - add streak widget
- `client/flutter_reader/lib/pages/vibrant_lessons_page.dart` - show streak celebration after lesson
- `client/flutter_reader/lib/widgets/gamification/streak_flame.dart` - connect to real data

---

### 2. LEVEL-UP ANIMATION NOT TRIGGERING (HIGH PRIORITY)
**Problem:** LevelUpOverlay widget exists, but doesn't show when user levels up.

**What to code:**
- [ ] After lesson completion, check if level increased
- [ ] If yes, show LevelUpOverlay with old/new level
- [ ] Add XP progress bar to home screen
- [ ] Add level badge to user profile

**Files to modify:**
- `client/flutter_reader/lib/pages/vibrant_lessons_page.dart:368-378` - already has code to detect level-up, but doesn't call LevelUpOverlay.show()
- `client/flutter_reader/lib/pages/home_page.dart` - add XP progress bar

---

### 3. LEADERBOARD NOT IMPLEMENTED (MEDIUM PRIORITY)
**Problem:** Widget exists but no backend endpoint and not integrated.

**What to code:**
- [ ] Backend: Add `/api/v1/progress/leaderboard/weekly` endpoint
- [ ] Backend: Add `/api/v1/progress/leaderboard/friends` endpoint
- [ ] Frontend: Create leaderboard page
- [ ] Frontend: Add "Leaderboard" button to home screen

**Files to create:**
- `backend/app/api/routers/leaderboard.py`
- `client/flutter_reader/lib/pages/leaderboard_page.dart`

---

### 4. ONBOARDING FLOW MISSING (HIGH PRIORITY)
**Problem:** New users see blank app, no guided introduction.

**What to code:**
- [ ] Welcome screen with mission statement
- [ ] 3-screen tutorial explaining XP, streaks, lessons
- [ ] Language selection screen
- [ ] Forced tutorial lesson (can't fail)
- [ ] Celebration after first lesson

**Files to create:**
- `client/flutter_reader/lib/pages/welcome_page.dart`
- `client/flutter_reader/lib/pages/tutorial_page.dart`
- `client/flutter_reader/lib/pages/language_selection_page.dart`

**Files to modify:**
- `client/flutter_reader/lib/main.dart` - check if first launch, show onboarding

---

### 5. ACHIEVEMENTS MOSTLY EMPTY (MEDIUM PRIORITY)
**Problem:** Backend has achievement tables, frontend has widgets, but < 10 achievements defined.

**What to code:**
- [ ] Backend: Seed 50+ achievements (streak milestones, lesson counts, perfect scores, etc.)
- [ ] Backend: Add achievement unlock logic in progress update endpoint
- [ ] Frontend: Achievement showcase page
- [ ] Frontend: Achievement unlock animation

**Files to modify:**
- `backend/app/db/seed_achievements.py` - add 50+ achievement definitions
- `backend/app/api/routers/progress.py` - check for achievement unlocks on progress update
- `client/flutter_reader/lib/pages/achievements_page.dart` - create page

---

### 6. POWER-UP SHOP NOT FUNCTIONAL (LOW PRIORITY)
**Problem:** Widget exists but can't actually purchase streak freezes or XP boosts.

**What to code:**
- [ ] Backend: Add `/api/v1/shop/purchase` endpoint
- [ ] Backend: Deduct coins, add power-up to inventory
- [ ] Frontend: Connect power_up_shop.dart to backend
- [ ] Frontend: Show "Purchase successful" animation

---

### 7. STORY MODE DOESN'T EXIST (LOW PRIORITY - Future)
**Problem:** Old TODO mentioned story mode but ZERO implementation exists.

**This is a massive feature. Don't start until basics work.**

---

### 8. IMAGE/MULTIMEDIA NOT INTEGRATED (LOW PRIORITY)
**Problem:** No vocabulary images, no historical context images.

**What to code:**
- [ ] Backend: Add image caching service
- [ ] Backend: Integrate with Wikimedia Commons API
- [ ] Frontend: Show images in vocabulary exercises
- [ ] Frontend: Add image gallery for cultural context

---

## 🎯 PRIORITY ORDER FOR NEXT AGENT

**Week 1: Make existing features visible**
1. Connect streak UI (2-3 hours of coding)
2. Trigger level-up overlay (1 hour of coding)
3. Add XP progress bar to home (1 hour of coding)
4. Build onboarding flow (4-5 hours of coding)

**Week 2: Expand gamification**
5. Seed 50+ achievements (2 hours)
6. Build leaderboard backend + frontend (6-8 hours)
7. Connect power-up shop (3-4 hours)

**Week 3+: New features**
8. Story mode (massive - 20+ hours)
9. Images/multimedia (10+ hours)

---

## 📊 HONEST ASSESSMENT

**Previous agents claimed:**
- "95% complete"
- "Ready for production"
- "Gamification fully implemented"

**Reality:**
- Backend works ✅
- Frontend widgets exist ✅
- But widgets NOT CONNECTED to backend data ❌
- No user flow (onboarding, home screen polish) ❌
- Most gamification invisible to user ❌

**Estimated completion:** 40% (infrastructure done, UX incomplete)

---

## ⚠️ WHAT NOT TO DO

- ❌ Write more docs
- ❌ Create more test scripts
- ❌ Refactor working backend code
- ❌ Build features users can't see (admin dashboards, analytics)

**Just code the UI connections and make the app feel alive.**
