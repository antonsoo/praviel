# Testing Instructions for Prakteros Delta Bug Fixes

## Setup

Backend is running on: `http://localhost:8000`
Frontend is running on: `http://localhost:8090`

## Fixed Issues to Verify

### 1. Reader Data (Lemma/Morphology Display)

**Expected**: Tapping words shows actual linguistic data, not "—"

**Steps**:
1. Open `http://localhost:8090` in browser
2. Navigate to **Reader** tab
3. Paste this text: `μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος`
4. Enable **LSJ** and **Smyth** toggles
5. Click **Analyze**
6. Tap the word "μῆνιν"
7. Modal should show:
   - **Lemma**: μῆνις (NOT "—")
   - **Morphology**: n-s---fa- (NOT "—")
8. Verify LSJ section appears
9. Verify Smyth section appears
10. Tap other words and verify they also show data

**Success criteria**: ✅ All words show actual lemma and morphology data

---

### 2. Font Loading

**Expected**: No font loading errors, Greek text renders correctly

**Steps**:
1. Open browser DevTools (F12)
2. Go to **Console** tab
3. Refresh `http://localhost:8090`
4. Look for font errors

**Success criteria**:
- ✅ Zero "Failed to load font" errors
- ✅ Greek text displays with proper polytonic diacritics throughout the app

---

### 3. Lessons Page (Layout Exception)

**Expected**: No layout errors when generating lessons

**Steps**:
1. Navigate to **Lessons** tab
2. Select sources: **Daily** ✓, **Canonical** ✓
3. Select exercises: **Match** ✓, **Cloze** ✓
4. Click **Generate lesson**
5. Check browser console for errors
6. Complete the lesson exercises
7. Scroll through the entire lesson page

**Success criteria**:
- ✅ No "LayoutBuilder does not support returning intrinsic dimensions" error
- ✅ No layout overflow errors
- ✅ Lesson generates and displays correctly
- ✅ Can complete full lesson flow

---

### 4. Chatbot (Message Duplication)

**Expected**: Each message appears exactly once

**Steps**:
1. Navigate to **Chat** tab
2. Select persona: **Athenian Merchant**
3. Send message: "χαῖρε"
4. Count how many times "χαῖρε" appears in chat history
5. Wait for response
6. Count how many times the response appears
7. Send second message: "πῶς ἔχεις;"
8. Count messages again
9. Send third message: "χαίρε φίλε"
10. Final count: should be 6 total messages (3 user + 3 assistant)

**Success criteria**: ✅ Each message appears exactly once (no duplication)

---

## API Testing (Already Verified)

### Reader API Test
```bash
python test_reader_fix.py
```

**Result**: ✅ PASSED
- API returns actual lemma/morph data
- Greek text encoding works correctly
- Response in `test_reader_output.json`

---

## Additional Checks

### Analyzer State
```bash
cd client/flutter_reader
flutter analyze
```

**Expected**: 0 errors, 0 warnings
**Current**: ✅ CONFIRMED (0 errors)

### Font Verification
Open DevTools Console and verify:
- Noto Serif loads from Google Fonts
- Inter loads from Google Fonts
- Roboto Mono loads from Google Fonts
- No 404 errors for font files

---

## Known Issues (Not in Scope)

- Port 8080 occupied by httpd.exe (system service), using 8090 instead
- 9 Flutter packages have newer versions available (non-breaking)

---

## Files Modified

### Backend
- `backend/app/ling/morph.py` - Fixed CLTK import path

### Frontend
- `client/flutter_reader/pubspec.yaml` - Removed local font declarations
- `client/flutter_reader/lib/theme/app_theme.dart` - Switched to Google Fonts
- `client/flutter_reader/lib/pages/history_page.dart` - Added Google Fonts import
- `client/flutter_reader/lib/main.dart` - Added Google Fonts import

---

## Next Steps After Testing

If all tests pass:
1. Commit changes with detailed message
2. Merge `prakteros-delta-bugfix` → `main`
3. Push to origin
4. Verify CI passes

If any tests fail:
1. Document failures
2. Continue debugging
3. Retest until all pass
