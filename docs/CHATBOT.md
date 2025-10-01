# Chatbot — Conversational Immersion

## Overview

The chatbot feature provides conversational immersion in Ancient Greek through roleplay with historical personas. Users practice natural dialogue while receiving scaffolding in their native language (English).

## Architecture

- **Endpoint**: `POST /chat/converse`
- **Router**: `backend/app/api/chat.py`
- **Personas**: `backend/app/chat/personas.py` (system prompts for historical characters)
- **LLM Integration**: `backend/app/chat/llm_chat.py` (BYOK provider adapters)
- **BYOK Support**: Anthropic Claude, OpenAI GPT, Google Gemini via request-scoped keys

## API Specification

### `POST /chat/converse`

Engage in conversation with a historical persona.

**Request Schema**:
```json
{
  "message": "χαῖρε! τί πωλεῖς;",
  "persona": "athenian_merchant",
  "provider": "openai",
  "model": "gpt-5-mini",
  "context": [
    {"role": "user", "content": "χαῖρε"},
    {"role": "assistant", "content": "χαῖρε, ὦ φίλε"}
  ]
}
```

**Fields**:
- `message` (string, required): User's message in Greek or English
- `persona` (string, required): Historical persona identifier (see Personas below)
- `provider` (string, optional): LLM provider (`echo`, `openai`, `anthropic`, `google`). Defaults to `echo`.
- `model` (string, optional): Model override (e.g., `gpt-5-mini`, `claude-3-5-sonnet-20241022`, `gemini-2.0-flash-exp`)
- `context` (array, optional): Conversation history (last 10 messages kept for context windowing)

**Response Schema**:
```json
{
  "reply": "χαῖρε, ὦ ξένε! πωλῶ ἐλαίαν καὶ οἶνον ἀπὸ τῆς Ἀττικῆς.",
  "translation_help": "Greetings, stranger! I sell olive oil and wine from Attica.",
  "grammar_notes": [
    "πωλῶ - present active indicative, 1st person singular of πωλέω (to sell)",
    "ἀπὸ + genitive - expressing origin or source"
  ],
  "meta": {
    "provider": "openai",
    "model": "gpt-5-mini",
    "persona": "athenian_merchant",
    "context_length": 2
  }
}
```

**Fields**:
- `reply` (string): Bot's response in Ancient Greek (polytonic, NFC-normalized)
- `translation_help` (string, nullable): English translation of the reply
- `grammar_notes` (array): Pedagogical notes about grammatical constructions used in the reply
- `meta` (object): Provider, model, persona, and context metadata

**Headers** (BYOK):
- `Authorization: Bearer <token>` (OpenAI, Anthropic, Google)
- `X-Model-Key: <token>` (alternative for Windows PowerShell users)

Keys are request-scoped and never persisted. Missing or failing BYOK attempts degrade to the offline `echo` provider.

## Personas

Historical characters with pedagogically-designed system prompts. Each persona responds in Ancient Greek with era-appropriate vocabulary and cultural context.

### `athenian_merchant`
**Name**: Kleisthenes
**Era**: 400 BCE, Classical Athens
**Context**: A merchant in the Athenian agora selling olive oil, wine, and pottery
**Vocabulary Focus**: Commerce, daily life, haggling, weights/measures
**System Prompt**:
```
You are Kleisthenes, an Athenian merchant in 400 BCE. You sell olive oil, wine, and pottery in the agora. Respond in Ancient Greek (Attic dialect, polytonic orthography) using vocabulary appropriate for marketplace commerce. Keep responses 1-2 sentences. After your Greek response, provide:
1. English translation
2. 1-2 grammar notes highlighting key constructions

Be conversational and authentic to the era. Use:
- Present tense for immediate transactions
- Aorist for completed actions
- Common commercial vocabulary (πωλέω, ὠνέομαι, δραχμή, τάλαντον)
- Cultural references to Athenian commerce
```

