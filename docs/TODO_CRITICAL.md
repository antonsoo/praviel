# Critical TODOs - What Actually Needs CODING

**Last Updated:** October 19, 2025
**Database:** 34/36 languages, 28,500+ segments ✓
**Critical Bugs:** All fixed ✓
**Script Preferences:** Complete ✓

---

## 🚨 WHAT NEEDS CODE (Priority Order)

### 1. **Fix Skill Tree Mock Data** (30 min) 🔴
**File:** `client/flutter_reader/lib/pages/skill_tree_page.dart:19-80`
- **Problem:** Shows 10 hardcoded fake lessons, never updates
- **Fix:** Use `LessonHistoryStore` to show real completed lessons
- **Why critical:** Makes app look fake in demos

### 2. **Fix Mobile Builds** (2-4 hours) 🔴
**Issue:** `flutter_secure_storage_windows` v2.1.1 symlink error
- **Options:**
  1. Downgrade to working version of package
  2. Switch to different package (`flutter_secure_storage_linux` or `hive`)
  3. Ship web-only (update docs, remove mobile references)
- **Why critical:** Blocks app store release

### 3. **Improve Lesson Quality** (4-6 hours) 🟡
**Current:** Lessons generate but AI quality untested
- Test 10+ languages, document quality issues
- Improve prompts in `backend/app/lesson/lang_config.py` if needed
- Add more task variety beyond basic 5 types
- Fix any vocabulary/grammar errors AI produces
- **Why important:** Core product value

### 4. **Add Missing Language Texts** (2-3 hours) 🟡
**Missing:** grc-koi (Koine Greek), hbo-paleo (Paleo-Hebrew)
- Import text segments for these 2 languages
- Test lesson generation works
- **Why important:** Completes language coverage

### 5. **Improve Gamification UI** (3-5 hours) 🟢
**Files:** Shop, quests, achievements pages
- Add animations to shop purchases
- Improve quest progress indicators
- Add achievement unlock celebrations
- Make streak freeze flow clearer
- Make daily challenges more prominent
- **Why nice-to-have:** Better engagement

### 6. **Polish Reader Experience** (2-3 hours) 🟢
**File:** `client/flutter_reader/lib/pages/text_reader_page.dart`
- Add word definition caching
- Improve tap targets (currently too small?)
- Add "Add to SRS" button in definition popup
- Show word frequency in popup
- **Why nice-to-have:** Better UX

### 7. **Test & Fix TTS** (1-2 hours) 🟢
**Files:** `backend/app/tts/*`
- Test TTS works for multiple languages
- Fix audio playback bugs if any
- Add TTS controls to lesson UI if missing
- **Why nice-to-have:** Audio learning

### 8. **Test & Fix Chat** (1-2 hours) 🟢
**File:** `backend/app/chat/*`
- Test AI tutor chat works
- Improve prompts if responses bad
- Add conversation persistence
- **Why nice-to-have:** Interactive learning

---

## ❌ DO NOT DO

- Write documentation (except code comments)
- Create test frameworks
- Write status reports
- Refactor working code
- Add new features (stick to the list above)

---

## 📊 REAL NUMBERS

**Estimated coding time to app-ready:**
- Critical (1-2): 3-5 hours
- Important (3-4): 6-9 hours
- Nice-to-have (5-8): 8-12 hours
- **Total:** 17-26 hours

**What's actually blocking app store:**
1. Mobile builds (2-4 hours to fix OR decide on web-only)
2. Skill tree fake data (30 min - embarrassing in demos)
3. That's it. Everything else works.

---

## ✅ COMPLETED (Oct 18-19, 2025)

**October 18:**
- Vocabulary timeout bug
- Reader validation error
- Languages endpoint 404
- Syriac YAML crash
- Script preferences UI

**October 19:**
- User import bug (would crash vocab)
- Script preferences data mismatch
- Navigation to script settings
- Cleaned up BS docs (4 files deleted)

---

## 💬 FOR NEXT AGENT

**Mission:** Write code for items 1-8 above. Nothing else.

**Start with:** Skill tree mock data (item #1) - it's quick and embarrassing.

**Then do:** Mobile builds decision (item #2) - blocks release.

**Then improve:** Lesson quality (item #3) - core value.

**Not your mission:**
- Testing frameworks
- Documentation
- Status reports
- "End-to-end testing" (just use the app yourself while coding)

**Measure of success:**
- Skill tree shows real data
- Mobile builds work (or web-only decision documented)
- Lessons tested for 10+ languages, quality documented
- At least 3-4 items from list completed with actual code changes

---

**Less talking. More coding.**
