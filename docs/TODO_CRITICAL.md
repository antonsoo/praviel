# Critical TODOs for Next Agent

**Updated:** 2025-10-17 (Script Transform Session)
**Session Summary:** Fixed critical script transformation bugs. All tests pass.

---

## What This Session Actually Completed

**Fixed Critical Bugs in Script Transformation System:**
1. **Alphabet tasks generating empty strings** (39/46 languages broken) - FIXED
   - Added alphabets for Sanskrit, Coptic, Gothic, Armenian, Georgian, Tibetan, Chinese, Japanese, etc.
   - Added fallback to extract chars from native names
   - Added validation to filter empty strings

2. **Cloze tasks not transformed** (Latin/Hebrew/Sanskrit completely broken) - FIXED
   - Added `apply_script_transform()` to all hardcoded sentences

3. **Listening tasks not transformed** (Latin/Hebrew/Sanskrit broken) - FIXED
   - Added transforms to audio_text and options for all languages

4. **Test failures** - FIXED
   - Updated expectations for uppercase Greek/Latin

**Verification:** All 19 tests pass. Tested 11 languages via API - all working correctly.

---

## What Still Needs Implementation (INCOMPLETE)

### CRITICAL - Frontend Missing Exercise Widgets

**1. Flutter UI for Most Exercise Types MISSING**
- ✓ Match, Translate, Cloze, Alphabet exist
- ✗ Reorder - widget exists but barely used
- ✗ Etymology - NO widget
- ✗ Dictation - NO widget
- ✗ Grammar - NO widget
- ✗ Listening - NO widget
- ✗ Speaking - NO widget
- ✗ Multiple choice - NO widget
- ✗ True/false - NO widget
- ✗ Wordbank - NO widget

**2. Providers Don't Generate All Types**
- OpenAI/Anthropic/Google: mostly translate + match only
- Echo has code but many types broken/unused
- Grammar/listening/speaking/wordbank missing from most providers

**3. TTS Not Integrated**
- Speaking tasks exist but no voice recording
- Listening tasks exist but no audio playback
- TTS providers exist but not wired to UI

### HIGH PRIORITY - Content Gaps

**4. Only 7/46 Languages Have Full Support**
- Greek, Latin, Hebrew, Sanskrit, Arabic, Coptic, Gothic work
- Other 39 have alphabets but NO vocabulary/lesson content

**5. Text Sources Incomplete**
- Latin: 7 authors, 255 refs (decent)
- Greek: Iliad/Odyssey/Republic/NT only
- Hebrew: Minimal
- Sanskrit/Others: NONE

### MEDIUM PRIORITY

**6. Gamification Weak**
- Achievements unlock but no celebration
- Coins accumulate but nothing to buy
- Leaderboards hidden

**7. Offline Mode Partial**
- Progress queues offline ✓
- Lesson generation fails offline ✗

---

## What Previous Sessions CLAIMED But Didn't Do

**Claimed:** "All exercise types working"
**Reality:** Only 4-5 types actually appear in lessons

**Claimed:** "46 languages supported"
**Reality:** Only 7 have actual content

**Claimed:** "Reading comprehension fully implemented"
**Reality:** Model + widget exist, providers don't generate them

---

## Next Agent Must Prioritize

**#1: Add Flutter Widgets for Missing Exercises** (4-6 hours)
- Create widgets for reorder, etymology, dictation, grammar, listening, speaking
- Wire into lesson display dispatcher

**#2: Make Providers Generate All Exercise Types** (3-4 hours)
- Edit openai.py, anthropic.py, google.py, echo.py
- Add prompts for all 13 exercise types

**#3: Add Content for Top 10 Languages** (3-4 hours)
- Create vocabulary lists for Sanskrit, Old Norse, Egyptian, etc.
- Add example sentences

**#4: Wire TTS to Exercises** (2-3 hours)
- Connect TTS to listening exercises
- Add voice recording to speaking exercises

---

## Files Changed This Session

```
backend/app/lesson/script_utils.py    - Added 30+ language alphabets
backend/app/lesson/providers/echo.py  - Fixed transform bugs (6 locations)
backend/app/tests/test_lessons.py     - Updated test expectations
```

Total: 3 files, ~150 lines

---

## What NOT To Do

- ❌ Write docs about accomplishments
- ❌ Refactor working code
- ❌ Write tests before features

**Just implement features.**
