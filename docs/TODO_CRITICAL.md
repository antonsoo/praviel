# TODO_CRITICAL.md - REAL ISSUES FROM MANUAL TESTING

**Last updated:** 2025-10-22 (After user's manual testing at 6:37 PM)

**Status:** CRITICAL BUGS FOUND - Next agent must CODE fixes, not write reports

---

## 🔴 CRITICAL BUGS (Must fix before launch)

### 1. Language Selection Doesn't Persist
**Priority:** CRITICAL
**Test log:** Issue #1
**Bug:** User selects Latin in onboarding, but app defaults to Classical Greek everywhere

**What to fix:**
- [ ] Check language persistence in onboarding_page.dart
- [ ] Fix language_controller.dart to actually save selected language
- [ ] Verify language preference loads correctly on app startup
- [ ] Test: Select Latin → Should stay Latin everywhere (not default to Greek)

**Files to check:**
- client/flutter_reader/lib/pages/onboarding_page.dart
- client/flutter_reader/lib/services/language_controller.dart
- client/flutter_reader/lib/services/language_preferences.dart

---

### 2. Vocabulary Generation Still Broken
**Priority:** CRITICAL
**Test log:** Issue #14
**Bug:** "Failed to generate vocabulary: No output_text found in OpenAI response"

**What happened:** Previous agent claimed to fix this (commit 6981604) but it's STILL BROKEN

**What to fix:**
- [ ] Actually test vocabulary generation with real API call
- [ ] Debug OpenAI response extraction in vocabulary_engine.py
- [ ] Verify fix works for ALL providers (OpenAI, Anthropic, Google)
- [ ] Add better error logging to see actual API response
- [ ] Test with actual API key, not just code review

**Files to fix:**
- backend/app/lesson/vocabulary_engine.py (line 200+)
- backend/app/lesson/vocabulary_router.py

---

### 3. Retry/Check Button Broken After Wrong Answer
**Priority:** CRITICAL
**Test log:** Issue #12
**Bug:** User gets answer wrong, tries to fix it, clicks Check - nothing happens. Can only proceed by clicking Skip.

**What to fix:**
- [ ] Debug exercise_control.dart check button logic
- [ ] Fix retry state management in lessons_page.dart
- [ ] Verify canCheck() returns true when user edits answer
- [ ] Test: Get wrong answer → Edit → Click Check → Should validate new answer

**Files to fix:**
- client/flutter_reader/lib/widgets/exercises/exercise_control.dart
- client/flutter_reader/lib/pages/lessons_page.dart (line 600-700)

---

### 4. BYOK Popup Doesn't Show for New Users
**Priority:** HIGH
**Test log:** Issue #5
**Bug:** New users don't get prompted to enter API key after onboarding

**What to fix:**
- [ ] Check byok_controller.dart initialization logic
- [ ] Add BYOK sheet auto-display for new/guest users
- [ ] Show notification/banner if no API key detected
- [ ] Test: New user completes onboarding → BYOK sheet should appear

**Files to fix:**
- client/flutter_reader/lib/services/byok_controller.dart
- client/flutter_reader/lib/widgets/byok_onboarding_sheet.dart
- client/flutter_reader/lib/pages/onboarding_page.dart

---

### 5. Script Preference Fails: "Not authenticated"
**Priority:** HIGH
**Test log:** Issue #6
**Bug:** Settings → Script display → Script preference shows "Failed to load preference: Not authenticated"

**What to fix:**
- [ ] Fix authentication check in settings_page.dart
- [ ] Allow guest users to set script preferences locally
- [ ] Fix backend API to allow unauthenticated script preference reads
- [ ] Test: Guest user → Settings → Script preference → Should work

**Files to fix:**
- client/flutter_reader/lib/pages/settings_page.dart
- backend/app/api/routers/ (preferences endpoints)

---

### 6. New Question Appears After Lesson Completion
**Priority:** MEDIUM
**Test log:** Issue #13
**Bug:** Lesson completion popup shows, but new question also renders on screen

**What to fix:**
- [ ] Fix race condition in lessons_page.dart completion logic
- [ ] Ensure no new task renders when _isLessonComplete is true
- [ ] Test: Complete last question → Only completion screen, no new question

**Files to fix:**
- client/flutter_reader/lib/pages/lessons_page.dart (completion logic)

---

## 🟡 HIGH PRIORITY (Blocking investor demo)

### 7. TTS Pronunciation Doesn't Work Reliably
**Priority:** HIGH
**Test log:** Issues #10, #11
**Bug:** "Tap to hear" sometimes silent, listening exercises sound like "incoherent garbage"

**What to fix:**
- [ ] Test TTS API integration for top 4 languages
- [ ] Fix TTS provider selection/fallback logic
- [ ] Add better error handling for TTS failures
- [ ] Verify audio plays correctly for Latin, Greek, Hebrew, Sanskrit
- [ ] Check TTS API credentials and rate limits

**Files to check:**
- backend/app/tts/providers/ (all provider files)
- client/flutter_reader/lib/widgets/tts_play_button.dart

---

### 8. Language Code "GRC" Too Generic
**Priority:** HIGH (Future-proofing)
**Test log:** Issue #3
**Problem:** We have Classical Greek (grc) and Koine Greek (grc-koi) - confusing

**What to fix:**
- [ ] Rename Classical Greek: grc → grc-cls or grc-attic
- [ ] Update language codes everywhere:
  - client/flutter_reader/lib/models/language.dart
  - backend/app/lesson/language_config.py
  - All lesson seed files
  - Database migrations
- [ ] Test all features work with new codes

**Impact:** Large refactoring, but necessary

---

## 🎨 UI/UX IMPROVEMENTS (Investor-critical)

### 9. Onboarding Screens Are Generic/Boring
**Priority:** HIGH
**Test log:** Issues #2, #4
**Problem:** User says UI looks like "boring, soulless, AI slop"

**What to fix:**
- [ ] Redesign onboarding_page.dart with professional UI
- [ ] Use better animations, gradients, typography
- [ ] Add compelling copy about app's unique value
- [ ] Make it feel like "top tech company" quality
- [ ] Reference Duolingo, Drops, Mondly for inspiration

**Files to fix:**
- client/flutter_reader/lib/pages/onboarding_page.dart
- client/flutter_reader/lib/widgets/onboarding/onboarding_flow.dart

---

### 10. Add "Learn More About Language" Feature
**Priority:** MEDIUM
**Test log:** Issue #7
**Feature:** Show language history, importance, famous quotes

**What to implement:**
- [ ] Create LanguageInfoSheet widget with:
  - When/where language was spoken
  - Why it's important
  - Fun facts
  - 2-3 famous quotes in original + translation
- [ ] Add "Learn more" button to language cards
- [ ] Design beautiful modal/sheet

**New files to create:**
- client/flutter_reader/lib/widgets/language_info_sheet.dart
- client/flutter_reader/lib/data/language_descriptions.dart

---

### 11. Background Music System
**Priority:** LOW (Can wait)
**Test log:** Issue #8
**Feature:** Background music with on/off controls

**What to implement:**
- [ ] Create audio service for background music
- [ ] Add folders for soundtracks
- [ ] Add bottom-right controls
- [ ] Make disabled by default

---

## ✅ VERIFICATION TASKS

### 12. Fill in the Blank Exercise
**Priority:** MEDIUM
**Test log:** Issue #9

**What to do:**
- [ ] Test fill in the blank exercise works
- [ ] Verify for top 4 languages
- [ ] Fix any bugs found

---

### 13. Reader Has 10+ Texts Per Language
**Priority:** MEDIUM
**Test log:** Issue #15

**What to verify:**
- [ ] Run app and open Reader
- [ ] Verify each top 4 language has 10+ texts
- [ ] Test texts actually load and display

---

## 📋 FOR NEXT AI AGENT

### Your Mission: FIX BUGS, DON'T WRITE REPORTS

### Priority Order:
1. Language selection persistence (Issue #1) - CRITICAL
2. Vocabulary generation (Issue #2) - CRITICAL
3. Retry/check button (Issue #3) - CRITICAL
4. BYOK popup (Issue #4) - HIGH
5. Script preference auth (Issue #5) - HIGH
6. TTS/pronunciation (Issue #7) - HIGH
7. UI/UX improvements (Issues #9, #10) - HIGH

### How to Work:
1. RUN THE APP YOURSELF
2. TEST WITH REAL API KEYS
3. FIX, TEST, VERIFY
4. WRITE CODE, NOT REPORTS

### Testing Commands:
```bash
# Backend
docker compose up -d
cd backend && conda activate ancient-languages-py312
alembic upgrade head
uvicorn app.main:app --reload

# Frontend
cd client/flutter_reader
flutter run -d web-server --web-port=3001
```

### Critical Test Cases:
1. Select Latin → Verify it stays Latin
2. Click "Vocabulary Practice" → Verify it works
3. Get answer wrong → Edit → Check → Verify validation
4. New user → Verify BYOK popup
5. Guest user → Script preference → Verify works
6. Tap to hear → Verify audio plays

---

## 🚫 WHAT PREVIOUS AGENTS DIDN'T DO

1. Vocabulary was "fixed" but still broken
2. No actual testing done
3. Backend/frontend integration not verified
4. TTS not tested
5. No end-to-end testing

**What WAS done:**
- Code-level bug fixes
- All 46 languages available
- Texts added (untested)
- Fun facts timing

---

## 💡 BOTTOM LINE

**App is at 60/100. Get it to 95/100 with REAL fixes.**

**Don't:**
- Give long reports
- Assume fixes work
- Skip testing

**Do:**
- Fix the 13 bugs above
- Test everything
- Write actual code
- Verify end-to-end
