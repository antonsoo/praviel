# TODO_CRITICAL.md - HONEST ASSESSMENT FOR NEXT AGENT

**Last updated:** 2025-10-22 (After Claude agent gamification session)

**Status:** 🚨 **SCAFFOLDING CREATED BUT NOT INTEGRATED** - Next agent must DO THE REAL WORK

---

## 🔥 CRITICAL: SCAFFOLDING EXISTS BUT ISN'T USED BY THE APP

### What Was Created But NOT Integrated:

The previous agent sessions created a lot of code files, but **THE APP DOESN'T USE THEM YET**. This is just infrastructure/scaffolding. The next agent must integrate everything and make it actually work.

**Files created but not integrated:**

1. **Gamification Pages (4 files)** - Created but app uses old pages:
   - `client/flutter_reader/lib/pages/enhanced_home_page.dart` (741 lines)
   - `client/flutter_reader/lib/pages/enhanced_reader_page.dart` (457 lines)
   - `client/flutter_reader/lib/pages/social_leaderboard_page.dart` (674 lines)
   - `client/flutter_reader/lib/pages/enhanced_profile_page.dart` (820 lines)
   - **Reality**: App still uses `vibrant_home_page.dart`, not `enhanced_home_page.dart`
   - **What's needed**: Replace old pages with new ones in navigation

2. **GoRouter Navigation (3 files)** - Created but app uses legacy navigation:
   - `client/flutter_reader/lib/router/app_router.dart` (292 lines)
   - `client/flutter_reader/lib/widgets/layout/app_shell.dart` (99 lines)
   - `client/flutter_reader/lib/router/README.md`
   - **Reality**: App still uses `ReaderHomePage` with manual tab management
   - **Blocker**: BYOK onboarding logic needs refactoring first
   - **What's needed**: Refactor `main.dart` to use `MaterialApp.router` (see router/README.md)

3. **Gamification Backend API** - Created but NOT TESTED:
   - `backend/app/api/routers/gamification.py` (758 lines with 5 endpoints)
   - **Reality**: Zero tests written, not verified to work with database
   - **What's needed**: Write tests, verify API works, test with real database

4. **Gamification Architecture (3 files)** - Uses MOCK data, not real backend:
   - `client/flutter_reader/lib/features/gamification/domain/models/user_progress.dart`
   - `client/flutter_reader/lib/features/gamification/data/repositories/gamification_repository.dart`
   - `client/flutter_reader/lib/features/gamification/presentation/providers/gamification_providers.dart`
   - **Reality**: Uses `MockGamificationRepository` - returns fake data
   - **What's needed**: Swap to `HttpGamificationRepository`, connect to backend API

5. **Premium Widgets (12 files)** - Created but barely used:
   - `client/flutter_reader/lib/widgets/premium_*.dart` (3D animations, shimmer buttons, etc.)
   - **Reality**: Created in previous session, integrated into 6 pages, but those pages aren't in use
   - **What's needed**: Ensure they work in integrated app

---

## 🔴 CRITICAL BUGS (From Previous Manual Testing - Still Not Fixed)

### 1. TTS Pronunciation Doesn't Work Reliably
**Priority:** CRITICAL
**Status:** ❌ NOT FIXED
**Bug:** "Tap to hear" sometimes silent, listening exercises sound like "incoherent garbage"

**What to fix:**
- [ ] Test TTS API integration for top 4 languages (Latin, Classical Greek, Koine Greek, Biblical Hebrew)
- [ ] Fix TTS provider selection/fallback logic
- [ ] Add better error handling for TTS failures
- [ ] Verify audio plays correctly
- [ ] Check TTS API credentials and rate limits
- [ ] **Currently just shows UI without functionality**

**Files to check:**
- `backend/app/tts/providers/` (all provider files)
- `client/flutter_reader/lib/widgets/exercises/*.dart` (tap to hear sections)

---

### 2. Onboarding Screens Look Like "Boring AI Slop"
**Priority:** HIGH (Investor-critical)
**Status:** ❌ NOT FIXED
**Problem:** User explicitly said UI looks "boring, soulless, AI slop" - not like a "top tech company"

**What to fix:**
- [ ] Redesign onboarding_page.dart with professional UI
- [ ] Use better animations, gradients, typography
- [ ] Add compelling copy about app's unique value proposition
- [ ] Make it feel like Duolingo/Drops/Mondly quality
- [ ] Add micro-interactions and delightful animations

