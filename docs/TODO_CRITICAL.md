# TODO_CRITICAL.md

**Last updated:** 2025-10-22 (End of Session 2)

**Status:** SIGNIFICANT PROGRESS - Critical blockers fixed, texts added, ready for testing

---

## ✅ COMPLETED (Sessions 1 & 2)

### Critical Bugs Fixed:
1. ✅ **Vocabulary API Error** - Fixed OpenAI Responses API text extraction (Commit: 6981604)
2. ✅ **Model Dropdown** - Premium models now show first (Commit: 6981604)
3. ✅ **Alphabet Exercise** - No longer shows answer (Commit: 6981604)
4. ✅ **Fun Facts Timing** - Slowed down for readability (Commit: 6981604)
5. ✅ **Language Selection** - ALL 46 languages now available everywhere (Commit: 80498be)

### Content Added:
6. ✅ **Top 4 Languages Texts** - All now have 10+ texts (Commit: da84f9c)
   - Classical Greek: 12 texts
   - Classical Latin: 10 texts
   - Biblical Hebrew: 11 texts (added 2)
   - Classical Sanskrit: 11 texts (added 2)

---

## 🔴 CRITICAL - MUST TEST BEFORE LAUNCH

### 1. **Lesson Generation Testing**
**Priority:** CRITICAL
**Status:** UNKNOWN - Needs manual testing

**What to test:**
```bash
# Start backend
docker compose up -d
cd backend && conda activate ancient-languages-py312
alembic upgrade head
uvicorn app.main:app --reload

# Start frontend (new terminal)
cd client/flutter_reader
flutter run -d web-server --web-port=3001

# Test lesson generation for:
- Classical Latin
- Classical Greek
- Biblical Hebrew
- Classical Sanskrit
```

**Test checklist:**
- [ ] Lesson generation actually works
- [ ] All exercise types render correctly
- [ ] Ancient writing rules are applied
- [ ] Vocabulary generation works
- [ ] BYOK flow works with user's API key

### 2. **Reader Functionality**
**Priority:** HIGH
**Status:** UNKNOWN - Needs manual testing

**What to test:**
- [ ] Can select texts from library
- [ ] Texts display correctly
- [ ] Can navigate between sections
- [ ] All 10+ texts show for top 4 languages

### 3. **History Page**
**Priority:** MEDIUM
**Status:** UNKNOWN - Needs testing

**What to test:**
- [ ] History saves correctly
- [ ] Works for signed-in users
- [ ] Works for guest users

---

## 🟡 KNOWN ISSUES (Non-blocking but should fix)

### 1. Sound Effects
**Priority:** LOW (doesn't block demo)
**User feedback:** Sounds are "dumb" / placeholder quality

**Action:** User will replace these files themselves:
- client/flutter_reader/assets/sounds/error.wav
- client/flutter_reader/assets/sounds/success.wav
- client/flutter_reader/assets/sounds/tap.wav
- client/flutter_reader/assets/sounds/whoosh.wav

**Resources:** https://freesound.org/ or https://mixkit.co/

### 2. Reader Default Text
**Priority:** LOW
**Status:** Need to verify if actually an issue

---

## 🎯 HONEST ASSESSMENT

### What We KNOW Works:
- ✅ Code compiles without errors
- ✅ All 46 languages are selectable
- ✅ Top 4 languages have 10+ texts
- ✅ Vocabulary API extraction logic is fixed
- ✅ Model dropdown shows premium options first
- ✅ Alphabet exercise doesn't show answer
- ✅ Fun facts have better timing

### What We DON'T KNOW:
- ❓ Does lesson generation actually work end-to-end?
- ❓ Do all exercise types render correctly?
- ❓ Does the Reader work properly?
- ❓ Does vocabulary generation work end-to-end?
- ❓ Are there UI/UX bugs when actually using the app?

### What Needs to Happen:
1. **USER MUST TEST THE APP** - Run it and verify functionality
2. Fix any bugs discovered during testing
3. Consider UI/UX improvements based on actual usage

---

## 📋 PRE-LAUNCH CHECKLIST

### Before Showing to Investors:
- [ ] Run the app and test lesson generation
- [ ] Test vocabulary generation
- [ ] Test Reader with multiple texts
- [ ] Verify BYOK flow works
- [ ] Check that all 46 languages can be selected
- [ ] Verify top 4 languages show their 10+ texts
- [ ] Test on actual device/browser
- [ ] Replace sound effects (optional)

### If Tests Pass:
- Ready for investor demo

### If Tests Fail:
- Report errors and continue debugging
- Don't present to investors until core functionality works

---

## 🚀 DEPLOYMENT READINESS: **70/100**

**Why not 95/100?**
- We haven't actually TESTED the app end-to-end
- We don't know if lessons actually generate
- We don't know if there are UI bugs
- Code fixes are done, but functionality is unverified

**To reach 95/100:**
1. Test lesson generation end-to-end
2. Test vocabulary generation
3. Test Reader
4. Fix any bugs found
5. Verify UI/UX is acceptable

---

## 📝 FOR NEXT SESSION / FOR USER

**Immediate next steps:**
1. **RUN THE APP** - Follow testing checklist above
2. **Report any errors/bugs** - So they can be fixed
3. **Test core flows** - Lesson generation, vocabulary, Reader
4. **Consider UI/UX improvements** - Based on actual usage

**Commits made:**
- 6981604: Critical UX and API fixes
- 0011adb: TODO update
- 80498be: All 46 languages available
- 478997f: TODO update
- da84f9c: Top 4 languages texts added

**Files modified:**
- backend/app/lesson/vocabulary_engine.py
- backend/app/lesson/language_config.py
- client/flutter_reader/lib/models/model_registry.dart
- client/flutter_reader/lib/models/language.dart
- client/flutter_reader/lib/pages/lessons_page.dart
- client/flutter_reader/lib/widgets/lesson_loading_screen.dart
- client/flutter_reader/lib/services/reader_fallback_catalog.dart
- docs/TODO_CRITICAL.md
- docs/LANGUAGE_WRITING_RULES.md
- docs/TOP_TEN_WORKS_PER_LANGUAGE.md

---

## 💡 BOTTOM LINE

**We've fixed critical code issues and added required content.**

**BUT** we haven't tested if the app actually works end-to-end.

**Next step:** USER MUST TEST THE APP to verify everything works before investor demo.
