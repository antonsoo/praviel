# Feature Status Matrix

**Last Updated:** 2025-10-06

This document provides an honest, comprehensive overview of what features are **working now**, what's **in development**, and what's **planned**.

---

## ✅ Core Learning Features (Production-Ready)

### 1. **AI-Powered Lessons**
**Status:** ✅ **Fully Working**
**API:** `POST /lesson/generate`

- **4 Exercise Types:**
  - ✅ Alphabet drills (letter recognition)
  - ✅ Match exercises (vocab pairing: Greek ↔ English)
  - ✅ Cloze (fill-in-blank from Iliad passages)
  - ✅ Translation (bidirectional Greek ↔ English)

- **AI Providers:**
  - ✅ OpenAI GPT-5 (via `/v1/responses` endpoint)
  - ✅ Anthropic Claude 4.5 Sonnet / 4.1 Opus
  - ✅ Google Gemini 2.5 Flash / Pro
  - ✅ Offline Echo (deterministic fallback, no API key)

- **Customization:**
  - ✅ Text-targeted learning (generate from specific Iliad passages like "Il.1.20-1.50")
  - ✅ Adaptive difficulty (beginner/intermediate profiles)
  - ✅ Register modes (literary vs. colloquial Greek)

**Evidence:** `backend/app/lesson/`, `backend/app/tests/test_lesson_quality.py`

---

### 2. **Conversational AI Chat**
**Status:** ✅ **Fully Working**
**API:** `POST /chat/*`

- **4 Historical Personas:**
  - ✅ Athenian merchant (400 BCE, marketplace Greek)
  - ✅ Spartan warrior (military discipline)
  - ✅ Athenian philosopher (Socratic dialogue style)
  - ✅ Roman senator (Latin with Greek code-switching)

- **Features:**
  - ✅ RAG-based context retrieval (fetches grammar/lexicon before responding)
  - ✅ Bilingual help (practice in Greek, get explanations in English)
  - ✅ Multi-provider support (OpenAI, Anthropic, Google, Echo)

**Evidence:** `backend/app/chat/`, `backend/app/api/routers/coach.py`

---

### 3. **Interactive Text Reader**
**Status:** ✅ **Fully Working**
**API:** `POST /reader/analyze`

- **Tap-to-Analyze:**
  - ✅ Lemma (dictionary form)
  - ✅ Morphology (detailed MSD tags: case, number, gender, tense, voice, mood)
  - ✅ LSJ dictionary definitions (with citations)
  - ✅ Smyth grammar references (with section numbers)

- **Search:**
  - ✅ Hybrid search (lexical trigram + semantic vector search)
  - ✅ Context building for AI coach

- **Data Sources:**
  - ✅ Perseus Digital Library morphological analysis
  - ✅ CLTK fallback for missing words
  - ✅ Works offline (embedded linguistic data, no API required)

**Evidence:** `backend/app/api/reader.py`, `backend/app/retrieval/hybrid.py`

---

### 4. **Text-to-Speech (TTS)**
**Status:** ✅ **Fully Working**
**API:** `POST /tts/speak`

- **Providers:**
  - ✅ OpenAI TTS (reconstructed Ancient Greek pronunciation)
  - ✅ Google TTS
  - ✅ Offline Echo (silent/placeholder)

- **License Guard:** ✅ Prevents abuse while allowing academic use

**Evidence:** `backend/app/tts/`, `backend/app/api/routers/tts.py`

---

## 🏆 Gamification & Progress Tracking (Production-Ready)

### 5. **XP & Leveling System**
**Status:** ✅ **Fully Working**
**API:** `GET /progress/me`, `POST /progress/me/update`

- ✅ Earn XP for completing lessons
- ✅ Algorithmic level calculation (dynamic XP thresholds)
- ✅ Level-up detection with old/new level tracking
- ✅ Progress percentage to next level
- ✅ Total lessons/exercises/time tracking

**Evidence:** `backend/app/api/routers/progress.py:37-179`

---

### 6. **Daily Streaks**
**Status:** ✅ **Fully Working**
**API:** Integrated into `POST /progress/me/update`

