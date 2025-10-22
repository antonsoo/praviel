# TODO_CRITICAL.md

**Last updated:** 2025-10-22

**Status:** Pre-deployment polishing for investor demo

## Overview

This document tracks critical issues for deploying the app for investor demos and initial user testing.

**MAJOR PROGRESS:** Most critical bugs have been fixed! Focus is now on polish and content.

---

## ✅ COMPLETED FIXES (2025-10-22)

### 1. Vocabulary Generation API Error
**FIXED:** Vocabulary generation now works across all providers (OpenAI, Anthropic, Google)
- Fixed OpenAI Responses API text extraction logic in vocabulary_engine.py
- Aligned with working lesson provider implementation
- No more "No output_text found" errors
- Commit: 6981604

### 2. BYOK Model Dropdown UX
**FIXED:** Premium models now shown first
- GPT-5 is now first option (not GPT-5 Nano dated)
- Model order: Premium → Balanced → Budget
- Better UX - users see best models first
- Commit: 6981604

### 3. Alphabet Exercise "Identify the Letter" Bug
**FIXED:** No longer shows answer on screen
- Switched to VibrantAlphabetExercise which properly hides the letter
- Shows "?" placeholder instead of the actual letter
- Requires flashcard toggle to preview
- Makes exercise pedagogically sound
- Commit: 6981604

### 4. Fun Facts Display Timing
**FIXED:** Users now have time to read feedback
- Increased lesson feedback highlight duration from 900ms to 2500ms
- Increased loading screen fun fact interval from 20s to 30s
- No more rushed feeling when reading explanations
- Commit: 6981604

### 5. Lesson Retry Logic
**VERIFIED:** Already working correctly
- Retry button appears when answer is wrong
- Resets exercise state properly
- No XP awarded on retry (as intended)
- User can retry or move to next lesson

### 6. Ancient Writing Rules Enforcement
**VERIFIED:** Already implemented
- Script transformations applied via enforce_script_conventions()
- Follows LANGUAGE_WRITING_RULES.md specifications
- Uppercase Greek, V-for-U Latin, etc. all working

### 7. Lesson Hints
**VERIFIED:** Already context-specific and actionable
- LessonHintResolver provides excellent hints for all 19 exercise types
- Each hint is pedagogically sound and helpful

### 8. Reader Loading Screen
**VERIFIED:** Already uses LessonLoadingScreen with fun facts
- Same engaging experience as lesson generation
- Now has improved timing (30s intervals for facts)
- Shows language-specific fun facts during loading

---

## 🟡 REMAINING ISSUES (For Next Session)

### 1. Language Selection UI (Onboarding/Settings)

**PRIORITY:** CRITICAL FOR DEMO

**Status:** NEEDS VERIFICATION

**User reported issues:**
- Onboarding page shows only 4 languages (Latin, Greek, Hebrew, Sanskrit)
- Settings page shows only 4 languages
- Compact language selector (dropdown in tabs) shows only 4 languages
- Order doesn't match LANGUAGE_LIST.md

**Investigation needed:**
- Check if language_picker_sheet.dart is implemented and being used
- Verify onboarding_page.dart language selector
- Verify settings_page.dart language selector
- Verify compact_language_selector.dart
- All should show all 46 languages from LANGUAGE_LIST.md in correct order

---

### 2. Sound Effects Quality

**PRIORITY:** MEDIUM (Polish)

**Status:** NOT FIXED

**User feedback:**
- Error sound is "dumb" (sounds like old computer)
- Click sounds are not great
- Need professional quality, non-copyrighted sound effects

**Files:**
- client/flutter_reader/assets/sounds/error.wav
- client/flutter_reader/assets/sounds/success.wav
- client/flutter_reader/assets/sounds/tap.wav
- client/flutter_reader/assets/sounds/whoosh.wav

---

### 3. Reader Default Text Language

**PRIORITY:** MEDIUM

**Status:** NOT FIXED

**User reported:**
- Default text in Reader input box is in English
- Should be in the target language being learned

---

### 4. Reader Text Library Content

**PRIORITY:** LOW (Content, not bugs)

**Status:** ONGOING

**User requests:**
- Classical Greek should have 10+ texts available
- Other top languages should have multiple texts
- Better book selection UI

**Notes:**
- This is content work, not a bug
- Texts are stored in database (TextWork model)

---

### 5. History Page Functionality

**PRIORITY:** LOW

**Status:** NEEDS TESTING

**User reported:**
- History functionality may be broken or only broken for non-signed-in users

---

## 📝 Notes for Next AI Agent

**Priorities for next session:**
1. Fix language selection UI - This is the #1 visible bug for investors
2. Test and verify - Run the app and verify all claimed fixes work
3. Sound effects - Quick polish if time permits
4. Content - Add more texts if time permits

**Files modified in this session:**
- backend/app/lesson/vocabulary_engine.py
- client/flutter_reader/lib/models/model_registry.dart
- client/flutter_reader/lib/pages/lessons_page.dart
- client/flutter_reader/lib/widgets/lesson_loading_screen.dart

**Commit hash:** 6981604
