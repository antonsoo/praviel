# AI Lesson Generation API

**API Contract:** `/lesson/generate` endpoint for AI-powered lesson generation.

This document describes the API for generating personalized lessons from authentic ancient texts using OpenAI, Anthropic, Google, or offline Echo providers.

---

## Endpoint

**POST** `/lesson/generate`

Generate a personalized lesson with interactive exercises.

---

## Request Format

### Basic Request

```json
{
  "language": "grc",
  "profile": "beginner",
  "exercise_types": ["alphabet", "match", "cloze", "translate"],
  "provider": "google"
}
```

### Full Request (All Options)

```json
{
  "language": "grc",
  "profile": "beginner",
  "exercise_types": ["alphabet", "match", "cloze", "translate"],
  "provider": "openai",
  "text_reference": "Il.1.1-1.10",
  "register": "literary",
  "difficulty": "intermediate",
  "num_exercises": 10,
  "custom_instructions": "Focus on aorist passive verbs"
}
```

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `language` | string | ✅ | Language code (`grc`, `lat`, `san`, `heb`) |
| `profile` | string | ✅ | User proficiency (`beginner`, `intermediate`, `advanced`) |
| `exercise_types` | array | ✅ | Exercise types (see below) |
| `provider` | string | ✅ | AI provider (`openai`, `anthropic`, `google`, `echo`) |
| `text_reference` | string | ❌ | Specific text passage (e.g., `Il.1.1-1.10`) |
| `register` | string | ❌ | Language register (`literary`, `colloquial`) |
| `difficulty` | string | ❌ | Override proficiency difficulty |
| `num_exercises` | integer | ❌ | Number of exercises (default: 5-10) |
| `custom_instructions` | string | ❌ | Additional AI instructions |

### Exercise Types

| Type | Description | Example |
|------|-------------|---------|
| `alphabet` | Script/alphabet recognition | "Match Α with 'alpha'" |
| `match` | Vocabulary matching | "Match μῆνις with 'wrath'" |
| `cloze` | Fill-in-the-blank | "Μῆνιν ἄειδε θεά, Πηληϊάδεω [____]" (answer: Ἀχιλῆος) |
| `translate` | Translation practice | "Translate: Μῆνιν ἄειδε θεά" → "Sing, goddess, the wrath" |
| `comprehension` | Reading comprehension | "What is the subject of this sentence?" |
| `morphology` | Grammar analysis | "Identify the case of μῆνιν" |

**Currently supported:** `alphabet`, `match`, `cloze`, `translate`

**Planned:** `comprehension`, `morphology`

---

## Response Format

### Success Response (200 OK)

```json
{
  "lesson_id": "uuid-1234",
  "language": "grc",
  "title": "Lesson: Iliad 1.1-1.10",
  "exercises": [
    {
      "id": "ex-1",
      "type": "alphabet",
      "prompt": "Match the Greek letter with its name:",
      "question": "Α",
      "options": ["alpha", "beta", "gamma", "delta"],
      "correct_answer": "alpha",
      "explanation": "Α (uppercase alpha) is the first letter of the Greek alphabet."
    },
    {
      "id": "ex-2",
      "type": "match",
      "prompt": "Match the Greek word with its English translation:",
      "question": "μῆνις",
      "options": ["wrath", "song", "goddess", "glory"],
      "correct_answer": "wrath",
      "explanation": "μῆνις (mēnis) means 'wrath, anger' (especially of the gods). See LSJ μῆνις."
    },
    {
      "id": "ex-3",
      "type": "cloze",
      "prompt": "Fill in the blank:",
      "question": "Μῆνιν ἄειδε θεά, Πηληϊάδεω [____]",
      "options": ["Ἀχιλῆος", "Ἀγαμέμνονος", "Ὀδυσσέως", "Ἕκτορος"],
      "correct_answer": "Ἀχιλῆος",
      "explanation": "The opening line of the Iliad: 'Sing, goddess, the wrath of Achilles, son of Peleus.'"
    },
    {
      "id": "ex-4",
      "type": "translate",
      "prompt": "Translate the following Greek to English:",
      "question": "Μῆνιν ἄειδε θεά",
      "options": ["Sing, goddess, the wrath", "Tell me, Muse, of the man", "Rage, goddess, sing the rage", "Speak to me of the hero"],
      "correct_answer": "Sing, goddess, the wrath",
      "explanation": "Literal translation: μῆνιν (wrath, acc.) ἄειδε (sing, imperative) θεά (goddess, voc.)"
    }
  ],
  "metadata": {
    "provider": "google",
    "model": "gemini-2.5-flash",
    "text_reference": "Il.1.1-1.10",
    "register": "literary",
    "difficulty": "beginner",
    "generated_at": "2025-10-17T14:00:00Z"
  }
}
```

### Error Response (400 Bad Request)

```json
{
  "error": "Invalid language code",
  "detail": "Language 'xyz' is not supported. Supported languages: grc, lat, san, heb"
}
```

### Error Response (401 Unauthorized)

```json
{
  "error": "API key required",
  "detail": "OpenAI API key not configured. Add OPENAI_API_KEY to .env or use 'echo' provider."
}
```

### Error Response (500 Internal Server Error)

```json
{
  "error": "AI provider error",
  "detail": "OpenAI API returned error: insufficient_quota"
}
```

---

## Provider Configuration

### OpenAI (GPT-5)

**Model:** `gpt-5` (October 2025 API)
**Endpoint:** `/v1/responses` (NOT `/v1/chat/completions`)

