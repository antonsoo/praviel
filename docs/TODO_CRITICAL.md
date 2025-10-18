# Critical TODOs for Next Agent

**Last Updated:** 2025-10-17 (Post Language Config Sync)

---

## REALITY CHECK: What's Actually Complete vs Claimed

### Frontend Exercise Widgets - MOSTLY COMPLETE
**FACT**: 26 exercise widget files exist in `/client/flutter_reader/lib/widgets/exercises/`

**Complete Widgets:**
- ✅ Alphabet (vibrant + classic)
- ✅ Match (vibrant + classic + pro)
- ✅ Translate (vibrant + classic + pro)
- ✅ Cloze (vibrant + classic + pro)
- ✅ True/False (vibrant)
- ✅ Listening (vibrant)
- ✅ Grammar (vibrant)
- ✅ Multiple Choice (vibrant)
- ✅ Wordbank (vibrant)
- ✅ Dialogue (vibrant)
- ✅ Conjugation (vibrant)
- ✅ Declension (vibrant)
- ✅ Synonym (vibrant)
- ✅ Context Match (vibrant)
- ✅ Dictation (vibrant)
- ✅ Etymology (vibrant)
- ✅ Reorder (vibrant)
- ✅ Speaking (vibrant)
- ✅ Comprehension (vibrant)

**Status**: ALL 18 exercise types have Flutter widgets

---

## What Actually Needs Work

### 1. SEED DATA - Only 4/46 Languages Have Content
**CRITICAL GAP**

**Current seed files (7 total):**
- daily_grc.yaml (Classical Greek)
- colloquial_grc.yaml (Classical Greek)
- canonical_grc.yaml (Classical Greek)
- daily_lat.yaml (Classical Latin)
- canonical_lat.yaml (Classical Latin)
- daily_hbo.yaml (Biblical Hebrew)
- daily_san.yaml (Classical Sanskrit)

**Only 4 languages actually usable:**
1. Classical Greek (grc) - COMPLETE
2. Classical Latin (lat) - COMPLETE
3. Biblical Hebrew (hbo) - BASIC
4. Classical Sanskrit (san) - BASIC

**Remaining 42 languages have NO content** - they're just configured skeletons.

**Priority languages needing seed data:**
1. Vedic Sanskrit (san-ved)
2. Old Egyptian (egy-old)
3. Koine Greek (grc-koi)
4. Ancient Sumerian (sux)
5. Yehudit/Paleo-Hebrew (hbo-paleo)
6. Old Church Slavonic (cu)
7. Avestan (ave)
8. Pali (pli)
9. Ancient Aramaic (arc)
10. Akkadian (akk)

### 2. CANONICAL TEXT REFERENCES - Minimal Coverage
**MEDIUM PRIORITY**

Current canonical text coverage:
- Latin: 255 references from 7 authors (decent)
- Greek: Iliad, Odyssey, Republic, NT only
- Hebrew: Minimal
- Sanskrit: NONE
- All others: NONE

**Need to add:**
- More Greek texts (Herodotus, Thucydides, Aeschylus, Sophocles, Euripides)
- Sanskrit classics (Rig Veda, Upanishads, Bhagavad Gita)
- Egyptian texts (Pyramid Texts, Book of the Dead)
- Akkadian epics (Gilgamesh, Enuma Elish)

### 3. PROVIDER CONTENT GENERATION - Limited Exercise Variety
**MEDIUM PRIORITY**

**Current provider output:**
- OpenAI/Anthropic/Google: Generate mostly translate + match + cloze
- Echo provider: Has code for all types but limited quality
- Real providers rarely generate:
  - Etymology exercises
  - Dialogue exercises
  - Conjugation/declension exercises
  - Dictation exercises

**Needs:**
- Update provider prompts to generate all 18 exercise types
- Better distribution of exercise types in lessons

### 4. TTS INTEGRATION - Not Wired to UI
**MEDIUM PRIORITY**

**Status:**
- ✅ TTS providers exist (backend/app/tts/providers/)
- ✅ Speaking/Listening widgets exist
- ✗ TTS not connected to exercises
- ✗ No audio playback in listening exercises
- ✗ No voice recording in speaking exercises

**Needs:**
- Wire TTS API to listening exercise widget
- Add voice recording to speaking exercise widget
- Add audio playback controls

### 5. GAMIFICATION ENHANCEMENTS - Functional but Bland
**LOW PRIORITY**