**Files to fix:**
- `client/flutter_reader/lib/pages/onboarding_page.dart`
- `client/flutter_reader/lib/widgets/onboarding/onboarding_flow.dart`

---

### 3. Reader Feature Doesn't Exist Yet
**Priority:** HIGH
**Status:** ❌ NOT IMPLEMENTED
**Problem:** There's a "Reader" tab but no actual curated reading texts

**What to implement:**
- [ ] Create Reader feature with text library
- [ ] Add 10+ authentic texts per language for top 4 languages:
  - Latin: Caesar, Cicero, Virgil, Ovid excerpts
  - Classical Greek: Homer, Plato, Xenophon excerpts
  - Koine Greek: New Testament passages
  - Biblical Hebrew: Torah, Psalms excerpts
- [ ] Add text navigation (by book/chapter/verse or section)
- [ ] Add comprehension exercises after reading
- [ ] Track reading progress

**Files to create/modify:**
- Text library data files (JSON or YAML)
- Reader UI components
- Progress tracking

---

## 🚨 CRITICAL INTEGRATION WORK (What Next Agent MUST Do)

### 4. Connect Flutter Gamification to Backend API
**Priority:** CRITICAL
**Status:** ❌ NOT DONE
**Current State:** Flutter uses mock data, backend API exists but they're not connected

**What to do:**
1. **Update gamification_providers.dart:**
   ```dart
   // Change from:
   final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
     return MockGamificationRepository();
   });

   // To:
   final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
     return HttpGamificationRepository(
       baseUrl: 'http://localhost:8000',  // or production URL
     );
   });
   ```

2. **Test API calls work:**
   - [ ] Test GET /api/v1/gamification/users/{user_id}/progress
   - [ ] Test GET /api/v1/gamification/achievements
   - [ ] Test GET /api/v1/gamification/users/{user_id}/challenges
   - [ ] Test GET /api/v1/gamification/leaderboard
   - [ ] Test POST /api/v1/gamification/users/{user_id}/lessons/complete

3. **Add error handling:**
   - [ ] Handle network errors gracefully
   - [ ] Show user-friendly error messages
   - [ ] Add offline fallback to mock data
   - [ ] Add retry logic for failed requests

4. **Add authentication:**
   - [ ] Pass user auth token in API requests
   - [ ] Handle 401/403 errors
   - [ ] Refresh tokens when needed

**Files to modify:**
- `client/flutter_reader/lib/features/gamification/presentation/providers/gamification_providers.dart`
- `client/flutter_reader/lib/features/gamification/data/repositories/gamification_repository.dart`

---

### 5. Integrate Enhanced Pages into App
**Priority:** CRITICAL
**Status:** ❌ NOT DONE
**Current State:** New pages exist but app uses old navigation

**Option A: Quick Integration (Recommended)**
Replace existing pages without full GoRouter migration:

1. **Replace home page:**
   - In `main.dart`, change `tabs` list to use `EnhancedHomePage` instead of `VibrantHomePage`
   - Remove callbacks to old pages if not needed

2. **Add enhanced profile:**
   - Replace `VibrantProfilePage` with `EnhancedProfilePage`

3. **Add social leaderboard:**
   - Add navigation to `SocialLeaderboardPage` from enhanced home page

**Files to modify:**
- `client/flutter_reader/lib/main.dart` (line 222-264, replace tabs list)

**Option B: Full GoRouter Migration (More work)**
Follow the migration guide in `client/flutter_reader/lib/router/README.md`:

1. **Extract BYOK onboarding** to separate provider
2. **Update main.dart:**
   ```dart
   // Change from:
   return MaterialApp(home: const ReaderHomePage());

   // To:
   return MaterialApp.router(routerConfig: AppRouter.router);
   ```
3. **Remove legacy `ReaderHomePage`** widget
4. **Test all navigation flows**

**Blocker:** BYOK onboarding logic in `ReaderHomePage` needs refactoring first.

---

### 6. Test Backend Gamification API
**Priority:** CRITICAL
**Status:** ❌ NOT TESTED
**Current State:** API code exists but no tests, not verified to work

**What to do:**
1. **Write pytest tests:**
   - [ ] Test GET progress endpoint returns correct data
   - [ ] Test POST complete lesson updates database
   - [ ] Test achievements unlock correctly
   - [ ] Test daily quests auto-generate
   - [ ] Test leaderboard rankings
   - [ ] Test authentication/authorization
   - [ ] Test error cases (invalid user ID, missing data, etc.)

