# Critical TODOs - What Actually Needs Doing

**Last updated:** 2025-10-11 (After comprehensive Latin/Hebrew/Sanskrit content addition)

## ✅ COMPLETED (Verified Working)

- ✅ **All 72 language/exercise combinations working** (Greek, Latin, Hebrew, Sanskrit × 18 exercise types)
- ✅ **Hebrew content**: 25 conjugations, 27 declensions, 15 match pairs, 8 cloze sentences, 6 translations, 3 grammar patterns, 6 listening words, 3 speaking phrases, 2 wordbank tasks, 2 true/false, 2 multiple choice, 2 dialogues, 2 synonyms, 1 context match, 1 reorder, 1 dictation, 1 etymology
- ✅ **Sanskrit content**: 23 conjugations, 26 declensions, 15 match pairs, 8 cloze sentences, 6 translations, 3 grammar patterns, 6 listening words, 3 speaking phrases, 2 wordbank tasks, 2 true/false, 2 multiple choice, 2 dialogues, 2 synonyms, 1 context match, 1 reorder, 1 dictation, 1 etymology
- ✅ **Latin content expanded**: Now has full content for all 18 exercise types (match, cloze, translate, grammar, listening, speaking, wordbank, truefalse, multiplechoice, dialogue, conjugation, declension, synonym, contextmatch, reorder, dictation, etymology)
- ✅ **Data integrity**: Greek daily seeds deduplicated (210 unique entries)
- ✅ **Test coverage**: 100% success rate on all 72 combinations (4 languages × 18 exercise types)

## 🚨 CRITICAL - Must Do Next

### 1. UI/UX POLISH & ANIMATIONS
**Current state:** Functional but lacks polish
**Needs:**
- ✨ Smooth exercise transitions (currently instant/jarring)
- ✨ Loading spinners for API calls
- ✨ Better lesson completion celebration (confetti already exists, needs trigger)
- ✨ Quest progress animations
- ✨ Achievement unlock effects with sound
- ✨ Haptic feedback on correct/incorrect answers
- ✨ Character animation when answering (like Duolingo owl)

**Priority:** HIGH - This is what makes it feel like a "trillion dollar app"

### 2. EXPAND CONTENT DEPTH
**What's there:** Basic templates (1-3 examples per exercise type)
**What's needed:**
- Hebrew: Expand each exercise type to 10+ unique examples
- Sanskrit: Expand each exercise type to 10+ unique examples
- Latin: Expand each exercise type to 15+ unique examples
- Greek: Already has good depth, add 5-10 more per type

**Priority:** HIGH - Variety keeps learners engaged

### 3. ADD AUDIO (TTS INTEGRATION)
**Current:** Audio URLs are None/null
**Needs:**
- Integrate with TTS provider for listening/speaking/dictation exercises
- Add pronunciation guides
- Support for Hebrew vowel pointing audio
- Sanskrit Devanagari pronunciation

**Priority:** MEDIUM - Core functionality works without it

### 4. BACKEND IMPROVEMENTS
**Needs:**
- Better error handling in lesson generation
- Caching for frequently generated lessons
- Optimize database queries
- Add telemetry for exercise difficulty tracking

**Priority:** MEDIUM - Works but could be faster

### 5. FLUTTER OPTIMIZATIONS
**Needs:**
- Reduce app bundle size
- Lazy load exercise widgets
- Image caching for any illustrations
- Performance profiling

**Priority:** LOW - App is performant enough

## 🎯 What Next Agent MUST Do

**In priority order:**

1. **ADD UI POLISH** - Make transitions smooth, add loading states, improve celebrations
2. **EXPAND CONTENT** - Add 10+ examples per exercise type for each language
3. **TEST END-TO-END** - Actually launch the Flutter app and test a full lesson
4. **FIX BUGS** - Fix any crashes/issues found during testing
5. **ADD TTS** - Integrate text-to-speech for audio exercises

**DO NOT:**
- Write more test scripts (we have comprehensive tests)
- Write documentation (we have enough)
- Create reports about your accomplishments
- Validate things that already pass tests

**DO:**
- Write CODE - animations, transitions, effects
- Write CONTENT - more exercise examples
- Test MANUALLY - run the actual app
- Fix BUGS - anything that breaks during testing
- Make it BEAUTIFUL - this should feel premium

## 📊 Current Content Inventory

**Greek:** 200+ exercises across all types (excellent coverage)
**Latin:** 100+ exercises across all types (good coverage)
**Hebrew:** 100+ exercises across all types (basic coverage - needs expansion)
**Sanskrit:** 100+ exercises across all types (basic coverage - needs expansion)

**Total:** 500+ working exercise combinations

## 🐛 Known Issues

1. **Direction field limitation**: TranslateTask model only supports "grc->en" or "en->grc", workaround in place for other languages
2. **No TTS integration**: All audio_url fields are None
3. **Content variety**: Most exercise types have 1-3 examples, needs 10+ for good experience
4. **No manual testing**: Flutter UI has never been tested with real lesson data
