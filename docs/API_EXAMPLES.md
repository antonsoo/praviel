# API Examples

Complete examples for all Ancient Languages API endpoints.

**🎯 New to the project?** See [BIG-PICTURE_PROJECT_PLAN.md](../BIG-PICTURE_PROJECT_PLAN.md) for the vision and language roadmap.

## Table of Contents

- [Lessons API](#lessons-api)
- [Text-to-Speech API](#text-to-speech-api)
- [Reader Analyze API](#reader-analyze-api)
- [Chat API](#chat-api)
- [Search API](#search-api)
- [BYOK Headers](#byok-headers)

---

## Lessons API

### Basic Lesson Generation (Offline)

Uses the offline `echo` provider (no API key needed):

```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily", "canon"],
    "exercise_types": ["alphabet", "match", "cloze", "translate"],
    "k_canon": 2,
    "include_audio": false,
    "provider": "echo"
  }'
```

### With BYOK (OpenAI)

```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily", "canon"],
    "exercise_types": ["alphabet", "match", "cloze", "translate"],
    "k_canon": 2,
    "include_audio": false,
    "provider": "openai",
    "model": "gpt-5-mini"
  }'
```

### Text-Targeted Lesson Generation

Generate lessons from specific text passages:

```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "text_range": {
      "ref_start": "Il.1.20",
      "ref_end": "Il.1.50"
    },
    "exercise_types": ["match", "cloze", "translate"],
    "provider": "openai",
    "model": "gpt-5-mini"
  }'
```

### Literary vs. Colloquial Register

```bash
# Colloquial (everyday speech)
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "register": "colloquial",
    "exercise_types": ["match", "translate"],
    "provider": "openai"
  }'

# Literary (formal language)
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "language": "grc",
    "profile": "intermediate",
    "register": "literary",
    "exercise_types": ["match", "translate"],
    "provider": "anthropic",
    "model": "claude-sonnet-4-5"
  }'
```

### Provider Examples

**Anthropic Claude:**
```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{
    "language": "grc",
    "profile": "advanced",
    "sources": ["canon"],
    "exercise_types": ["translate", "cloze"],
    "provider": "anthropic",
    "model": "claude-sonnet-4-5"
  }'
```

**Google Gemini:**
```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H "X-Model-Key: $GOOGLE_API_KEY" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily"],
    "exercise_types": ["alphabet", "match"],
    "provider": "google",
    "model": "gemini-2.5-flash"
  }'
```

---

## Text-to-Speech API

### Basic TTS (Offline Echo)

```bash
curl -X POST http://127.0.0.1:8000/tts/speak \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "χαῖρε κόσμε",
    "provider": "echo"
  }' \
  --output hello.wav
```

### OpenAI TTS (BYOK)

```bash
curl -X POST http://127.0.0.1:8000/tts/speak \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "text": "Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος",
    "provider": "openai",
    "voice": "alloy",
    "speed": 1.0
  }' \
  --output iliad.wav
```

### TTS with Lesson Integration

```bash
curl -X POST http://127.0.0.1:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily"],
    "exercise_types": ["alphabet"],
    "include_audio": true,
    "provider": "openai",
    "model": "gpt-5-mini"
  }'
```

---

## Reader Analyze API

### Basic Token Analysis

```bash
curl -X POST http://localhost:8000/reader/analyze \
  -H 'Content-Type: application/json' \
  -d '{
    "q": "Μῆνιν ἄειδε"
  }'
```

**Response includes:**
- Tokenization
- Lemma for each token
- Morphology (via Perseus + CLTK fallback)

### With LSJ and Smyth Grammar

```bash
curl -X POST 'http://localhost:8000/reader/analyze?include={"lsj":true,"smyth":true}' \
  -H 'Content-Type: application/json' \
  -d '{
    "q": "Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος"
  }'
```

**Response includes:**
- Tokens with lemma + morphology
- `lexicon` array with LSJ entries
- `grammar` array with Smyth topics (Greek-filtered)

### Full Iliad Passage

```bash
curl -X POST 'http://localhost:8000/reader/analyze?include={"lsj":true,"smyth":true}' \
  -H 'Content-Type: application/json' \
  -d '{
    "q": "Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος οὐλομένην, ἣ μυρί Ἀχαιοῖς ἄλγε ἔθηκε"
  }'
```

---

## Chat API

### Conversational Chatbot

Practice with historical personas:

```bash
curl -X POST http://127.0.0.1:8000/chat/converse \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{
    "message": "χαῖρε! τί πωλεῖς;",
    "persona": "athenian_merchant",
    "provider": "openai",
    "model": "gpt-5-mini",
    "context": []
  }'
```

**Available personas:**
- `athenian_merchant`
- `spartan_warrior`
- `philosopher`
- `playwright`

### Multi-turn Conversation

```bash
# First message
curl -X POST http://127.0.0.1:8000/chat/converse \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{
    "message": "χαῖρε, φίλε",
    "persona": "philosopher",
    "provider": "anthropic",
    "model": "claude-sonnet-4-5",
    "context": []
  }' | jq -r '.response' > response1.txt

# Second message (with context)
curl -X POST http://127.0.0.1:8000/chat/converse \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $ANTHROPIC_API_KEY" \
  -d '{
    "message": "τί ἐστι σοφία;",
    "persona": "philosopher",
    "provider": "anthropic",
    "model": "claude-sonnet-4-5",
    "context": [
      {"role": "user", "content": "χαῖρε, φίλε"},
      {"role": "assistant", "content": "'$(cat response1.txt)'"}
    ]
  }'
```

---

## Search API

### Hybrid Search

```bash
curl 'http://127.0.0.1:8000/search?q=Μῆνιν&l=grc&k=5&t=0.05'
```

**Parameters:**
- `q`: Query string
- `l`: Language code (e.g., `grc` for Ancient Greek)
- `k`: Number of results
- `t`: Trigram similarity threshold (0.0-1.0)

---

## BYOK Headers

The API accepts API keys via two header formats:

### Option 1: Standard Authorization Header

```bash
curl -H "Authorization: Bearer sk-proj-your-key-here" ...
```

### Option 2: Custom Header (Windows PowerShell Friendly)

```bash
curl -H "X-Model-Key: sk-proj-your-key-here" ...
```

### PowerShell Example

```powershell
$key = $env:OPENAI_API_KEY
curl.exe -X POST http://127.0.0.1:8000/lesson/generate `
  -H "Content-Type: application/json" `
  -H "Authorization: Bearer $key" `
  -d '{"language":"grc","profile":"beginner","provider":"openai"}'
```

### Diagnostic Endpoint (Dev Only)

Verify BYOK connectivity:

```bash
curl http://127.0.0.1:8000/diag/byok/openai \
  -H "Authorization: Bearer $OPENAI_API_KEY"
```

---

## Response Format Examples

### Lesson Generate Response

```json
{
  "lesson_id": "uuid-here",
  "language": "grc",
  "profile": "beginner",
  "exercises": [
    {
      "type": "alphabet",
      "prompt": "Identify the letter",
      "options": ["α", "β", "γ"],
      "correct": 0
    },
    {
      "type": "cloze",
      "sentence": "χαῖρε, ___!",
      "options": ["κόσμε", "φίλε", "ἀνήρ"],
      "correct": 0
    }
  ],
  "meta": {
    "provider": "openai",
    "model": "gpt-5-mini",
    "duration_ms": 1234
  }
}
```

### Reader Analyze Response

```json
{
  "tokens": [
    {
      "surface": "Μῆνιν",
      "lemma": "μῆνις",
      "morph": "n-s---fa-",
      "pos": "noun"
    }
  ],
  "lexicon": [
    {
      "lemma": "μῆνις",
      "gloss": "wrath, anger",
      "source": "LSJ",
      "url": "http://..."
    }
  ],
  "grammar": [
    {
      "section": "340",
      "title": "Accusative of Direct Object",
      "source": "Smyth"
    }
  ]
}
```

---

## Smoke Test Scripts

Instead of manual curl commands, use provided smoke test scripts:

**Lessons:**
```bash
# Unix
scripts/dev/smoke_lessons.sh

# Windows
scripts/dev/smoke_lessons.ps1
```

**TTS:**
```bash
# Unix
scripts/dev/smoke_tts.sh

# Windows
scripts/dev/smoke_tts.ps1
```

**Full Orchestrator:**
```bash
# Unix
scripts/dev/orchestrate.sh up
scripts/dev/orchestrate.sh smoke
scripts/dev/orchestrate.sh e2e-web

# Windows
scripts/dev/orchestrate.ps1 up
scripts/dev/orchestrate.ps1 smoke
scripts/dev/orchestrate.ps1 e2e-web
```

---

## Security Notes

- **Keys are never persisted** - BYOK keys are request-scoped only
- **Keys are redacted in logs** - Server logs mask API keys
- **Fallback behavior** - Missing/invalid keys degrade to offline `echo` provider
- **Rate limiting** - Provider-specific rate limits apply (set by OpenAI/Anthropic/Google)

See [docs/BYOK.md](BYOK.md) for full BYOK policy.