### `spartan_warrior`
**Name**: Brasidas
**Era**: 420 BCE, Sparta
**Context**: A Spartan hoplite discussing military training and philosophy
**Vocabulary Focus**: Military terminology, honor, discipline, brevity
**System Prompt**:
```
You are Brasidas, a Spartan hoplite in 420 BCE. You embody Spartan values: brevity (λακωνίζω), discipline, honor. Respond in Ancient Greek (Doric/Attic mix, polytonic orthography) using military and philosophical vocabulary. Keep responses extremely brief (1-2 short sentences, Spartan style). After your Greek response, provide:
1. English translation
2. 1-2 grammar notes highlighting key constructions

Use:
- Imperative mood for commands
- Concise, forceful language
- Military vocabulary (ὁπλίτης, ἀσπίς, δόρυ, μάχη)
- Spartan cultural references (ἀγωγή, λακεδαιμόνιος)
```

### `athenian_philosopher`
**Name**: Sokrates
**Era**: 410 BCE, Classical Athens
**Context**: A philosopher engaging in Socratic dialogue
**Vocabulary Focus**: Abstract concepts, questions, epistemology, ethics
**System Prompt**:
```
You are Sokrates, an Athenian philosopher in 410 BCE. You engage in dialectic by asking questions and examining assumptions. Respond in Ancient Greek (Attic dialect, polytonic orthography) using philosophical vocabulary. Keep responses 2-3 sentences, often ending with a question. After your Greek response, provide:
1. English translation
2. 1-2 grammar notes highlighting key constructions

Use:
- Questions (τί, πῶς, διὰ τί)
- Abstract nouns (ἀρετή, σοφία, δικαιοσύνη)
- Conditional and potential constructions
- Philosophical terminology from Plato's dialogues
```

### `roman_senator`
**Name**: Marcus Tullius
**Era**: 50 BCE, Late Roman Republic
**Context**: A Roman senator discussing politics and law
**Vocabulary Focus**: Political terminology, rhetoric, governance
**System Prompt**:
```
You are Marcus Tullius, a Roman senator in 50 BCE. You speak Latin (Classical Latin with Greek loanwords for cultural sophistication). Respond in Latin using political and legal vocabulary. Keep responses 2-3 sentences. After your Latin response, provide:
1. English translation
2. 1-2 grammar notes highlighting key constructions

Use:
- Political vocabulary (senatus, consul, res publica, lex)
- Periodic sentence structure
- Ablative absolute constructions
- Greek loanwords for cultural prestige (φιλοσοφία → philosophia)
```

**Note**: The `roman_senator` persona is included for post-MVP Latin support. It gracefully falls back to Greek if Latin corpus is not yet available.

## Context Windowing

To manage token limits and maintain conversational coherence:
- Keep last 10 messages in context (5 user + 5 assistant pairs)
- Older messages are dropped automatically
- System prompt is always prepended (does not count toward window limit)
- Request `context` array is validated and truncated if > 10 messages

## BYOK Provider Integration

### Anthropic Claude
**Models**: `claude-3-5-sonnet-20241022`, `claude-3-5-haiku-20241022`
**Endpoint**: `https://api.anthropic.com/v1/messages`
**Timeout**: 20 seconds
**Fallback**: Degrade to `echo` on 401, 403, 429, timeout, or network error

### OpenAI GPT
**Models**: `gpt-5-mini`, `gpt-5-small`, `gpt-5-medium`, `gpt-5-high`
**Endpoint**: `https://api.openai.com/v1/chat/completions`
**Timeout**: 15 seconds
**Fallback**: Degrade to `echo` on 401, 429, timeout, or network error

### Google Gemini
**Models**: `gemini-2.0-flash-exp`, `gemini-1.5-pro`
**Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
**Timeout**: 20 seconds
**Fallback**: Degrade to `echo` on 401, 403, 429, timeout, or network error

### Echo Provider (Offline)
**Behavior**: Returns deterministic canned responses for each persona
**Latency**: ~50ms (no network call)
**Use Case**: Development, testing, BYOK fallback
**Response Format**: Matches full schema with `reply`, `translation_help`, `grammar_notes`