2. **Run manual tests:**
   - [ ] Start backend: `uvicorn app.main:app --reload`
   - [ ] Hit each endpoint with curl/Postman
   - [ ] Verify database updates correctly
   - [ ] Check SQL queries are efficient

3. **Check database migrations:**
   - [ ] Verify all tables exist (user_progress, user_achievement, user_quest, learning_event)
   - [ ] Create migration if new columns needed
   - [ ] Test migration with real database

**Files to create:**
- `backend/app/tests/test_gamification_api.py` (NEW - write this!)

**Commands to test:**
```bash
# Start database
docker compose up -d db

# Run migrations
cd backend
conda activate ancient-languages-py312
alembic upgrade head

# Start server
uvicorn app.main:app --reload

# Test endpoints
curl http://localhost:8000/api/v1/gamification/users/1/progress
curl -X POST http://localhost:8000/api/v1/gamification/users/1/lessons/complete \
  -H "Content-Type: application/json" \
  -d '{"language_code":"lat","xp_earned":50,"words_learned":10,"minutes_studied":15}'
```

---

## 🐛 KNOWN BUGS FROM PREVIOUS TESTING (Already Fixed)

These were fixed in previous sessions:
- ✅ Language selection persistence
- ✅ Vocabulary generation crash
- ✅ Exercise retry/check button logic
- ✅ BYOK popup for new users
- ✅ Script preferences for guest users
- ✅ Lesson completion race condition
- ✅ Language code consistency (grc → grc-cls)

---

## 📊 LANGUAGE SUPPORT ISSUES

### 7. 8 Languages Have YAML Syntax Errors
**Priority:** HIGH
**Status:** ❌ NOT FIXED
**Problem:** 38/46 languages work (83%), but 8 have YAML parsing errors

**What to fix:**
- [ ] Identify which 8 languages have YAML errors
- [ ] Fix boolean parsing issues (like `nci`, `qwh` had)
- [ ] Fix YAML syntax errors in seed files
- [ ] Test all 46 languages work

**Files to check:**
- `backend/app/lesson/seed/canonical_*.yaml` (all language files)
- `backend/app/lesson/seed/daily_*.yaml` (all language files)

**Testing script:**
```bash
cd backend
python scripts/test_all_languages.py  # or PowerShell equivalent
```

---

### 8. Missing Texts for New Languages
**Priority:** MEDIUM
**Status:** ❌ NOT DONE
**Problem:** 46 languages enabled but only 4 have proper seed data

**What to do:**
- [ ] Add canonical texts for priority languages:
  - Sanskrit (Bhagavad Gita, Upanishads)
  - Old Norse (Eddas, Sagas)
  - Egyptian Hieroglyphics (Book of the Dead)
  - Sumerian (Gilgamesh)
- [ ] Create daily lessons for each
- [ ] Test lesson generation works

**Files to create:**
- `backend/app/lesson/seed/canonical_[lang].yaml`
- `backend/app/lesson/seed/daily_[lang].yaml`

---

## 🎨 UI/UX IMPROVEMENTS NEEDED

### 9. App Doesn't Feel Like "Multi-Billion Dollar Tech App"
**Priority:** HIGH (Investor-critical)
**Status:** ⚠️ PARTIAL (Premium widgets created but not enough)

**User's explicit feedback:**
> "YOU NEED TO MAKE MASSIVE UPGRADES"
> "Not cheap AI slop or high-school student work"
> "Multi-billion-dollar-tech-app quality"

**What's been done:**
- ✅ Created 12 premium widget components (3D animations, shimmer, particles)
- ✅ Integrated into 6 pages
- ⚠️ But those pages aren't in use yet

**What still needs to be done:**
- [ ] Integrate premium widgets into actual running app
- [ ] Redesign onboarding to not look "boring"
- [ ] Add micro-interactions everywhere (haptic + sound + animation)
- [ ] Improve typography and spacing
- [ ] Add delightful empty states
- [ ] Add loading skeletons instead of spinners
- [ ] Add success animations (confetti, celebrations)
- [ ] Polish all transitions and animations
- [ ] Make it feel smooth, professional, premium

**Reference apps for inspiration:**
- Duolingo: Gamification, celebrations, smooth animations
- Drops: Beautiful typography, micro-interactions, premium feel
- Mondly: Modern UI, delightful UX, professional polish

