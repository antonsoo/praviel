# Critical TODOs - What Actually Needs to Be Done

**Last updated:** 2025-10-10

## What's DONE (verified by counting actual code):
- ✅ Dialogues: 32 (target was 30+)
- ✅ Etymology questions: 41 (target was 40+)
- ✅ All 18 exercise types work
- ✅ Quest system implemented
- ✅ Flutter analyzer errors fixed

## 1. EXPAND GREEK CONTENT (Partially Done)
**What's LEFT to do:**
- Add 20+ reorder sentence exercises (currently 10, target 30+)
- Add 20+ context match exercises (currently 10, target 30+)
- Add conjugation templates for aorist, future, imperfect, perfect (currently only present tense)
- Add declension templates for vocative and dual cases

**Priority:** HIGH - Users need more exercise variety

## 2. LATIN CONTENT PIPELINE (NOT STARTED)
**What needs to be done:**
- Ingest Latin texts into `data/latin/`: Aeneid, Metamorphoses, Gallic War
- Create Latin lexicon (subset of Lewis & Short) with morphology rules
- Extend echo provider or create new provider for Latin
- Make all 18 exercise types work with Latin content
- Add tests for Latin lesson generation

**Priority:** HIGH - Promised in README, blocking language expansion

## 3. VERIFY GREEK TEXTS (NOT CHECKED)
**What needs to be done:**
- Verify 5 Classical Greek texts exist and are accessible as promised in README
- If missing, add them to `data/greek/`
- Test that text-range lesson generation works with these texts

**Priority:** MEDIUM - Already promised to users

## 4. MANUAL E2E TESTING (NOT DONE)
**What needs to be done:**
- Launch backend + Flutter app
- Play through complete lesson with all 18 exercise types
- Test drag-and-drop reorder
- Test dialogue chat bubbles
- Test conjugation/declension chips
- Test dictation audio
- Document and fix any crashes, layout issues, missing assets

**Priority:** CRITICAL - No one has actually tested if the UI works!

## 5. UI/UX IMPROVEMENTS (BARELY TOUCHED)
**What needs improvement:**
- Profile page UI (basic implementation exists)
- Quest creation flow (functional but could be prettier)
- Lesson results screen (needs celebration animations)
- Achievement notifications (basic toast, needs polish)
- Sound effects integration (guide exists, no sounds included)
- Haptic feedback (code exists, needs tuning)

**Priority:** HIGH - "Trillion dollar experience" requires polish

## 6. BACKEND IMPROVEMENTS NEEDED
**What's broken/missing:**
- Quest progress auto-tracking (exists but not tested with real lessons)
- XP calculation validation (formula exists, not verified accurate)
- Streak tracking accuracy (code exists, edge cases not tested)
- TTS endpoint (enabled but no provider testing)
- Coach endpoint (enabled but implementation unclear)

**Priority:** MEDIUM - Core features need validation

## 7. BUGS TO FIX
**Known issues:**
- Preview endpoint requires server restart to work (route caching issue)
- Flutter deprecation warnings (11 warnings about withOpacity)
- Test database setup broken (asyncpg caching issue)
- Potential quest reward calculation edge cases

**Priority:** LOW-MEDIUM - Not blocking but should be fixed

## Bottom Line for Next Agent

**STOP writing tests and docs. START writing CODE:**

1. **Add 40+ more exercise seed data** (reorder, context match)
2. **Add conjugation templates** for all Greek tenses
3. **Build Latin content pipeline** from scratch
4. **Actually launch the app** and test it manually
5. **Polish the UI/UX** to be gorgeous
6. **Fix the bugs** you find during manual testing

The app is functional but needs MORE CONTENT and MORE POLISH, not more test scripts.