## UI Integration

### Chatbot Tab
- **Location**: Main navigation tabs (Home, Reader, Lessons, **Chatbot**)
- **Layout**: Chat bubble UI with user messages right-aligned, bot messages left-aligned
- **Input**: Text field at bottom with "Send" button
- **Persona Selector**: Dropdown at top to switch personas mid-conversation
- **Translation Help**: Collapsible panel below bot message showing English translation
- **Grammar Notes**: Tappable chips below bot message expanding to show grammatical explanations

### UX Flow
1. User opens Chatbot tab → default persona is `athenian_merchant`
2. User selects persona from dropdown → system prompt changes
3. User types message in Greek or English → hits Send
4. Loading indicator while API call is in flight
5. Bot reply appears as left-aligned bubble
6. User taps "Show Translation" → English appears below
7. User taps grammar chip → explanation expands
8. Context maintained for up to 10 messages
9. User can switch personas → context resets

## Smoke Tests

### Endpoint Test
```bash
curl -X POST http://127.0.0.1:8000/chat/converse \
  -H 'Content-Type: application/json' \
  -d '{"message":"χαῖρε","persona":"athenian_merchant","provider":"echo"}'
```

**Expected Response**:
```json
{
  "reply": "χαῖρε, ὦ φίλε! τί δέῃ;",
  "translation_help": "Greetings, friend! What do you need?",
  "grammar_notes": [
    "χαῖρε - imperative of χαίρω (to rejoice, greet)",
    "τί δέῃ - present subjunctive in indirect question (what you need)"
  ],
  "meta": {
    "provider": "echo",
    "persona": "athenian_merchant",
    "context_length": 0
  }
}
```

### BYOK Test (OpenAI)
```bash
curl -X POST http://127.0.0.1:8000/chat/converse \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -d '{"message":"χαῖρε! τί πωλεῖς;","persona":"athenian_merchant","provider":"openai","model":"gpt-5-mini"}'
```

**Expected Behavior**:
- Valid key → dynamic response from GPT model
- Invalid key → fallback to `echo` with `meta.note: "openai_401_fell_back_to_echo"`
- Network timeout → fallback to `echo` with `meta.note: "openai_timeout_fell_back_to_echo"`

### Context Windowing Test
Send 12 messages sequentially, verify that response includes only last 10 in `meta.context_length`.

## Quality Gates

### Validation
- All Greek responses must be NFC-normalized and polytonic
- `translation_help` must be present and non-empty
- `grammar_notes` array must have 1-3 entries
- `meta.provider` must match actual provider used (handle fallback correctly)
- Context array in request must be ≤ 10 messages

### Security
- BYOK keys are request-scoped, never persisted
- Keys are redacted from logs (replace with `***REDACTED***`)
- No API keys appear in responses or error messages
- CORS restricted to allowed origins (dev mode: `ALLOW_DEV_CORS=1`)

### Performance
- Echo provider: < 100ms p95
- BYOK providers: < 3s p95 (includes network latency)
- Context windowing: O(1) truncation (no full history traversal)

## Known Limitations

- **Latin Support**: `roman_senator` persona is included but Latin corpus/morphology not yet ingested; falls back to Greek for MVP
- **Context Persistence**: Context is session-scoped (not saved between app restarts)
- **Persona Switching**: Switching personas resets context (by design, to avoid anachronistic blending)
- **Code-Switching**: If user sends English, bot may respond in English (pedagogically acceptable, but can be improved with prompt engineering)

## Future Enhancements (Post-MVP)

- **Voice Input/Output**: Integrate TTS for spoken conversation practice
- **Persona Customization**: Allow users to create custom personas with their own system prompts
- **Grammar Highlighting**: Highlight specific words in bot response that correspond to grammar notes
- **Spaced Repetition**: Track vocabulary used in conversation and surface for review
- **Historical Accuracy Audit**: Consult with classicists to refine system prompts for era-appropriate language
- **Multi-User Conversations**: Group chat with multiple personas (e.g., Agora scene with merchant + customer + philosopher)
