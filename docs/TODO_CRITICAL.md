# CRITICAL TODOs - Actually Verified

**Last Updated:** October 12, 2025 (after achievement celebration integration)

---

## COMPLETED (Verified in Code)

✅ **Power-up API Integration** - Lines exist in progress_api.dart:250, 266, 282
✅ **Achievement Celebrations** - Wired in gamification_coordinator.dart:295-309
✅ **Backend Test Infrastructure** - client fixture added to conftest.py
✅ **Flutter Analyzer** - 0 warnings (verified with `flutter analyze`)
✅ **All 18 Exercise Types** - Lesson generation tested: 20 tasks generated

---

## ACTUALLY NEEDS WORK

### 1. Content Expansion (HIGH PRIORITY)

**Problem:** Sparse content for non-Greek languages

**Current vocab counts:**
- Greek: 210 words
- Latin: 168 words
- Hebrew: 154 words
- Sanskrit: 165 words

**What to do:**
1. Add 200+ more vocab words per language
2. Add 10+ dialogue conversations per language
3. Add etymology content
4. Add conjugation/declension tables

**Where:** Look for lesson content generation in `backend/app/lesson/` directory

### 2. Audio Playback (NEEDS TESTING)

**Status:** TTS exists, listening exercises exist, but untested

**What to test:**
1. Start backend server
2. Generate lesson with "listening" exercise
3. Click play button
4. Verify audio actually plays

**Files:**
- `backend/app/tts/providers/*.py`
- `client/flutter_reader/lib/widgets/exercises/vibrant_listening_exercise.dart`

### 3. Error Handling & Offline Mode

**Problem:** App may crash on network errors

**What to do:**
1. Verify retry logic in ALL API files
2. Add offline lesson caching
3. Add better error UI feedback

**Files:** `client/flutter_reader/lib/api/*.dart`

### 4. Real User Testing

**Critical:** No one has actually used the app end-to-end

**What to test:**
1. Register new user
2. Complete full lesson
3. Verify XP/coins/achievements work
4. Try purchasing power-ups
5. Activate power-ups in lesson
6. Check leaderboard
7. Test on real mobile device

---

## DO NOT DO

❌ Don't rewrite existing features (power-ups, achievements, etc.)
❌ Don't write more documentation
❌ Don't add new gamification (already have enough)
❌ Don't create new test scripts

---

## NEXT AGENT: FOCUS ON

1. **Add content** - More vocab, dialogues, grammar for all 4 languages
2. **Test everything** - Verify audio, power-ups, achievements with real usage
3. **Fix bugs** - Any issues found during testing
4. **Improve UX** - Better error messages, loading states, animations