- ✅ Track consecutive days of practice
- ✅ Automatic streak increment (daily)
- ✅ Automatic streak reset after gaps
- ✅ Max streak records (personal best)
- ✅ Timezone-aware logic (UTC-based)

**Evidence:** `backend/app/api/routers/progress.py:120-147`

---

### 7. **Skills Tracking (ELO System)**
**Status:** ✅ **Fully Working**
**API:** `GET /progress/me/skills`

- ✅ ELO ratings per grammar topic
- ✅ Per-topic accuracy tracking
- ✅ Skill decay modeling (last practiced tracking)
- ✅ Filter by topic type (grammar, morphology, vocab)

**Example Topics:** aorist passive, genitive absolute, optative mood, dative of means, etc.

**Evidence:** `backend/app/api/routers/progress.py:182-200`, `backend/app/db/user_models.py:UserSkill`

---

### 8. **Achievements & Badges**
**Status:** ✅ **Fully Working**
**API:** `GET /progress/me/achievements`

- ✅ Unlock achievements (badges, milestones, collections)
- ✅ Metadata (icons, descriptions, unlock dates)
- ✅ Progress tracking toward next tier

**Evidence:** `backend/app/api/routers/progress.py:203-216`, `backend/app/db/user_models.py:UserAchievement`

---

### 9. **Text-Specific Statistics**
**Status:** ✅ **Fully Working**
**API:** `GET /progress/me/texts`, `GET /progress/me/texts/{work_id}`

- ✅ Per-work reading stats (e.g., Iliad Book 1)
- ✅ Vocabulary coverage (lemma coverage percentage)
- ✅ Reading speed (words per minute)
- ✅ Comprehension scores (quiz/exercise performance)
- ✅ Hintless reading streaks (consecutive sentences without help)

**Evidence:** `backend/app/api/routers/progress.py:219-256`, `backend/app/db/user_models.py:UserTextStats`

---

### 10. **Learning Event Analytics**
**Status:** ✅ **Fully Working**
**Database:** `learning_events` table

- ✅ Event types: `lesson_start`, `lesson_complete`, `exercise_result`, `reader_tap`, `chat_turn`, `srs_review`
- ✅ JSONB data for flexible analytics
- ✅ Timestamp indexing for time-series queries

**Evidence:** `backend/app/db/user_models.py:LearningEvent`

---

## 🔐 User Management & Security (Production-Ready)

### 11. **Authentication System**
**Status:** ✅ **Fully Working**
**API:** `POST /auth/register`, `POST /auth/login`, `POST /auth/refresh`, etc.

- ✅ User registration (email + username + password)
- ✅ JWT access + refresh tokens
- ✅ Token refresh with rotation
- ✅ Password change (with verification)
- ✅ Soft delete (account deactivation)

**Evidence:** `backend/app/api/routers/auth.py`

---

### 12. **User Profiles & Preferences**
**Status:** ✅ **Fully Working**
**API:** `GET /users/me`, `PUT /users/me/preferences`

- ✅ Profile information (real name, Discord, phone)
- ✅ Payment provider tokens (encrypted)
- ✅ LLM preferences (default provider/models)
- ✅ UI/UX settings (theme, language focus)
- ✅ Learning goals (daily XP, SRS limits)

**Evidence:** `backend/app/api/routers/users.py`, `backend/app/db/user_models.py:UserPreferences`

---

### 13. **BYOK (Bring Your Own Key)**
**Status:** ✅ **Fully Working**
**API:** `POST /api-keys/`, `GET /api-keys/`, `PUT /api-keys/{provider}`, `DELETE /api-keys/{provider}`

- ✅ Encrypted API key storage (Fernet encryption at rest)
- ✅ Per-provider config (OpenAI, Anthropic, Google)
- ✅ Test key configuration (with masking)
- ✅ Unified priority: user DB key > header key > server default

**Evidence:** `backend/app/api/routers/api_keys.py`, `backend/app/security/encryption.py`

---

### 14. **Security Middleware**
**Status:** ✅ **Fully Working**