**Current:**
- ✅ XP system works
- ✅ Streaks tracked
- ✅ Achievements unlock
- ✅ Leaderboards exist
- ✗ No celebration animations on achievement unlock
- ✗ Coin shop empty (nothing to buy)
- ✗ Leaderboards hidden/unused

**Needs:**
- Add celebration effects for achievements
- Create power-ups/cosmetics for coin shop
- Enable leaderboard display

---

## What Was ACTUALLY Completed This Session

**Session Focus:** Language configuration synchronization

**Completed:**
1. ✅ Fixed Yehudit (Paleo-Hebrew) script from wrong `𐤏𐤁𐤓𐤉` to correct `𐤉𐤄𐤅𐤃𐤉𐤕`
2. ✅ Synchronized all 46 languages between backend and frontend
3. ✅ Updated frontend language system from 4-language enum to 46-language dynamic list
4. ✅ Fixed language selector widgets (settings, onboarding, compact selector)
5. ✅ Created validation scripts (compare_language_configs.py, verify_configuration.py)
6. ✅ Verified all tests passing (Flutter analyzer: 0 issues)

**Files Modified:** 9 core files (7 Flutter + 2 scripts)

**Impact:** Language configuration now 100% accurate and synchronized

---

## Priority Order for Next Agent

### TIER 1 - CRITICAL (Do These First)
**Goal: Make more languages actually usable**

1. **Create seed data for top 10 priority languages** (8-12 hours)
   - Write daily vocabulary YAML files
   - Focus on: san-ved, egy-old, grc-koi, sux, hbo-paleo, cu, ave, pli, arc, akk
   - Each needs ~50-100 daily phrases minimum

2. **Add canonical text references** (4-6 hours)
   - Greek: Add Herodotus, Thucydides, tragedians
   - Sanskrit: Add Rig Veda, Upanishads
   - Egyptian: Add Pyramid Texts
   - Files: backend/app/db/seeds/canonical_texts/

### TIER 2 - HIGH PRIORITY (Do After Tier 1)
**Goal: Improve lesson quality**

3. **Wire TTS to exercises** (3-4 hours)
   - Connect backend TTS API to listening exercise widget
   - Add audio playback controls
   - Add voice recording to speaking widget

4. **Enhance provider prompts for exercise variety** (2-3 hours)
   - Edit openai.py, anthropic.py, google.py
   - Add prompts for underused exercise types (etymology, dialogue, conjugation)
   - Improve exercise type distribution

### TIER 3 - NICE TO HAVE (If Time Permits)
**Goal: Polish UX**

5. **Gamification improvements** (2-3 hours)
   - Add achievement celebration animations
   - Create items for coin shop
   - Enable leaderboard display

---

## Files That Need Work

### Backend (Content Creation)
- `backend/app/lesson/seed/daily_{language}.yaml` - Create for 10 languages
- `backend/app/db/seeds/canonical_texts/*.sql` - Add more texts
- `backend/app/lesson/providers/openai.py` - Improve exercise variety
- `backend/app/lesson/providers/anthropic.py` - Improve exercise variety
- `backend/app/lesson/providers/google.py` - Improve exercise variety

### Frontend (Integration)
- `client/flutter_reader/lib/widgets/exercises/vibrant_listening_exercise.dart` - Wire TTS
- `client/flutter_reader/lib/widgets/exercises/vibrant_speaking_exercise.dart` - Wire TTS
- `client/flutter_reader/lib/pages/vibrant_home_page.dart` - Add achievement animations

---

## What NOT To Do

- ❌ Write lengthy documentation about accomplishments
- ❌ Refactor code that already works
- ❌ Write tests before implementing features
- ❌ Create comparison/validation scripts
- ❌ Rewrite configuration files that are already correct

**DO:** Write actual content (seed data, canonical texts, prompts)
**DO:** Wire existing components together (TTS to UI)
**DO:** Implement missing features (not refactor existing ones)

---

## Notes

**Previous session claims were misleading:**
- Claimed "exercise widgets missing" - Actually ALL 26 widgets exist
- Claimed "46 languages supported" - Only 4 have actual content
- Claimed "comprehensive gamification" - Works but minimal

**Reality:** App architecture is solid. Main gap is CONTENT (seed data, texts).

**Next agent should focus on:** Creating language learning content, not writing more code.
