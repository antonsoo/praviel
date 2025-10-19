# Critical TODOs - What Actually Needs CODING

**Last Updated:** October 19, 2025 (Evening Session)
**Database:** 77/77 language seed files exist ✓
**Critical Bugs:** Fixed ✓
**Recent Work:** Skill tree real data, Echo provider fix, interactive text reading

---

## ✅ COMPLETED (Oct 19, Evening Session)

### 1. **Skill Tree Real Data** ✅ DONE
- **Was:** Showing 10 hardcoded fake lessons
- **Now:** Shows actual completed lessons from LessonHistoryStore
- **File:** `client/flutter_reader/lib/pages/skill_tree_page.dart`
- **Impact:** No longer looks fake in demos

### 2. **Echo Provider Scriptio Continua Bug** ✅ DONE
- **Was:** Removing spaces before tokenization, breaking cloze tasks
- **Fix:** Split text into tokens FIRST, then apply script transform to each token
- **File:** `backend/app/lesson/providers/echo.py`
- **Impact:** All 18 lesson tests now pass (was 16/18)

### 3. **Shop Confetti Celebrations** ✅ DONE
- **Added:** Confetti animation on successful shop purchases
- **File:** `client/flutter_reader/lib/pages/shop_page.dart`
- **Impact:** Better user feedback, more engaging UX

### 4. **Interactive Text Reading** ✅ MAJOR FEATURE
- **Added:** Tappable words with morphological analysis
- **Features:**
  - Hover effects with border highlighting
  - Tap any word → see lemma, morphology in bottom sheet
  - "Add to SRS" button
  - Visual highlighting of known words
- **Files:**
  - `client/flutter_reader/lib/widgets/interactive_text.dart` (NEW)
  - `client/flutter_reader/lib/pages/reading_page.dart` (UPDATED)
  - `client/flutter_reader/lib/services/reader_api.dart` (UPDATED)
  - `client/flutter_reader/lib/models/reader.dart` (UPDATED)
- **Impact:** Transforms passive reading into active learning - HUGE investor demo value

### 5. **Language Texts** ✅ ALREADY EXIST
- **Found:** Both grc-koi and hbo-paleo have seed files
- **Total:** 77 language seed files (daily + canonical)
- **Status:** Nothing to do here

---

## 🚨 WHAT STILL NEEDS CODE (Priority Order)

### 1. **SRS Backend Integration** (2-3 hours) 🔴
**Current:** "Add to SRS" button exists in UI but doesn't save to backend
- **Files to modify:**
  - `backend/app/api/vocabulary.py` - Add endpoint for saving words from reader
  - `client/flutter_reader/lib/widgets/interactive_text.dart` - Connect to real API
  - `client/flutter_reader/lib/models/reader.dart` - Add SRS save model
- **Why critical:** Feature is half-done, looks broken

### 2. **Mobile Build Decision** (2-4 hours OR 5 min decision) 🔴
**Status:** Web builds work, mobile untested
- **Options:**
  1. Test mobile builds thoroughly
  2. Ship web-only for now (update README, deployment docs)
  3. Fix storage package if actually broken
- **Why critical:** Blocks app store release OR need to commit to web-only

### 3. **Lesson Quality Testing** (4-6 hours) 🟡
**Current:** Lessons generate but quality untested for most languages
- **Test:** Generate 2-3 lessons for each of 10+ languages
- **Document:** Quality issues, vocabulary errors, grammar mistakes
- **Fix:** Improve prompts in language configs if needed
- **Languages to test:**
  - grc, lat, san, hbo, akk, sux, egy, non, ang, grc-koi
- **Why important:** Core product value, investor demos

### 4. **Word Definition Caching** (1-2 hours) 🟡
**File:** `client/flutter_reader/lib/pages/reading_page.dart`
- **Add:** Cache analyzed words in memory
- **Add:** Show cached definition instantly on second tap
- **Add:** Persist cache to local storage
- **Why important:** Better UX, less API calls

### 5. **Improve Gamification UI** (3-5 hours) 🟢
**Files:** Quests, achievements pages
- **Add:** Achievement unlock celebrations (confetti + modal)
- **Improve:** Quest progress indicators (animated progress bars)
- **Add:** Streak milestone celebrations (7 days, 30 days, etc.)
- **Make:** Daily challenges more prominent on home page
- **Why nice-to-have:** Better engagement

### 6. **Test & Fix TTS** (1-2 hours) 🟢
**Files:** `backend/app/tts/*`
- **Test:** TTS works for grc, lat, san
- **Test:** Audio playback in Flutter app
- **Add:** TTS controls to lesson UI if missing
- **Why nice-to-have:** Audio learning feature

### 7. **Test & Fix Chat** (1-2 hours) 🟢
**File:** `backend/app/chat/*`, `backend/app/api/coach.py`
- **Test:** AI tutor chat works with real conversations
- **Test:** Conversation persistence
- **Improve:** Prompts if responses are poor
- **Why nice-to-have:** Interactive learning

---

## ❌ DO NOT DO

- Write documentation (except code comments)
- Create test frameworks
- Write status reports
- Refactor working code
- Add new features not on this list

---

## 📊 REAL NUMBERS

**Estimated coding time to investor-ready:**
- Critical (1-2): 4-7 hours
- Important (3-4): 5-8 hours
- Nice-to-have (5-7): 6-10 hours
- **Total:** 15-25 hours

**What's actually blocking investor demos:**
1. SRS backend integration (2-3 hours) - looks half-done currently
2. Lesson quality testing (4-6 hours) - need to prove it works well
3. That's it. Everything else is polish.

---

## 💬 FOR NEXT AGENT

**Mission:** Write code for items 1-7 above. Nothing else.

**Start with:** SRS backend integration (item #1) - it's half-done and looks broken.

**Then do:** Lesson quality testing (item #3) - test 10+ languages, document issues.

**Then decide:** Mobile builds (item #2) - either fix or commit to web-only.

**Then add:** Word definition caching (item #4) - makes interactive text feature complete.

**Not your mission:**
- Testing frameworks
- Documentation
- Status reports
- "End-to-end testing" (just use the app yourself while coding)

**Measure of success:**
- SRS integration complete (backend + frontend connected)
- Lessons tested for 10+ languages, quality documented
- Mobile build decision made and documented
- At least 4-5 items from list completed with actual code changes
- At least 10-15 commits pushed

**Key deliverables:**
1. Working SRS save from reader → backend
2. Lesson quality report for 10+ languages
3. Mobile build status documented
4. Word definition caching working
5. Optional: Gamification improvements

---

## 🎯 RECENT ACCOMPLISHMENTS (This Session)

**Lines of code added:** ~600
**Files created:** 1 new widget
**Files modified:** 6
**Commits pushed:** 3
**Tests passing:** 18/18 (was 16/18)

**Major features added:**
1. Interactive text reading with word analysis
2. Real skill tree data integration
3. Shop purchase celebrations

**Bugs fixed:**
1. Echo provider scriptio continua bug
2. Skill tree showing fake data

---

**Less talking. More coding.**