**Required:**
- `OPENAI_API_KEY` environment variable

**Cost:** ~$0.01-0.05 per lesson

```bash
# .env
OPENAI_API_KEY=sk-your-key-here
```

### Anthropic (Claude 4.5)

**Models:** `claude-4.5-sonnet`, `claude-4.1-opus`

**Required:**
- `ANTHROPIC_API_KEY` environment variable

**Cost:** ~$0.02-0.03 per lesson

```bash
# .env
ANTHROPIC_API_KEY=sk-ant-your-key-here
```

### Google (Gemini 2.5)

**Models:** `gemini-2.5-flash`, `gemini-2.5-pro`

**Required:**
- `GOOGLE_API_KEY` environment variable

**Cost:** FREE (generous free tier)

```bash
# .env
GOOGLE_API_KEY=AIza-your-key-here
```

### Echo (Offline)

**Model:** Local fallback (no AI)

**Required:** None

**Cost:** FREE

**Returns:** Seed/example exercises (not AI-generated)

---

## Language Support

| Language | Code | Status | Texts Available |
|----------|------|--------|-----------------|
| Classical Greek | `grc` | ✅ | Homer's Iliad, Odyssey, Hesiod |
| Classical Latin | `lat` | ✅ (Beta) | Virgil's Aeneid, Ovid, Caesar |
| Classical Sanskrit | `san` | ✅ (Beta) | Mahābhārata, Rāmāyaṇa, Bhagavad-Gītā |
| Biblical Hebrew | `heb` | ✅ (Beta) | Genesis, Exodus, Psalms, Isaiah |

---

## Text References

**Format:** `{work}.{book}.{line_start}-{book}.{line_end}`

**Examples:**
- `Il.1.1-1.10` — Iliad, Book 1, lines 1-10
- `Il.1.20-1.50` — Iliad, Book 1, lines 20-50
- `Il.2.1-2.100` — Iliad, Book 2, lines 1-100

**Omit for random selection:**
```json
{
  "language": "grc",
  "profile": "beginner",
  "provider": "google"
  // No text_reference — AI will select appropriate passage
}
```

---

## Register Modes

### Literary (Default)

Formal, classical language as found in ancient texts.

**Use for:**
- Reading Homer, Virgil, Sanskrit epics
- Academic study
- Historical accuracy

**Example (Classical Greek):**
```
Μῆνιν ἄειδε θεά, Πηληϊάδεω Ἀχιλῆος
(Sing, goddess, the wrath of Achilles, son of Peleus)
```

### Colloquial

Everyday speech, marketplace conversations.

**Use for:**
- Conversational practice
- Daily life scenarios
- Interactive chat

**Example (Classical Greek):**
```
Χαῖρε! Πῶς ἔχεις;
(Hello! How are you?)
```

---

## Rate Limits

| Provider | Rate Limit | Notes |
|----------|------------|-------|
| OpenAI | 10,000 TPM (tokens per minute) | Default tier |
| Anthropic | 50,000 TPM | Default tier |
| Google | 60 RPM (requests per minute) | Free tier |
| Echo | Unlimited | Local only |

**Exceeded rate limit?**
- Wait and retry
- Upgrade provider tier
- Switch to different provider

---

## Examples

### Generate Beginner Greek Lesson

```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H "Content-Type: application/json" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "exercise_types": ["alphabet", "match"],
    "provider": "google"
  }'
```

### Generate Advanced Lesson from Specific Passage

```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H "Content-Type: application/json" \
  -d '{
    "language": "grc",
    "profile": "advanced",
    "exercise_types": ["cloze", "translate"],
    "provider": "openai",
    "text_reference": "Il.1.1-1.20",
    "register": "literary",
    "custom_instructions": "Focus on Homeric epithets and dactylic hexameter"
  }'
```

### Offline Lesson (No API Key)

```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H "Content-Type: application/json" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "exercise_types": ["match", "cloze"],
    "provider": "echo"
  }'
```

---

## Implementation Details

**Backend:** `backend/app/lesson/providers/`

**Provider implementations:**
- `openai.py` — GPT-5 (October 2025 API)
- `anthropic.py` — Claude 4.5/4.1
- `google.py` — Gemini 2.5
- `echo.py` — Offline fallback

**Database:** `backend/app/db/models/lesson.py`

**Tests:** `tests/test_lessons.py`

**Smoke tests:** `scripts/dev/smoke_lessons.ps1` (Windows) / `smoke_lessons.sh` (Unix)

---

## Validation

**Before deploying changes to lesson providers:**

```bash
# Validate October 2025 APIs
python scripts/validate_no_model_downgrades.py

# Validate payload structure
python scripts/validate_api_payload_structure.py

# Smoke test real APIs
scripts/dev/smoke_lessons.ps1  # Windows
scripts/dev/smoke_lessons.sh   # Unix
```

---

## Related Documentation

- [docs/API_REFERENCE.md](API_REFERENCE.md) — Full API documentation
- [docs/AI_AGENT_GUIDELINES.md](AI_AGENT_GUIDELINES.md) — October 2025 API specs
- [docs/COACH.md](COACH.md) — Conversational chat API
- [docs/BYOK.md](BYOK.md) — API key setup

---

## Need Help?

- 💬 [GitHub Discussions](https://github.com/antonsoo/AncientLanguages/discussions)
- 🐛 [GitHub Issues](https://github.com/antonsoo/AncientLanguages/issues)
- 📖 [Documentation](../docs/)
