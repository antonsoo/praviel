# Critical TODOs - What Actually Needs CODING

**Last Updated:** October 19, 2025
**Honest Status:** Backend solid, frontend 36% polished, needs end-to-end testing

---

## 🎯 HIGHEST PRIORITY - FRONTEND UI/UX

### 1. **Complete Premium UI Rollout**
- **Current:** 15 out of 41 pages have premium UI (36%)
- **Needed:** Upgrade the remaining 26 pages
- **Components:** `PremiumButton`, `PremiumSnackBar`, `ElevatedCard`, `GlowCard`
- **Impact:** Consistent premium feel across entire app

**Pages still needing upgrade:**
```
challenges_page.dart, change_password_page.dart, edit_profile_page.dart,
enhanced_history_page.dart, font_test_page.dart, history_page.dart,
lessons_page.dart, onboarding_page.dart, passage_selection_page.dart,
pro_chat_page.dart, pro_history_page.dart, pro_home_page.dart,
pro_lessons_page.dart, profile_page.dart, quest_create_page.dart,
quest_detail_page.dart, quests_page.dart, script_settings_page.dart,
search_page.dart, srs_create_card_page.dart, stunning_home_page.dart,
support_page.dart, text_range_picker_page.dart, text_structure_page.dart,
vibrant_profile_page.dart, vocabulary_practice_page.dart
```

### 2. **Test Flutter App End-to-End**
- **Current:** Build succeeds but app hasn't been tested in browser
- **Needed:** Open web app, click through ALL features
- **Critical bugs to find:**
  - Lesson generation flow
  - Text reader word analysis
  - SRS card creation
  - Gamification animations
  - Shop purchases
  - Authentication flow

---

## 🔧 HIGH PRIORITY - BACKEND

### 3. **Test All 39 Language Lesson Generation**
- **Current:** Only tested with Greek, Latin, Sanskrit, Hebrew
- **Needed:** Verify lesson generation works for all 39 seed files
- **Test:** Echo provider first (free), then real APIs if available
- **Files:** `backend/app/lesson/seed/daily_*.yaml`

### 4. **Add Missing Languages**
- **Current:** 39 languages have seed files
- **Target:** 46 languages per BIG_PICTURE.md
- **Missing 7 languages need seed files created**

### 5. **Fix Phonetic Transcriptions**
- **File:** `backend/app/lesson/providers/echo.py:1170`
- **Current:** `phonetic_guide=None` (TODO comment exists)
- **Needed:** Add IPA phonetic guides for non-Latin scripts
- **Impact:** Better pronunciation learning

---

## 📱 MEDIUM PRIORITY

### 6. **Verify Backend-Frontend Integration**
- **Current:** Backend runs on port 8000, frontend configured correctly
- **Needed:** Test all API endpoints from Flutter app
- **Check:**
  - Lesson generation API
  - Text reader API
  - SRS endpoints
  - Chat endpoints
  - Progress tracking
  - Authentication

### 7. **Improve Error Handling**
- **Current:** Generic error messages in many places
- **Needed:** User-friendly error messages throughout
- **Examples:** "No internet connection", "API key invalid", "Text not found"

### 8. **Deploy Web Build**
- **Current:** Build exists at `client/flutter_reader/build/web/`
- **Needed:** Deploy to Netlify, Vercel, or Firebase
- **Impact:** Shareable demo link for investors/users

---

## 🧹 LOW PRIORITY (Polish)

### 9. **Consolidate Duplicate Widgets**
- **Issue:** Multiple similar files exist
- **Check:** `premium_button.dart` vs `premium_buttons.dart`, etc.
- **Action:** Consolidate or remove duplicates

### 10. **Add More Exercise Types**
- **Current:** Cloze, match, translate, alphabet
- **Potential:** Grammar drills, listening, speaking, dialogue

---

## ✅ ACTUALLY COMPLETED

**Backend:**
- ✅ 39 languages have seed files
- ✅ Echo provider works (fallback for all languages)
- ✅ OpenAI, Anthropic, Google providers work
- ✅ Text reader with morphology analysis
- ✅ SRS backend integration
- ✅ Chat with historical personas
- ✅ TTS (text-to-speech)
- ✅ Gamification (XP, levels, streaks)
- ✅ Database schema complete

**Frontend:**
- ✅ 15/41 pages have premium UI (36%)
- ✅ Flutter web build compiles successfully
- ✅ Premium UI components created
- ✅ Gamification widgets (XP, streaks, achievements)
- ✅ Interactive text reading widgets
- ✅ Lesson exercise widgets

**Infrastructure:**
- ✅ Docker setup
- ✅ PostgreSQL + Redis
- ✅ API key encryption (BYOK)
- ✅ Pre-commit hooks

---

## ❌ NOT COMPLETED (Despite Claims)

- ❌ App NOT tested end-to-end in browser
- ❌ Not all 39 languages tested
- ❌ Premium UI only on 36% of pages
- ❌ Not deployed publicly
- ❌ Error handling still generic in many places
- ❌ Phonetic guides still missing

**HONEST ASSESSMENT:** Backend is solid and production-ready. Frontend needs 26 more pages upgraded and full testing. App is about 60-70% ready for investors.

---

## 💡 FOR NEXT AGENT

**FOCUS ON CODE, NOT DOCS.**

**Priority order:**
1. Upgrade remaining 26 pages with premium UI
2. Test app end-to-end in browser, fix any bugs
3. Test lesson generation for all 39 languages
4. Improve error messages throughout
5. Deploy web build

**What NOT to do:**
- Don't write reports about how much you accomplished
- Don't claim "ALL TASKS COMPLETED" unless they actually are
- Don't create new documentation files
- Don't waste time on low-priority polish

**What TO do:**
- Write code that makes the app better
- Test features to find real bugs
- Fix the bugs you find
- Make the UI more beautiful and consistent
- Verify features actually work end-to-end
