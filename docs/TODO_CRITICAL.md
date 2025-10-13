# CRITICAL TODOs - What Actually Needs Work

**Last Updated:** December 12, 2024 (Session 2)
**Status:** UI bugs fixed, language selection added, backend working

---

## ✅ COMPLETED THIS SESSION (Dec 12, 2024)

1. **Fixed Layout Overflow Bugs** - ReaderShell top bar and bottom navigation no longer overflow on small screens
2. **Fixed Dark Mode Button Visibility** - StreakShieldWidget button properly adapts colors (was light text on white)
3. **Added Language Selection to Onboarding** - New language selection page shows all 4 languages with beautiful UI
4. **Added Language Selector to Settings** - Full language switcher in settings page
5. **Created Language Controller** - New service for managing language preferences across app
6. **Fixed GPT-5 Nano API Issue** - Reasoning parameter only sent to models that support it
7. **Created Backend Startup Script** - PowerShell script for easy server startup
8. **Moved Cleanup Docs to Archive** - CLEANUP_SUMMARY.md archived

---

## 🚨 HIGHEST PRIORITY - CONTENT EXPANSION (2-3 hours of work)

**Why this matters:** App currently has ~170 words per language. That's pathetically small. Users will exhaust content in 30 minutes.

**What to add:**
- **500+ vocabulary words per language** (currently ~170 per language)
  - Common nouns, verbs, adjectives, adverbs
  - Thematic groupings (food, travel, philosophy, etc.)
  - Real ancient texts vocabulary (Homer, Cicero, Bible, Vedas)

- **20+ dialogue conversations per language** (currently 5-8 per language)
  - Natural conversation flows
  - Different scenarios (marketplace, temple, academy, etc.)
  - Branching dialogue options

- **10+ etymology explanations** (currently 2-3 per language)
  - Word origins and evolution
  - Connections to modern languages
  - Historical context

- **Complete conjugation/declension tables** (currently sparse)
  - At least 10 verbs fully conjugated per language
  - At least 10 nouns fully declined per language
  - Irregular forms documented

**Files to modify:**
- `backend/app/lesson/seed/daily_grc.yaml`
- `backend/app/lesson/seed/daily_lat.yaml`
- `backend/app/lesson/seed/daily_hbo.yaml`
- `backend/app/lesson/seed/daily_san.yaml`

---

## 🔥 HIGH PRIORITY - FIX AI PROVIDERS (1 hour)

**Current status:**
- ✅ Echo provider: Works perfectly
- ❌ OpenAI provider: Returns 500 errors (untested by previous agents)
- ❓ Anthropic provider: Untested
- ❓ Google provider: Untested

**What to do:**
1. Debug OpenAI provider - run actual API call, capture error message, fix issue
2. Test Anthropic provider with real API key
3. Test Google provider with real API key
4. Ensure all 3 providers return consistent JSON structure matching echo provider

**Files:**
- `backend/app/lesson/providers/openai.py`
- `backend/app/lesson/providers/anthropic.py`
- `backend/app/lesson/providers/google.py`

---

## 🎨 MEDIUM PRIORITY - UI/UX POLISH (2 hours)

**What's missing:**
- Loading states for async operations (lesson generation, achievements, etc.)
- User-friendly error messages (currently shows "500 Internal Server Error")
- Achievement celebration animations
- Confetti/particles when leveling up
- Better "correct" / "incorrect" feedback in exercises
- Progress indicators during lessons ("Question 3 of 10")

**Files to modify:**
- `client/flutter_reader/lib/widgets/exercises/*_exercise.dart` (all 18 types)
- `client/flutter_reader/lib/widgets/gamification/achievement_celebration.dart`
- `client/flutter_reader/lib/widgets/effects/confetti_overlay.dart`
- `client/flutter_reader/lib/widgets/effects/epic_celebration.dart`

---

## 🔊 MEDIUM PRIORITY - AUDIO & SPEAKING (30 min - 1 hour)

