# TODO_CRITICAL - Actually Incomplete Tasks

**Last Updated:** October 25, 2025
**Status:** Code/Feature implementation focus

---

## 🎯 Actually Incomplete Code/Features

### 1. Search Filter Modal ✅ Mostly Complete
- **File:** [search_page.dart:144](../client/flutter_reader/lib/pages/search_page.dart#L144)
- **Status:** ✅ Modal implemented with core features
- **Implemented:**
  - ✅ Filter modal widget with draggable bottom sheet
  - ✅ Type filters (lexicon, grammar, text) with checkboxes
  - ✅ Language selector with radio buttons
  - ✅ Work selector (for filtering by specific texts)
  - ✅ Apply/reset buttons with proper state management
- **Missing (requires backend API changes first):**
  - ❌ Date range picker (backend `/search` endpoint needs date params)
  - ❌ Difficulty level slider (backend needs difficulty field in text_segment table)

### 2. Perseus Morphology Data Ingestion ❌
- **Status:** Infrastructure ready, data pipeline not run
- **Impact:** Word-tap morphology lookup in reader returns empty/fallback results
- **Guide:** [docs/MORPHOLOGY_INGESTION.md](MORPHOLOGY_INGESTION.md)
- **Required Steps:**
  1. Download Perseus canonical Greek/Latin texts from GitHub
  2. Create/run ingestion script using `backend/app/ingestion/sources/perseus.py`
  3. Populate `token` table with lemmatized words and morphological tags
  4. Verify morphology lookups work for Iliad Book 1 and other texts
- **Why Not Done:** Requires downloading external data (several GB)

### 3. Chat API Provider Verification ✅ COMPLETE
- **File:** [chat_page.dart](../client/flutter_reader/lib/pages/chat_page.dart)
- **Status:** ✅ All chat providers verified and tested
- **Completed:**
  - ✅ Enhanced smoke tests with comprehensive tests
  - ✅ Tests all 4 providers: Echo, OpenAI, Anthropic, Google
  - ✅ Tests all 3 personas: athenian_merchant, spartan_warrior, athenian_philosopher
  - ✅ Tests context management (conversation history)
  - ✅ Pytest integration tests in [test_providers_integration.py](../backend/app/tests/test_providers_integration.py)

---

## 🧪 Automated Testing - ✅ COMPLETE

### Language Smoke Tests ✅ COMPLETE

**Features:**
- ✅ Tests all 46 languages (full list from language_config.py)
- ✅ Verifies lesson generation endpoint for each language
- ✅ Validates response structure (vocabulary, exercises)
- ✅ Fast mode option available for testing representative languages
- ✅ Comprehensive error reporting with pass/fail summary

**Note:** PowerShell scripts are legacy. Use Python test scripts or orchestrator smoke tests instead.

### API Integration Tests ✅ COMPLETE
**Deliverable:** [backend/app/tests/test_providers_integration.py](../backend/app/tests/test_providers_integration.py)

**Coverage:**
- ✅ All lesson providers: OpenAI (GPT-5), Anthropic (Claude 4.5), Google (Gemini 2.5), Echo
- ✅ All TTS providers: Google, ElevenLabs, OpenAI, Echo
- ✅ All chat providers: OpenAI, Anthropic, Google, Echo
- ✅ Chat persona system: athenian_merchant, spartan_warrior, athenian_philosopher
- ✅ Chat context management (conversation history)
- ✅ Multi-language lesson generation (parametrized tests)
- ✅ Error handling: invalid providers, missing API keys

**Usage:**
```bash
# Run all integration tests (requires API keys)
pytest backend/app/tests/test_providers_integration.py -v

# Run specific test
pytest backend/app/tests/test_providers_integration.py::test_openai_chat_provider -v
```

---

## 📝 Deferred (User Decision)

### Background Music Audio Files
- **Path:** `client/flutter_reader/assets/audio/music/`
- **Status:** User said "do later"
- **What's Needed:** 3 loopable ambient music MP3 files (2-5 min, 128 kbps, CC0 license)
- **Why Deferred:** Music service code is complete, just needs actual audio files

---

## ✅ Recently Completed (Last 48 Hours)

### Flutter UI Modernization
- ✅ **36 pages** modernized with fade animations
  - Added `SingleTickerProviderStateMixin` or `TickerProviderStateMixin`
  - Added `_fadeController` and `_fadeAnimation`
  - Wrapped content in `FadeTransition`
  - All syntax errors fixed

### Pages Modernized:
challenges_page.dart, leaderboard_page.dart, quests_page.dart, quest_detail_page.dart, quest_create_page.dart, skill_tree_page.dart, srs_review_page.dart, srs_decks_page.dart, srs_create_card_page.dart, chat_page.dart, pro_chat_page.dart, text_library_page.dart, passage_selection_page.dart, progress_stats_page.dart, vocabulary_review_page.dart, vocabulary_practice_page.dart, edit_profile_page.dart, search_page.dart, settings_page.dart, shop_page.dart, social_leaderboard_page.dart, vibrant_home_page.dart, lesson_completion_page.dart, reading_page.dart, premium_login_page.dart, public_profile_page.dart, script_settings_page.dart, pro_history_page.dart, change_password_page.dart, text_range_picker_page.dart, tutorial_page.dart, language_selection_page.dart, vibrant_lessons_page.dart, friends_page.dart, achievements_page.dart, vibrant_profile_page.dart

### Backend Work (Previously Completed)
- ✅ Input validation on all 14 routers (100% complete)
- ✅ Database session dependency injection (`get_session` instead of `get_db`)
- ✅ Rate limiting on sensitive endpoints
- ✅ JWT token revocation/blacklist system
- ✅ Error boundaries for Flutter provider failures
- ✅ Computed XP/level fields in progress responses

---

## 🎯 Next Agent Priority

### Completed (October 25, 2025)
1. ✅ **Search filter modal** - Core features implemented (types, language, work selector)
2. ✅ **Automated language smoke tests** - Tests all 46 languages
3. ✅ **Chat providers verification** - Enhanced smoke tests + pytest tests
4. ✅ **API integration tests** - [test_providers_integration.py](../backend/app/tests/test_providers_integration.py) covers all providers

### Remaining Tasks
1. **Perseus morphology ingestion** - Requires downloading external data (several GB)
   - Guide available: [docs/MORPHOLOGY_INGESTION.md](MORPHOLOGY_INGESTION.md)
   - Infrastructure ready, just needs data pipeline execution
   - Impact: Makes word-tap morphology lookup return real data

2. **Search filter enhancements** (optional, requires backend changes)
   - Date range picker (needs backend API support)
   - Difficulty level slider (needs database schema changes)

**Focus:** All automatable tasks completed. Morphology ingestion requires user decision on downloading large datasets.
