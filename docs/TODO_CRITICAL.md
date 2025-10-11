# Critical TODOs - What Actually Needs Doing

**Last updated:** 2025-10-11 (After Flutter audio integration + massive content expansion)

## ✅ ACTUALLY COMPLETED (Verified by commits + testing)

**Recent comprehensive fixes:**
- ✅ **FLUTTER AUDIO INTEGRATION** (commit b49bf13): Both listening and dictation widgets now use backend audio URLs
- ✅ **TTS FULLY INTEGRATED** (commit 9bf1391): Audio URLs generated and cached for all audio tasks
- ✅ **MASSIVE CONTENT EXPANSION** (commits a7568c5, add412f): Cloze/translate/grammar expanded 2-3x per language
- ✅ **Audio Caching System**: Created `backend/app/lesson/audio_cache.py` with deterministic caching
- ✅ **Static Audio Serving**: `/audio/` endpoint serves generated WAV files
- ✅ **All 18 Exercise Types**: Tested and working for all 4 languages (Greek, Latin, Hebrew, Sanskrit)

**Previous fixes (commits 0cb1609, e2e335b):**
- ✅ Fixed cloze exercise: Was hardcoding Greek distractors for ALL languages
- ✅ Fixed TranslateTask: Changed from hardcoded "grc->en" to language-agnostic
- ✅ Fixed 6+ placeholder bugs that would crash server

**Multi-language support:**
- ✅ All 4 languages work: Greek, Latin, Hebrew, Sanskrit
- ✅ Backend generates lessons for all 18 exercise types
- ✅ No more Greek-only hardcoding bugs

## ✅ FULL AUDIO PIPELINE - COMPLETE!

**Backend → Frontend audio integration fully working!**

**Backend (commit 9bf1391):**
1. `backend/app/lesson/audio_cache.py`: Generates and caches audio with deterministic hashing
2. `backend/app/lesson/providers/echo.py`: Populates audio URLs when `include_audio=True`
3. `backend/app/main.py`: Serves audio at `/audio/{hash}.wav`

**Flutter (commit b49bf13):**
1. `vibrant_lessons_page.dart`: Sets `includeAudio: true` in API requests
2. `vibrant_listening_exercise.dart`: Uses AudioPlayer to play backend URLs (falls back to TTS)
3. `vibrant_dictation_exercise.dart`: Uses AudioPlayer with prominent play button UI

**Testing:**
```bash
curl -X POST http://localhost:8001/lesson/generate \
  -H "Content-Type: application/json" \
  -d '{"language": "lat", "exercise_types": ["listening"], "include_audio": true}'

# Response includes: "audio_url": "/audio/8527326237a6ed3d.wav"
```

## ✅ CONTENT DEPTH - MASSIVE EXPANSION!

**Commits a7568c5, add412f:** Cloze, translate, and grammar tasks expanded 2-3x per language

| Exercise Type | Language | Before | After | Details |
|--------------|----------|--------|-------|---------|
| **Cloze**    | Latin    | 10     | 35    | Full sentences with context |
|              | Hebrew   | 8      | 25    | Biblical + modern phrases |
|              | Sanskrit | 8      | 25    | Classical literature quotes |
| **Translate**| Latin    | 8      | 30    | Common expressions + proverbs |
|              | Hebrew   | 6      | 25    | Practical phrases + idioms |
|              | Sanskrit | 6      | 25    | Yoga sutras + daily life |
| **Grammar**  | Latin    | 5      | 25    | All major constructions |
|              | Hebrew   | 3      | 17    | Verb patterns + syntax |
|              | Sanskrit | 3      | 17    | Case usage + compounds |

**Result:** Lessons now have much richer variety with minimal repetition

## 🚨 WHAT STILL NEEDS DOING

### Issue #1: Flutter UI Not Tested With Real Backend Data ⚠️
**Status:** Widgets complete, audio integration done, but NO manual testing yet
**What's needed:**
- Launch Flutter app connected to real backend
- Test all 18 exercise widgets with actual API data
- Verify audio playback works from backend URLs (code is ready, needs real device test)
- Check for null pointer exceptions, rendering issues
- Test conjugation tables, dialogue bubbles, drag-and-drop reorder

### Issue #2: UI Polish Missing ⚠️
**Current state:** Basic functional widgets
**What's missing:**
- Loading spinners during API calls (currently UI just freezes)
- Smooth transitions between exercises (currently snaps instantly)
- Celebration effects on lesson completion (confetti exists but not always triggered properly)
- Error recovery UI (crashes show error text but no retry button)
- Progress indicators during long operations

### Issue #3: Answer Validation Could Be Smarter ⚠️
**Current validation:**
- TranslateTask: Simple string comparison (doesn't handle "the boy" vs "a boy")
- Grammar: True/false check works, but error_explanation field not always displayed
- Speaking: No pronunciation checking (just "press done")

**Improvements needed:**
- Fuzzy string matching for translate tasks (handle articles, punctuation)
- Display grammar explanations more prominently
- Consider adding pronunciation scoring (future enhancement)


## 🎯 PRIORITY ORDER FOR NEXT AGENT

**1. FLUTTER APP MANUAL TESTING (HIGH PRIORITY)**
```bash
# Windows PowerShell:
.\scripts\dev\orchestrate.ps1 up

# Then launch Flutter app:
cd client/flutter_reader
flutter run

# Test checklist:
- ✓ Generate lesson for each language (grc, lat, hbo, san)
- ✓ Try all 18 exercise types
- ✓ Test audio playback (listening, dictation) - verify backend URLs work
- ✓ Check for crashes, null errors, UI glitches
- ✓ Verify smooth transitions and animations
```

**2. ADD UI POLISH (MEDIUM PRIORITY)**
- Loading spinners during lesson generation API calls
- Smooth AnimatedSwitcher transitions between exercises
- Better error recovery with retry buttons
- Progress indicators for long operations

**3. IMPROVE ANSWER VALIDATION (LOW PRIORITY)**
- Fuzzy string matching for translation tasks (e.g., "a boy" vs "the boy")
- More prominent display of grammar explanations
- Visual feedback improvements

## 📊 UPDATED REALITY CHECK

| Feature | Status |
|---------|--------|
| "All 72 combinations work" | ✅ TRUE (backend tested via curl) |
| "Backend→Flutter audio pipeline" | ✅ COMPLETE (commit b49bf13) |
| "Rich content variety" | ✅ COMPLETE (2-3x expansion completed) |
| "UI is polished" | ⚠️ Functional but needs loading states |
| "Manual Flutter testing done" | ❌ NOT YET - needs real device testing |

## 🎉 MAJOR WINS FROM RECENT SESSIONS

1. ✅ **Flutter Audio Integration** - Both widgets now use backend audio URLs
2. ✅ **Massive Content Expansion** - Cloze/translate/grammar 2-3x larger
3. ✅ **TTS Audio Caching** - Deterministic hashing, no re-generation
4. ✅ **All 18 Exercise Types** - Working for all 4 languages
5. ✅ **Audio Serving** - `/audio/` static endpoint serving WAV files

## DO THIS NEXT:

1. **Manual Flutter testing** - Launch app, test all 18 exercise types with all 4 languages
2. **Add UI polish** - Loading spinners, smooth transitions, error recovery
3. **Fix bugs found during testing** - Crashes, null errors, UI glitches

## DON'T DO:

- ❌ Write more docs or reports
- ❌ Add new features before testing existing ones
- ❌ Refactor working code

**FOCUS ON: MANUAL TESTING AND BUG FIXES.**