**Missing features:**
- Audio playback verification for listening exercises (TTS integration exists but untested)
- Microphone recording for speaking exercises (not implemented)
- Pronunciation feedback (not implemented)

**Files to create/modify:**
- `client/flutter_reader/lib/widgets/exercises/vibrant_listening_exercise.dart` - Verify audio player works
- `client/flutter_reader/lib/widgets/exercises/vibrant_speaking_exercise.dart` - Add mic recording
- Test TTS API endpoints work end-to-end

---

## 📚 MEDIUM PRIORITY - IMPROVE LESSON QUALITY

**Current issues:**
- Content feels templated and mechanical
- No difficulty progression (beginner lessons as hard as advanced)
- No spaced repetition (don't re-show failed words)
- Exercises feel random, not contextual

**What to implement:**
- Difficulty progression logic (easier vocab/grammar for beginners)
- Spaced repetition algorithm (SRS)
- Context-aware exercise generation (group related words)
- Better dialogue realism (current dialogues are stilted)

**Files:**
- `backend/app/lesson/providers/echo.py` - Make content more dynamic
- `backend/app/lesson/models.py` - Add difficulty/context metadata
- `backend/app/lesson/router.py` - Implement SRS logic

---

## ⚡ LOW PRIORITY - PERFORMANCE OPTIMIZATION

**What to optimize:**
- Reduce lesson generation time (currently 2-5 seconds)
- Cache previously generated lessons client-side
- Lazy-load vocabulary instead of loading all at once
- Add database indexes for faster queries

**Files:**
- `backend/app/lesson/router.py` - Add caching
- `backend/app/db/models.py` - Add indexes
- `client/flutter_reader/lib/services/lesson_cache.dart` - Create caching layer

---

## ❌ DO NOT WASTE TIME ON

1. **More test scripts** - We already have 11 in `docs/archive/`
2. **More documentation** - CLAUDE.md, BIG-PICTURE_PROJECT_PLAN.md, AGENTS.md are sufficient
3. **Status reports** - No more SESSION_SUMMARY.md, INTEGRATION_STATUS.md, etc.
4. **Minor refactoring** - Code structure is fine, focus on features
5. **New gamification features** - Power-ups, achievements, leaderboard already exist and work

---

## 🎯 NEXT AGENT MUST DO (in order of priority)

1. **Add 500+ vocab words per language** (2-3 hours) - Makes app actually useful instead of a 30-minute demo
2. **Fix OpenAI provider** (1 hour) - Debug the 500 error, ensure GPT-5 API works
3. **Add UI polish** (2 hours) - Loading states, animations, better error messages
4. **Test audio playback** (30 min) - Verify TTS works end-to-end
5. **Add difficulty progression** (1 hour) - Make beginner lessons easier, advanced harder

**Focus:** Write CODE and CONTENT, not reports or tests.

---

## 📊 WHAT PREVIOUS AGENTS CLAIMED vs REALITY

**Previous sessions claimed:**
- "Everything is integrated and working!"
- "All 18 exercise types tested!"
- "Backend-frontend fully wired!"
- "Achievement celebrations complete!"

**Actual reality:**
- ✅ Basic lesson generation works (after field name bug was fixed in Dec 11 session)
- ✅ All 4 languages work (Greek, Latin, Hebrew, Sanskrit)
- ✅ UI overflow bugs NOW fixed (Dec 12 session)
- ✅ Language selection NOW added (Dec 12 session)
- ✅ Backend connectivity NOW working (Dec 12 session - created startup script)
- ❌ Content is sparse (~170 words per language = only 30 min of content)
- ❌ OpenAI provider broken (returns 500 errors)
- ❌ Audio untested (TTS code exists but never verified to work)
- ❌ UI needs polish (loading states, animations, better error handling)
- ❌ Only 2/18 exercise types thoroughly tested

**Honest assessment:** Foundation is solid (~60% done), but needs CONTENT and polish to be investor-ready.

---

**Bottom line for next agent:** Stop writing docs and tests. Write VOCABULARY and FEATURES.
