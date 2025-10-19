# Critical TODOs - What Actually Needs CODING

**Last Updated:** October 19, 2025
**Status:** 39 language seed files exist, core features working, premium UI integrated

---

## 🎯 HIGH PRIORITY - BACKEND

### 1. **Expand Language Support** (7 missing from 46 target)
- **Current:** 39 seed files exist (daily_*.yaml)
- **Target:** 46 languages per BIG_PICTURE.md
- **Missing:** 7 languages need seed files created
- **Files:** `backend/app/lesson/seed/daily_*.yaml`
- **Impact:** Complete language coverage as advertised

### 2. **Test All Language Providers**
- **Current:** Only grc, lat, san, hbo tested with real APIs
- **Needed:** Test lesson generation for all 39 languages
- **Verify:** Echo provider works for ALL languages
- **Files:** `scripts/test/test_lesson_quality.py`
- **Impact:** Ensure no languages break in production

### 3. **Phonetic Transcriptions**
- **Current:** `phonetic_guide=None` in echo.py (line with TODO comment)
- **Needed:** Add IPA transcriptions for pronunciation guides
- **Files:** `backend/app/lesson/providers/echo.py`
- **Impact:** Better learning experience for non-native scripts

---

## 🎨 HIGH PRIORITY - FRONTEND

### 4. **Complete Premium UI Rollout**
- **Current:** 7/30+ pages have premium UI (vibrant_home, vibrant_lessons, shop, power_up_shop, skill_tree, settings, achievement_widgets)
- **Needed:** Apply premium components to remaining pages
- **Files:** All pages in `client/flutter_reader/lib/pages/`
- **Components to use:** `premium_snackbars.dart`, `premium_progress_indicators.dart`, `glassmorphic_card.dart`
- **Impact:** Consistent billion-dollar UI across entire app

### 5. **Test Flutter App End-to-End**
- **Current:** Web build works (38 seconds), but not tested in browser
- **Needed:** Actually open the web app and click through all features
- **Verify:**
  - Lesson generation UI works
  - Interactive text reading works
  - SRS card creation works
  - Gamification animations work
  - Shop purchase flow works
- **Impact:** Find bugs before demo/launch

---

## 📱 MEDIUM PRIORITY

### 6. **Deploy Web Build**
- **Current:** Build succeeds, but not deployed
- **Needed:** Deploy to Netlify or Firebase for public demo
- **Files:** `client/flutter_reader/build/web/`
- **Impact:** Shareable demo link for investors/users

### 7. **Remove Unused Premium Components**
- **Current:** 8 premium widget files exist, but some might have duplicate/unused code
- **Files:** `premium_button.dart`, `premium_buttons.dart`, `premium_card.dart`, `premium_cards.dart` (4 pairs - likely duplicates)
- **Needed:** Consolidate or remove duplicates
- **Impact:** Cleaner codebase, less confusion

### 8. **Test With Real API Keys**
- **Current:** Only tested with echo provider and limited OpenAI
- **Needed:** Test with:
  - GPT-5 Nano (OpenAI)
  - Claude 4.5 Sonnet (Anthropic)
  - Gemini 2.5 Flash (Google)
- **Files:** Backend providers
- **Impact:** Verify production APIs work correctly

---

## 🔧 LOW PRIORITY (Polish)

### 9. **Add More Exercise Types**
- **Current:** 4-5 exercise types (cloze, match, translate, alphabet)
- **Potential:** Grammar, listening, speaking, dialogue (some UI exists but not integrated)
- **Impact:** More engaging lessons

### 10. **Improve Error Messages**
- **Current:** Generic error messages in some places
- **Needed:** User-friendly error messages throughout
- **Impact:** Better UX when things go wrong

---

## ❌ DO NOT DO

- Write documentation (except inline code comments)
- Create test frameworks
- Write status reports or summaries
- Refactor working code without reason
- Add features not on this list without asking

---

## 📊 CURRENT STATE

**Backend:**
- ✅ 39 languages have seed files
- ✅ Echo provider works (tested with 10 languages)
- ✅ OpenAI provider works (tested with grc)
- ✅ TTS works (Echo + Google)
- ✅ Chat works (Echo provider)
- ✅ SRS integration complete

**Frontend:**
- ✅ Premium UI components created (3,871 lines)
- ✅ 7 pages upgraded with premium UI
- ✅ Web build works (38 seconds)
- ✅ Interactive text reading works
- ✅ Gamification system works
- ⚠️ Not fully tested end-to-end in browser
- ⚠️ Not deployed publicly

**The app is 90% investor-ready. The 10% missing is polish and verification.**

---

## 💡 FOR NEXT AGENT

**Focus on CODE, not documentation.**

**Top 3 priorities:**
1. Test the Flutter web app end-to-end (open in browser, click through everything)
2. Apply premium UI to more pages (there are 20+ pages that don't have it yet)
3. Test lesson generation for all 39 languages

**Don't:**
- Write long reports about what you did
- Claim "ALL TASKS COMPLETED!" unless they actually are
- Create new documentation files

**Do:**
- Write code that improves the app
- Fix bugs you find
- Make the UI more beautiful
- Test that features actually work