---

## 🚀 FEATURES NOT STARTED

### 10. Offline Sync
**Priority:** HIGH
**Status:** ❌ NOT STARTED

**What to implement:**
- [ ] Add connectivity monitoring (connectivity_plus package)
- [ ] Queue API calls when offline
- [ ] Retry queue when back online
- [ ] Show offline indicator in UI
- [ ] Cache lesson data locally
- [ ] Sync progress when reconnected

**Files to create:**
- `client/flutter_reader/lib/services/offline_sync_service.dart`
- `client/flutter_reader/lib/services/connectivity_service.dart`

---

### 11. Analytics Integration
**Priority:** MEDIUM
**Status:** ❌ NOT STARTED

**What to implement:**
- [ ] Add Firebase Analytics or Mixpanel
- [ ] Track user events (lesson start, lesson complete, etc.)
- [ ] Track user properties (level, streak, language)
- [ ] Track screen views
- [ ] Add A/B testing capability
- [ ] Track errors and crashes

**Files to create:**
- `client/flutter_reader/lib/services/analytics_service.dart`

---

## 📝 CODE QUALITY ISSUES

### 12. No Tests for New Features
**Priority:** HIGH
**Status:** ❌ CRITICAL GAP

**What's missing:**
- ❌ No tests for backend gamification API
- ❌ No tests for Flutter gamification providers
- ❌ No tests for enhanced pages
- ❌ No integration tests
- ❌ No widget tests

**What to create:**
1. **Backend tests:**
   - `backend/app/tests/test_gamification_api.py` - Test all 5 endpoints
   - Test database operations
   - Test authentication
   - Test error cases

2. **Flutter tests:**
   - `client/flutter_reader/test/features/gamification/` - Unit tests for providers
   - Widget tests for enhanced pages
   - Integration tests for navigation

**Testing commands:**
```bash
# Backend tests
cd backend
pytest backend/app/tests/test_gamification_api.py -v

# Flutter tests
cd client/flutter_reader
flutter test
```

---

### 13. Code Duplication and Technical Debt
**Priority:** MEDIUM
**Status:** ⚠️ NEEDS REFACTORING

**Issues:**
- Two home pages: `vibrant_home_page.dart` vs `enhanced_home_page.dart`
- Two profile pages: `vibrant_profile_page.dart` vs `enhanced_profile_page.dart`
- Legacy navigation vs GoRouter (two systems)
- Mock repository vs HTTP repository (need to remove mock)

**What to do:**
- [ ] Delete old pages after migration
- [ ] Remove MockGamificationRepository after HTTP integration
- [ ] Consolidate navigation to one system
- [ ] Remove unused imports
- [ ] Run `flutter analyze` and fix all warnings

---

## 🎯 PRIORITY ORDER FOR NEXT AGENT

### MUST DO (Critical for functioning app):