- ✅ Rate limiting (prevent API abuse)
- ✅ CSRF protection (cross-site request forgery mitigation)
- ✅ Security headers (HSTS, X-Frame-Options, etc.)
- ✅ API key redaction (automatic PII filtering in logs)

**Evidence:** `backend/app/middleware/`

---

## 📚 Linguistic Database (Production-Ready)

### 15. **Corpus & Lexicon Integration**
**Status:** ✅ **Fully Working**

- ✅ Text corpus (Homer's Iliad, verse-by-verse)
- ✅ Token database (every word with lemma, morphology, surface forms)
- ✅ LSJ lexicon (Liddell-Scott-Jones dictionary entries)
- ✅ Lemma folding (accent-insensitive lookup)
- ✅ Smyth Grammar (digitized, topic-based search)

**Evidence:** `backend/app/db/models.py:TextWork, TextSegment, Token, Lexeme, GrammarTopic`

---

### 16. **Morphological Analysis Pipeline**
**Status:** ✅ **Fully Working**

- ✅ Perseus Digital Library data (frequency-based lemma disambiguation)
- ✅ CLTK fallback (Classical Language Toolkit for missing words)
- ✅ Confidence scores (statistical frequency-based)
- ✅ MSD tags (detailed morphosyntactic descriptions)

**Evidence:** `backend/app/ling/morph.py`

---

### 17. **Hybrid Search Engine**
**Status:** ✅ **Fully Working**

- ✅ Lexical search (PostgreSQL trigram similarity, fast fuzzy matching)
- ✅ Semantic search (pgvector embeddings, 1536-dim OpenAI embeddings)
- ✅ Blended results (mean-normalized score fusion)
- ✅ Context building for AI coach

**Evidence:** `backend/app/retrieval/hybrid.py`, `backend/app/retrieval/context.py`

---

## 🚧 In Development (Database Models Ready, API Endpoints Coming Soon)

### 18. **Quests System**
**Status:** 🚧 **Database Ready, API In Progress**
**Database:** `user_quests` table

- ✅ Database model exists (`UserQuest`)
- ✅ Schema defined (quest types, target progress, XP rewards, expiration dates)
- ❌ No API endpoints yet (cannot create/track/complete quests)
- ❌ Not accessible in frontend

**Next Steps:**
- [ ] Create `POST /progress/me/quests` (create quest)
- [ ] Create `GET /progress/me/quests` (list active quests)
- [ ] Create `PUT /progress/me/quests/{quest_id}` (update progress)
- [ ] Create `POST /progress/me/quests/{quest_id}/complete` (mark complete)

**Evidence:** `backend/app/db/user_models.py:UserQuest`, `backend/app/api/schemas/user_schemas.py:UserQuestResponse`

---

### 19. **Spaced Repetition System (SRS)**
**Status:** 🚧 **Database Ready, API In Progress**
**Database:** `user_srs_cards` table

- ✅ Database model exists (`UserSRSCard`)
- ✅ FSRS algorithm fields (stability, difficulty, state, P(recall))
- ✅ Schema supports New → Learning → Review → Relearning states
- ❌ No API endpoints yet (cannot create/review flashcards)
- ❌ Not accessible in frontend

**Next Steps:**
- [ ] Create `POST /srs/cards` (create flashcard)
- [ ] Create `GET /srs/cards/due` (get due cards)
- [ ] Create `POST /srs/cards/{card_id}/review` (submit review with quality rating)
- [ ] Implement FSRS scheduling algorithm

**Evidence:** `backend/app/db/user_models.py:UserSRSCard`

---

## 📱 Frontend (Production-Ready)

### 20. **Flutter Web/Mobile App**
**Status:** ✅ **Fully Working** (Web), 🚧 **In Progress** (Mobile native)

**Working Features:**
- ✅ Home page (multiple professional designs: `stunning_home_page`, `pro_home_page`)
- ✅ Lessons page (generate lessons, complete exercises, see results)
- ✅ Chat page (select persona, converse in Greek)
- ✅ Reader page (tap words, see analysis)
- ✅ History page (view past lessons with scores)
- ✅ Settings page (configure preferences)
- ✅ Support page (donations, crypto QR codes)
- ✅ Premium UI (glass morphism, mesh gradients, 3D buttons, haptic feedback)
- ✅ Dark/light theme support

**In Progress:**
- 🚧 Mobile native apps (Android/iOS) - Flutter web works on mobile browsers
- 🚧 Offline mode (caching for full offline lessons)

**Evidence:** `client/flutter_reader/lib/pages/`, Flutter analyzer output shows 16 issues (mostly warnings, not blocking)

---

## 🌐 Multi-Language Foundation (Planned)

### 21. **Language Expansion**
**Status:** 🔄 **Architecture Ready, Implementation Planned**

**Current:**
- ✅ Classical Greek (grc) - Homer's Iliad

**Planned:**
- 🚀 Classical Latin (Virgil, Cicero, Caesar) - **Next priority**
- 📜 Ancient Hebrew (Tanakh)
- 𓃭 Old Egyptian (Middle Egyptian hieroglyphics)

**Future Languages (Community Vote):**
- Ancient Aramaic (language of Jesus)
- Ancient Akkadian (Babylonian, 24th-22nd century BC)
- Ancient Sumerian (world's oldest written language, 31st century BC)
- Vedic Sanskrit & Classical Sanskrit
- Proto-Indo-European (PIE)
- Classical Mayan hieroglyphics
- Classical Nahuatl (Aztec)
- Classical Quechua (Inca)

**Evidence:** `backend/app/db/models.py:Language` table, BIG-PICTURE_PROJECT_PLAN.md

---

## 🛠️ Developer Tools (Production-Ready)

### 22. **Testing & Validation**
**Status:** ✅ **Fully Working**

- ✅ Pytest test suite
- ✅ Pre-commit hooks (Ruff formatting, linting)
- ✅ Smoke tests (`smoke_lessons.sh/ps1`, `smoke_tts.sh/ps1`)
- ✅ API version validation (`validate_api_versions.py`)
- ✅ Lesson quality harness (`test_lesson_quality.py`)
- ✅ E2E web tests (`orchestrate.sh/ps1 e2e-web`)

**Evidence:** `scripts/dev/`, `backend/app/tests/`

---

### 23. **Health Monitoring**
**Status:** ✅ **Fully Working**
**API:** `GET /health`, `GET /health/providers`

- ✅ System health checks
- ✅ Provider availability (OpenAI, Anthropic, Google)
- ✅ Latency tracking (histograms)

**Evidence:** `backend/app/api/health.py`, `backend/app/api/health_providers.py`

---

## 📊 Summary

### Production-Ready Features (23)
1. ✅ AI Lessons (4 exercise types, 4 providers)
2. ✅ Conversational Chat (4 personas)
3. ✅ Interactive Reader (tap-to-analyze)
4. ✅ Text-to-Speech
5. ✅ XP & Leveling
6. ✅ Daily Streaks
7. ✅ Skills (ELO)
8. ✅ Achievements
9. ✅ Text Stats
10. ✅ Learning Analytics
11. ✅ Authentication
12. ✅ User Profiles
13. ✅ BYOK
14. ✅ Security Middleware
15. ✅ Corpus & Lexicon
16. ✅ Morphological Analysis
17. ✅ Hybrid Search
18. ✅ Flutter Web App
19. ✅ Developer Tools
20. ✅ Health Monitoring

### In Development (2)
1. 🚧 Quests (database ready, API needed)
2. 🚧 SRS Flashcards (database ready, API needed)

### Planned (1)
1. 🔄 Multi-Language Expansion (Latin, Hebrew, Egyptian)

---

## Contributing

Want to help implement missing features?
- **Quests API:** See `backend/app/db/user_models.py:UserQuest` for schema
- **SRS API:** See `backend/app/db/user_models.py:UserSRSCard` for FSRS fields
- **Language Expansion:** See [BIG-PICTURE_PROJECT_PLAN.md](BIG-PICTURE_PROJECT_PLAN.md)

[Contributing Guide →](CONTRIBUTING.md)
