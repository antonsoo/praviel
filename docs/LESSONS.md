# Lesson v0 (flagged) — API contract & usage

`LESSONS_ENABLED=1` mounts `POST /lesson/generate`, a compact generator for beginner Classical-/Koine-style drills:

* **Sources**: "daily" (team-authored YAML, natural daily speech) and "canon" (Iliad 1.1–1.10 slice via LDS).
* **Providers**:
  - `echo` (offline, deterministic) – no key required
  - `anthropic` (BYOK, Claude models) – requires `x-api-key` header
  - `openai` (BYOK, GPT models) – requires `Authorization: Bearer` header
  - `google` (BYOK, Gemini models) – requires API key as query param

  All BYOK keys are request-scoped only. The `model` field specifies which model to use:
  - Anthropic: `claude-sonnet-4-5`, `claude-opus-4-1-20250805`, `claude-sonnet-4`, `claude-opus-4`
  - OpenAI: `gpt-5`, `gpt-5-mini`, `gpt-5-nano`
  - Google: `gemini-2.5-flash`, `gemini-2.5-flash-lite`, `gemini-2.5-flash-preview-09-2025`
* **Task types**: `alphabet`, `match`, `cloze` (canonical refs), `translate`.

## Request examples

### Echo provider (no key)
```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily","canon"],
    "exercise_types": ["alphabet","match","cloze","translate"],
    "k_canon": 2,
    "include_audio": false,
    "provider": "echo"
  }'
```

### Anthropic provider (Claude)
```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer sk-ant-...' \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily"],
    "exercise_types": ["match","translate"],
    "provider": "anthropic",
    "model": "claude-sonnet-4-5",
    "include_audio": false
  }'
```

### OpenAI provider (GPT)
```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer sk-...' \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily"],
    "exercise_types": ["match","translate"],
    "provider": "openai",
    "model": "gpt-5-mini",
    "include_audio": false
  }'
```

### Google provider (Gemini)
```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer AIza...' \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily"],
    "exercise_types": ["match","translate"],
    "provider": "google",
    "model": "gemini-2.5-flash",
    "include_audio": false
  }'
```

**Headers for BYOK providers** (non-echo):
- `Authorization: Bearer <token>` (standard)
- `X-Model-Key: <token>` (alternative)

Tokens stay request-scoped and are wiped after each call; the redaction middleware removes them from logs. `Authorization` is parsed with standard Bearer semantics (case-insensitive), while `X-Model-Key` accepts the raw token. Missing BYOK headers no longer raise 400 responses—the request downgrades to the offline echo provider instead.

## Response (schema)
```json
{
  "meta": {"language":"grc","profile":"beginner","provider":"echo","model":"echo"},
  "tasks": [
    {"type":"alphabet","prompt":"Select the letter named 'beta'","options":["β","δ","λ","π"],"answer":"β"},
    {"type":"match","pairs":[{"grc":"Χαῖρε","en":"Hello"},{"grc":"Τί κάνεις;","en":"How are you?"}]},
    {"type":"cloze","source_kind":"canon","ref":"Il.1.1","text":"Μῆνιν ἄειδε … Πηληϊάδεω Ἀχιλῆος","blanks":[{"surface":"Μῆνιν","idx":0},{"surface":"ἄειδε","idx":1}],"options":["Μῆνιν","ἄειδε","Πηληϊάδεω","Ἀχιλῆος"]},
    {"type":"translate","direction":"grc→en","text":"Χαῖρε· τί κάνεις;","rubric":"Write a natural English translation."}
  ]
}
```

*Optional cloze options:* Providers may include `options` (3–6 choices including the correct token(s)) to support multiple-choice UIs. Clients not using choices can ignore unknown fields. Canonical tasks still require `ref`; daily tasks may keep `ref: null`.

## Quality guarantees

The lesson QA harness (`backend/app/tests/test_lesson_quality.py`) generates 12 lessons across the `daily`+`canon` mix and writes `artifacts/lesson_qa_report.json`. It asserts:

* Greek text is NFC-normalized and passes CLTK accent-fold checks (no mixed-script tokens).
* Canonical tasks always include a non-empty `ref` value.
* When `cloze.options` are present, each correct blank surface appears exactly once.
* Match pairs are unique and non-empty.
* Missing or bad BYOK headers downgrade to the offline echo provider with `meta.note=byok_missing_fell_back_to_echo`.

Run `pytest backend/app/tests/test_lesson_quality.py` locally to regenerate the report before shipping lesson changes.
## Seed data policy
Daily lines live in `backend/app/lesson/seed/daily_grc.yaml` with English glosses; they are team-authored (no licensing entanglements). Canonical lines are fetched via LDS from allowed slices with NFC/fold normalization and a `ref` (e.g., `Il.1.1`). Never commit vendor texts to the repo.

## Error handling & fallback
Provider failures or missing keys automatically fall back to `echo` and still return a valid lesson. All BYOK adapters import `httpx` lazily and enforce short timeouts.
When a downgrade happens the response carries `meta.note` so clients can surface the reason. Current codes:
- `byok_missing_fell_back_to_echo` (no BYOK header was supplied)
- `anthropic_401` / `openai_401` / `google_401` (rejected token)
- `anthropic_403` / `openai_403` / `google_403` (policy block)
- `anthropic_404_model` / `openai_404_model` / `google_404_model` (model unavailable)
- `anthropic_timeout` / `openai_timeout` / `google_timeout` (provider timeout)
- `anthropic_network` / `openai_network` / `google_network` (network/transport failure)
- `anthropic_http_<status>` / `openai_http_<status>` / `google_http_<status>` (HTTP error)
- `anthropic_bad_payload` / `openai_bad_payload` / `google_bad_payload` (malformed JSON)
- `byok_failed_fell_back_to_echo` (safety net for unexpected adapter errors)
Logs include only the provider, model, and a redacted token fingerprint.

## TTS roadmap (post-MVP)
We will add a pluggable TTS layer behind a flag. TTS will remain BYOK and observe the licensing matrix to block NC sources for audio.