1. **Connect Flutter to Backend API** (Issue #4)
   - Swap MockGamificationRepository → HttpGamificationRepository
   - Test API calls work
   - Add error handling

2. **Test Backend Gamification API** (Issue #6)
   - Write pytest tests
   - Verify database operations
   - Test all 5 endpoints

3. **Integrate Enhanced Pages** (Issue #5)
   - Replace old pages with new ones in navigation
   - OR do full GoRouter migration
   - Test everything works

4. **Fix TTS** (Issue #1)
   - Make "Tap to hear" actually work
   - Test with top 4 languages
   - Fix provider selection logic

### SHOULD DO (High value):

5. **Improve Onboarding UI** (Issue #2)
   - Redesign to not look "boring"
   - Add premium animations
   - Make it feel professional

6. **Fix YAML Language Errors** (Issue #7)
   - Get all 46 languages working
   - Fix syntax errors
   - Test lesson generation

7. **Add Reader Feature** (Issue #3)
   - Implement text library
   - Add 10+ texts per language
   - Add comprehension exercises

### NICE TO HAVE:

8. **Offline Sync** (Issue #10)
9. **Analytics** (Issue #11)
10. **Polish UI/UX** (Issue #9)

---

## 📊 HONEST ASSESSMENT

**What was actually accomplished this session:**
- ✅ Created GoRouter infrastructure (but not integrated)
- ✅ Created backend gamification API (but not tested)
- ✅ Previous session created 4 enhanced pages + 12 premium widgets (but not integrated)

**What was NOT accomplished:**
- ❌ No integration of new features into running app
- ❌ No backend API testing
- ❌ No connection between Flutter and backend
- ❌ No bug fixes from previous testing
- ❌ No UI/UX improvements
- ❌ No offline sync
- ❌ No analytics
- ❌ No language YAML fixes
- ❌ No Reader feature implementation

**Brutal truth:**
The previous agents created a lot of scaffolding and infrastructure, but the app still runs like it did before. The next agent needs to **DO THE INTEGRATION WORK** and **FIX REAL BUGS**, not just create more isolated code files.

---

## 💻 TESTING CHECKLIST FOR NEXT AGENT

Before claiming something is "done", verify:

**Backend:**
- [ ] Run: `pytest backend/app/tests/test_gamification_api.py -v`
- [ ] All tests pass
- [ ] Database updates correctly
- [ ] API returns correct data
- [ ] Error handling works

**Flutter:**
- [ ] Run: `flutter analyze`
- [ ] Zero errors, zero warnings
- [ ] Run: `flutter test`
- [ ] All tests pass
- [ ] Run app: `flutter run`
- [ ] Manually test new features work
- [ ] Test on multiple screen sizes

**Integration:**
- [ ] Start backend: `uvicorn app.main:app --reload`
- [ ] Start Flutter: `flutter run`
- [ ] Complete a lesson - verify XP updates in backend
- [ ] Check leaderboard - verify data from backend
- [ ] Check achievements - verify unlock logic works
- [ ] Test offline - verify graceful degradation

**User Experience:**
- [ ] App doesn't crash
- [ ] No "incoherent garbage" from TTS
- [ ] Onboarding doesn't look "boring"
- [ ] Animations are smooth (60fps)
- [ ] No blank screens or error messages
- [ ] Everything feels polished and professional

---

## 🎬 COMMANDS FOR NEXT AGENT

### Start Backend:
```bash
# Start database
docker compose up -d db

# Activate Python environment
conda activate ancient-languages-py312

# Run migrations
cd backend
alembic upgrade head

# Start server
uvicorn app.main:app --reload
```

### Start Flutter:
```bash
cd client/flutter_reader

# Run on web
flutter run -d web-server --web-port=3001

# Or run on desktop
flutter run -d windows  # or macos, linux
```

### Run Tests:
```bash
# Backend tests
cd backend
pytest app/tests/ -v

# Flutter tests
cd client/flutter_reader
flutter test
flutter analyze
```

---

## 📚 USEFUL FILES FOR NEXT AGENT

**Navigation/Routing:**
- `client/flutter_reader/lib/main.dart` - App entry point, tab navigation
- `client/flutter_reader/lib/router/app_router.dart` - GoRouter config (not integrated)
- `client/flutter_reader/lib/router/README.md` - Migration guide

**Gamification (Frontend):**
- `client/flutter_reader/lib/features/gamification/` - All gamification code
- `client/flutter_reader/lib/pages/enhanced_*.dart` - New pages (not integrated)

**Gamification (Backend):**
- `backend/app/api/routers/gamification.py` - 5 API endpoints (not tested)
- `backend/app/db/user_models.py` - Database models

**Languages:**
- `backend/app/lesson/seed/canonical_*.yaml` - Canonical texts per language
- `backend/app/lesson/seed/daily_*.yaml` - Daily lessons per language
- `backend/app/lesson/language_config.py` - Language definitions

**TTS:**
- `backend/app/tts/providers/` - TTS provider implementations
- `client/flutter_reader/lib/widgets/exercises/` - Exercise widgets with "tap to hear"

---

## 🚨 FINAL WARNING FOR NEXT AGENT

**DO NOT:**
- ❌ Create more isolated code files without integrating them
- ❌ Write "TODO" comments - actually implement the feature
- ❌ Skip writing tests
- ❌ Claim something is "done" without running it
- ❌ Ignore the user's feedback about UI looking "boring"
- ❌ Add more scaffolding without connecting it

**DO:**
- ✅ Integrate the existing gamification features
- ✅ Connect Flutter to backend API
- ✅ Write and run tests
- ✅ Fix the TTS bug
- ✅ Improve the onboarding UI
- ✅ Make the app feel professional
- ✅ Test everything works end-to-end

**Remember:** The user explicitly said they want "tons of code" that actually improves the app, not more scaffolding. The next agent must focus on **INTEGRATION, TESTING, and BUG FIXES**.

---

**End of TODO_CRITICAL.md**
