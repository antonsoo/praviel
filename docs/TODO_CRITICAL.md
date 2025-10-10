# Critical TODO - Code Implementation Focus

**Last Updated**: 2025-10-10 (Current Session)
**Focus**: FEATURES THAT NEED **CODE**, NOT DOCS OR TESTING

---

## 🔴 CRITICAL CODE IMPLEMENTATIONS (Before Production)

### 1. **6 New Lesson Types - Make Interactive** ⚠️ PARTIALLY DONE
**Status**: Backend works, frontend shows answers directly (NOT interactive!)
**Priority**: **HIGHEST** - Users can't actually DO the new lesson types
**File**: `client/flutter_reader/lib/pages/vibrant_lessons_page.dart` (lines 993-1325)

**What Works**:
- ✅ Backend generates 6 new task types
- ✅ Frontend displays task content
- ✅ Lesson length 20 tasks (2 of each type)

**What's BROKEN - HIGH PRIORITY CODE WORK**:
```dart
// TODO Lines 993-1046: _buildGrammarExercise()
// Currently: Shows answer directly
// NEED: Stateful widget, True/False buttons, attach/check pattern

// TODO Lines 1048-1101: _buildListeningExercise()
// Currently: Shows answer text
// NEED: TTS audio, option buttons, answer validation

// TODO Lines 1103-1161: _buildSpeakingExercise()
// Currently: Just displays text
// NEED: Speech recognition, record button, pronunciation feedback

// TODO Lines 1163-1220: _buildWordBankExercise()
// Currently: Shows correct order
// NEED: Drag-and-drop, reorderable list, submit button

// TODO Lines 1222-1264: _buildTrueFalseExercise()
// Currently: Shows answer
// NEED: Interactive buttons, show explanation after answer

// TODO Lines 1266-1325: _buildMultipleChoiceExercise()
// Currently: Highlights correct answer
// NEED: Hide answer, option selection, reveal after selection
```

**Code Pattern**: Copy from `client/flutter_reader/lib/widgets/exercises/vibrant_alphabet_exercise.dart`
- Stateful widget with `_selectedAnswer`, `_checked`, `_correct` state
- `widget.handle.attach()` in initState
- `_check()` validates, `_reset()` clears

**Estimated Work**: 8-12 hours (2 hours per widget × 6 widgets)

---

### 2. **UI Overflow Warnings - Fix Yellow Warning Bars** ⚠️ NOT INVESTIGATED
**Status**: User reported yellow/black warning bars at top of pages
**Priority**: HIGH - Makes app look broken
**Impact**: Unprofessional UX

**How to Find**:
```bash
# Run app, look for console messages like:
# "A RenderFlex overflowed by 42 pixels on the bottom"
```

**Likely Locations**:
- `vibrant_lessons_page.dart` - Exercise content in Column
- `vibrant_home_page.dart` - Dashboard widgets
- `vibrant_profile_page.dart` - Stats/language selector

**Common Fixes**:
- Wrap Column/Row in `SingleChildScrollView`
- Add `Expanded` or `Flexible` to child widgets
- Use `overflow: TextOverflow.ellipsis` for text
- Remove hardcoded heights/widths

**Estimated Work**: 2-4 hours

---

### 3. **Language Selector - Integrate into Profile Page** ⚠️ WIDGET EXISTS, NOT ADDED
**Status**: Widget created (261 lines) but not visible anywhere in app
**File**: `client/flutter_reader/lib/widgets/language_selector.dart`
**Priority**: MEDIUM - Nice to have for multi-language vision

**Code Needed** in `vibrant_profile_page.dart`:
```dart
import '../widgets/language_selector.dart';

// Add after stats cards (around line 300):
SlideInFromBottom(
  delay: const Duration(milliseconds: 700),
  child: LanguageSelector(
    currentLanguage: 'grc',
    onLanguageSelected: (languageCode) {
      // TODO: Save user preference
      // TODO: Show "Coming Soon" modal for non-Greek
    },
  ),
)
```

**Additional Code**:
1. Save language preference to secure storage
2. "Coming Soon" modal for unavailable languages
3. Persistence across app restarts

**Estimated Work**: 2-3 hours

---

## 🟡 LOWER PRIORITY CODE WORK (Post-Launch)

### 4. **Quest Model Schema Refactor** ⚠️ HAS WORKAROUND
**Status**: Fixed with backward compatibility getters
**File**: `client/flutter_reader/lib/services/quests_api.dart`
**Priority**: LOW - Current workaround is fine

