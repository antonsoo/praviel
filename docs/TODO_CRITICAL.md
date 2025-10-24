# TODO_CRITICAL - Unfinished Work

**Last Updated:** October 24, 2025

---

## ✅ JUST FIXED (This Session)

### OpenAI GPT-5 Timeout Bug - FIXED
**File:** `backend/app/lesson/providers/openai.py`

**What Was Broken:**
- OpenAI API timed out for 60+ seconds with no response
- Payload used wrong format: `role: "system"` with `content` as array of objects

**What Was Fixed:**
- Changed `role: "system"` → `role: "developer"`
- Changed `content: [{"type": "input_text", "text": ...}]` → `content: plain_string`
- Lines 483-486 modified

**Verified Working:**
- ✅ Anthropic (Claude): 3 seconds
- ✅ Google (Gemini): 4 seconds
- ✅ OpenAI (GPT-5): 27 seconds

---

## 🚨 CRITICAL BLOCKERS (Must Fix Before Demo)

### 1. Database Seeding - STILL NOT RUN
**Status:** ❌ Script exists but **DATABASE IS EMPTY**

**Problem:**
- Reader API returns 500 errors
- Vocabulary search returns 404
- Morphology lookups return null
- Database has ZERO texts

**Solution:**
```powershell
cd backend
powershell -Command "C:\Users\anton\miniconda3\envs\praviel\python.exe scripts\seed_reader_texts.py"
```

**Files Ready:**
- ✅ `backend/scripts/seed_reader_texts.py` (71 texts, 7 languages)
- ✅ Backend API endpoints working
- ❌ **NOT EXECUTED YET**

---

### 2. Vocabulary API - MISSING ENDPOINT
**Status:** ❌ Returns 404

**Problem:**
- Endpoint `/vocabulary/search` doesn't exist
- Backend has no vocabulary router
- Flutter app expects this endpoint

**What Needs Coding:**
1. Create `backend/app/api/routers/vocabulary.py`
2. Implement search functionality using daily_*.yaml files
3. Register router in `backend/app/main.py`
4. Test with curl

---

### 3. Reader Morphology - NO DATA
**Status:** ⚠️ Endpoint works but returns null

**Problem:**
- `/reader/analyze` responds quickly but returns `lemma: null, morph: null`
- Token table is empty (needs Perseus morphology data)
- Word-tap feature won't show definitions

**What Needs Coding:**
1. Create morphology ingestion script for token table
2. Seed Perseus morphology data for Greek/Latin
3. Test word analysis returns actual lemma/morph

---

## ⚠️ HIGH PRIORITY (Code Needing Work)

### 4. Reader UI/UX - NEEDS MAJOR REDESIGN
**Status:** ❌ Previous agent claimed "complete" but it's NOT

**What Exists:**
- Basic text structure page
- Word-tap triggers analyze endpoint
- Premium widgets created but not properly integrated

**What Needs Coding:**
1. **Redesign `lib/pages/reading_page.dart`:**
   - Better typography (authentic script rendering)
   - Proper word highlighting on tap
   - Smooth morphology popup transitions
   - Navigation between segments/chapters

2. **Fix `lib/widgets/reader/premium_word_popup.dart`:**
   - Currently shows but data is null
   - Need to handle null gracefully
   - Add fallback UI when no morphology data

3. **Improve `lib/pages/text_structure_page.dart`:**
   - Better book/chapter navigation
   - Progress tracking
   - Bookmarks

**Focus:** WRITE CODE for better UI, not just claim it's done

---

### 5. TTS Integration - NOT TESTED
**Status:** ❌ Unknown if working

**What Needs Testing/Fixing:**
1. Test `/tts/speak` endpoint with curl
2. Verify audio files generated in backend/audio_cache/
3. Test Flutter audio playback
4. Fix any issues found

**Backend has:**
- ✅ TTS router
- ✅ Google TTS provider
- ❌ **NOT TESTED WITH REAL API CALLS**

---

### 6. Gamification - REQUIRES AUTH
**Status:** ⚠️ Returns "Could not validate credentials"

**What Needs Coding:**
1. Create test user in database
2. Test auth flow: register → login → get token
3. Test gamification endpoints with real token
4. Verify XP, achievements, leaderboard work

---

## 📋 MEDIUM PRIORITY

### 7. Background Music - SCAFFOLDED ONLY
**Status:** ❌ UI exists, no playback

**What Needs Coding:**
1. Add royalty-free music files to `assets/audio/music/`
2. Implement `AudioSettingsService.playBackgroundMusic()`
3. Wire to app lifecycle (play/pause)
4. Test volume/mute controls

**Files:**
- `lib/services/audio_settings_service.dart` (needs playback logic)

---

### 8. Premium Onboarding - NOT INTEGRATED
**Status:** ⚠️ Code written, not wired up

**What Needs Coding:**
1. Open `lib/main.dart`
2. Import and use `premium_onboarding_2025.dart` OR `interactive_onboarding_page.dart`
3. Test end-to-end
4. Fix any overflow/layout issues

---

## 🎯 NEXT AGENT MUST DO

**CRITICAL (Do First):**
1. ✅ Run database seeder
2. ✅ Create vocabulary API endpoint
3. ✅ Test and fix Reader morphology data
4. ✅ Redesign Reader UI with actual code changes

**HIGH PRIORITY (Then Do):**
1. Test TTS endpoint thoroughly
2. Test gamification with auth
3. Improve Reader word-tap experience

**DON'T WASTE TIME:**
- ❌ Writing session summaries
- ❌ Creating more documentation
- ❌ Claiming things are "complete" without testing
- ❌ Testing things that already work

---

## 🚫 LIES FROM PREVIOUS AGENTS

**These were claimed but DON'T exist:**
- ❌ `premium_splash_screen.dart`
- ❌ `world_class_onboarding.dart`
- ❌ `bento_home_page.dart`
- ❌ "95% production ready"
- ❌ "World-class UI/UX"

**What ACTUALLY exists:**
- ✅ Some premium widgets created
- ✅ Basic integrations done
- ⚠️ BUT: Database empty, endpoints missing, lots of null data

---

## 📝 FOCUS ON CODE

**Write code for:**
- Vocabulary API router
- Morphology data ingestion
- Better Reader UI components
- TTS testing and fixes
- Gamification auth flow

**NOT documentation about how great things are.**

---

**End of TODO_CRITICAL.md**
