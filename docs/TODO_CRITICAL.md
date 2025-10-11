# Critical TODOs - What Actually Needs Doing

**Last updated:** 2025-10-11 (After bug fixes by Claude Code Agent)

## ✅ ACTUALLY COMPLETED (Verified by commits)

**Recent fixes (commits 0cb1609, e2e335b):**
- ✅ Fixed cloze exercise: Was hardcoding Greek distractors for ALL languages. Now uses backend-provided `options` field
- ✅ Fixed TranslateTask: Changed from hardcoded "grc->en" to language-agnostic "native->en"/"en->native"
- ✅ Fixed TranslateTask: Added `sampleSolution` field for better answer validation
- ✅ Fixed 6+ placeholder bugs: GrammarTask, ClozeTask, TranslateTask, ListeningTask, SpeakingTask, WordBankTask all had wrong parameters that would crash server

**Multi-language support:**
- ✅ All 4 languages work: Greek, Latin, Hebrew, Sanskrit
- ✅ Backend generates lessons for all 18 exercise types
- ✅ No more Greek-only hardcoding bugs

## 🚨 WHAT'S ACTUALLY NOT DONE

### Issue #1: TTS NOT INTEGRATED ❌
**Claim in docs:** "TTS pending but core works"
**Reality:** ALL audio exercises have `audio_url: None`
- ListeningTask: Backend sends `audio_text` but NO actual audio
- SpeakingTask: No audio playback or pronunciation validation
- DictationTask: No audio, just shows text hints

**What needs doing:**
```python
# In backend/app/lesson/providers/echo.py
# Need to actually call TTS service and get audio URLs:
ListeningTask(
    audio_url="https://tts.service/audio/12345.mp3",  # Currently None!
    audio_text=text,
    ...
)
```

### Issue #2: Content Depth Is SHALLOW ❌
**Claim in docs:** "100+ exercises per language"
**Reality:** Most exercise types have 2-10 examples MAX

Check the actual code:
```bash
# Latin matches: Only 10 pairs
grep -A 10 "latin_pairs = \[" backend/app/lesson/providers/echo.py

# Hebrew conjugations: Only ~5-8 examples
grep -A 20 "hebrew_verbs = \[" backend/app/lesson/providers/echo.py
```

**What's needed:**
- Each exercise type needs 15-30 examples MINIMUM
- Currently RNG picks from tiny pools = repetitive lessons

### Issue #3: Flutter UI NEVER TESTED WITH REAL DATA ❌
**Claim:** "Flutter widgets exist and work"
**Reality:** No evidence anyone launched the actual Flutter app with real backend data

**Critical unknowns:**
- Does conjugation table render correctly with real Latin/Hebrew data?
- Do dialogue bubbles work with actual conversations?
- Does drag-and-drop reorder work?
- Any null pointer exceptions with real API responses?

### Issue #4: UI Polish MISSING ❌
**What's there:** Basic functional widgets
**What's missing:**
- Loading spinners (API calls just hang UI)
- Smooth transitions (exercises snap instantly)
- Celebration effects (confetti exists but not triggered)
- Error recovery UI (crashes just show error text)

### Issue #5: Answer Validation IS WEAK ❌
**Current state:**
- TranslateTask: Simple string comparison (doesn't handle article variations)
- Grammar: True/false only (no explanations shown properly)
- Speaking: No actual pronunciation checking (just "press done")

## 🎯 PRIORITY ORDER FOR NEXT AGENT

**1. ADD TTS INTEGRATION (HIGH PRIORITY)**
- Integrate with OpenAI TTS or Google Cloud TTS
- Generate actual audio files/URLs for ListeningTask
- Store audio in backend or use CDN
- Update all audio-related tasks

**2. EXPAND CONTENT 10X (HIGH PRIORITY)**
- Add 20+ examples PER exercise type PER language
- Latin: Expand from ~10 to 30+ vocab pairs, sentences, etc.
- Hebrew: Expand from ~8 to 25+ examples
- Sanskrit: Expand from ~6 to 25+ examples

**3. MANUAL E2E TESTING (CRITICAL)**
```bash
# Start backend
uvicorn app.main:app --reload

# Launch Flutter app
cd client/flutter_reader && flutter run

# Test:
- Generate Latin lesson with all 18 types
- Tap through EVERY exercise
- Note any crashes, null errors, rendering issues
- Fix ALL bugs found
```

**4. UI POLISH (MEDIUM PRIORITY)**
- Add loading spinners during API calls
- Add smooth AnimatedSwitcher transitions
- Trigger confetti on lesson completion
- Add error retry buttons

**5. IMPROVE ANSWER VALIDATION (MEDIUM PRIORITY)**
- Fuzzy string matching for translate tasks
- Show grammar error explanations clearly
- Add visual feedback for correct/incorrect

## 📊 ACTUAL REALITY CHECK

| Claim | Reality |
|-------|---------|
| "All 72 combinations work" | ✅ TRUE (after bug fixes) |
| "TTS pending but works" | ❌ FALSE - No audio at all |
| "100+ exercises per language" | ❌ FALSE - More like 10-30 total |
| "UI is polished" | ❌ FALSE - Basic functional only |
| "Manual testing done" | ❌ FALSE - No evidence |

## 🐛 KNOWN BUGS TO FIX

1. **No TTS audio** - All audio_url fields are None
2. **Content too shallow** - Same 5-10 examples repeat
3. **No loading states** - UI freezes during API calls
4. **Translate validation weak** - "the boy" != "a boy" even though both valid
5. **Grammar explanations not shown** - error_explanation field exists but not displayed properly

## DO THIS NEXT:

1. Integrate TTS and get real audio URLs
2. Add 20+ examples per exercise type
3. Launch Flutter app and TEST IT manually
4. Fix any crashes found
5. Add loading spinners and transitions

## DON'T DO:

- ❌ Write more integration test scripts (already have one)
- ❌ Write more reports about progress (this is the last one)
- ❌ "Validate" things that already pass (tests are passing)
- ❌ Refactor working code unnecessarily

**FOCUS ON: Writing CODE to add features, not docs to claim features exist.**
