# Lesson v0 (flagged) — API contract & usage

`LESSONS_ENABLED=1` mounts `POST /lesson/generate`, a compact generator for beginner Classical-/Koine-style drills:

* **Sources**: "daily" (team-authored YAML, natural daily speech) and "canon" (Iliad 1.1–1.10 slice via LDS).
* **Providers**: `echo` (offline, deterministic) and `openai` (BYOK; keys are request-scoped only).
* **Task types**: `alphabet`, `match`, `cloze` (canonical refs), `translate`.

## Request
```json
{
  "language": "grc",
  "profile": "beginner",
  "sources": ["daily","canon"],
  "exercise_types": ["alphabet","match","cloze","translate"],
  "k_canon": 2,
  "include_audio": false,
  "provider": "echo",
  "model": "optional"
}
```

**Headers for BYOK providers** (non-echo):
`Authorization: Bearer <token>` *or* `X-Model-Key: <token>`. Tokens are read per request and never persisted; redaction middleware removes them from logs.

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

## Seed data policy
Daily lines live in `backend/app/lesson/seed/daily_grc.yaml` with English glosses; they are team-authored (no licensing entanglements). Canonical lines are fetched via LDS from allowed slices with NFC/fold normalization and a `ref` (e.g., `Il.1.1`). Never commit vendor texts to the repo.

## Error handling & fallback
Provider failures or missing keys automatically fall back to `echo` and still return a valid lesson. The `openai` adapter imports `httpx` lazily and enforces short timeouts.

## TTS roadmap (post-MVP)
We will add a pluggable TTS layer behind a flag. TTS will remain BYOK and observe the licensing matrix to block NC sources for audio.