**Current**: Uses deprecated fields with getters
**Better**: Update UI code to use new field names directly
- `targetValue` → `progressTarget`
- `currentProgress` → `progressCurrent`
- Remove `coinReward` (doesn't exist in backend)

**Estimated Work**: 2-3 hours (low priority)

---

### 5. **Content Expansion** 📋 FUTURE FEATURE
**Status**: 7,584 Iliad lines seeded (sufficient for launch)
**Priority**: LOW - More content later

**Available to seed**:
- Iliad Books 13-24 (8,103 more lines)
- Odyssey (~12,000 lines from Perseus)
- Plato's Apology (~1,000 lines)
- LSJ Lexicon (top 1000 Greek words)

---

## ✅ COMPLETED (Recent Sessions)

### This Session (Oct 10, 2025 - Current):
**Lesson System Expansion**
- ✅ Added 6 new lesson types to backend (grammar, listening, speaking, wordbank, truefalse, multiplechoice)
- ✅ Implemented backend task generation for all 6 types
- ✅ Created frontend models for all 6 types
- ✅ Added placeholder UI for all 6 types (shows answers, needs interaction)
- ✅ Increased lesson length from 4 to 20 tasks
- ✅ Created LanguageSelector widget (261 lines)
- ✅ Updated README to multi-language branding

### Previous Session (Oct 10, 2025 - Session 2):
**Bug Fixes & Auth UX**
- ✅ Fixed 5 critical API schema bugs
- ✅ Removed all Duolingo trademark references
- ✅ Added auth prompts to protected pages
- ✅ Created first-run account creation flow
- ✅ Fixed Google Chat 502 errors
- ✅ Fixed scheduled task crashes

### Previous Session (Oct 10, 2025 - Session 1):
**Infrastructure**
- ✅ ApiRetry utility with circuit breaker
- ✅ ErrorStateWidget, EmptyStateWidget, SkeletonLoader
- ✅ AppHaptics with 11 patterns
- ✅ Double-or-nothing celebration system
- ✅ Backend coins integration

---

## 🎯 SUMMARY FOR NEXT AGENT

**TOP 3 PRIORITIES (in order)**:

1. **Make 6 new lesson types interactive** (8-12 hours)
   - Grammar, Listening, Speaking, WordBank, TrueFalse, MultipleChoice
   - Currently show answers; need user interaction
   - Copy pattern from `vibrant_alphabet_exercise.dart`
   - Each needs stateful widget with attach/check

2. **Fix UI overflow warnings** (2-4 hours)
   - Run app, find yellow warning bars
   - Fix with SingleChildScrollView/Expanded/Flexible
   - Check console for "RenderFlex overflowed" messages

3. **Integrate language selector** (2-3 hours)
   - Add to vibrant_profile_page.dart
   - Save user preference
   - "Coming Soon" for unavailable languages

**TOTAL ESTIMATED WORK TO PRODUCTION-READY**: 12-19 hours

---

## 🚫 ANTI-PATTERNS TO AVOID

❌ **DON'T** write more docs/reports claiming perfection
❌ **DON'T** create new API clients without checking backend
❌ **DON'T** write tests before implementing features
❌ **DON'T** focus on "code quality" when features don't work

✅ **DO** implement the 6 interactive lesson widgets first
✅ **DO** fix visible UI bugs (overflow warnings)
✅ **DO** integrate existing widgets into pages
✅ **DO** test actual user flows after coding

---

## 📊 CURRENT STATUS

| Component | Status | Notes |
|-----------|--------|-------|
| Backend | ✅ 100% | All APIs work, 10 lesson types generate |
| Frontend Models | ✅ 100% | All 10 lesson types have Dart models |
| Lesson UI (4 types) | ✅ 100% | Alphabet, Match, Cloze, Translate fully interactive |
| Lesson UI (6 new) | ⚠️ 40% | Display works, interaction missing |
| Auth/UX | ✅ 100% | Login prompts, first-run flow complete |
| Branding | ✅ 100% | Multi-language vision clear |

**THE APP IS 85% DONE. THE REMAINING 15% IS MAKING THE 6 NEW LESSON TYPES INTERACTIVE.**

---

**Session reports archived**: `docs/archive/`
**Dev setup**: `DEVELOPMENT.md`
**Auth details**: `AUTHENTICATION.md`
**API specs**: `AI_AGENT_GUIDELINES.md`
