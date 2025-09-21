# Coach Endpoint (PR-E)

Experimental Classical Greek coaching endpoint guarded by feature flags and Bring-Your-Own-Key (BYOK). Disabled by default.

## Enable the endpoint

Set the following env vars for the backend:

```bash
export COACH_ENABLED=true
export BYOK_ENABLED=true      # required when using non-echo providers
# optional override
export COACH_DEFAULT_MODEL=gpt-4o-mini
```

The server mounts `/coach/chat` only when `COACH_ENABLED=true`. Leave the flag off in production until the feature is ready.

## Request contract

`POST /coach/chat`

Headers:
- `Content-Type: application/json`
- BYOK token (providers other than `echo`):
  - `Authorization: Bearer <token>` **or**
  - `X-Model-Key: <token>`

Payload:

```json
{
  "q": "optional question string",
  "history": [{"role": "user", "content": "previous turn"}],
  "provider": "echo" | "openai",
  "model": "optional provider-specific model"
}
```

- `q` can be omitted when the last `history` turn is from the user.
- `provider` defaults to `echo`, which requires no external key.
- When `provider` is not `echo`, a BYOK token must be present; the server reads it from the request and never persists it.

## Response shape

```json
{
  "answer": "model reply",
  "citations": ["Work.Ref"],
  "usage": {"input_tokens": 123, "output_tokens": 45}
}
```

`citations` mirrors the short-list of passages retrieved via the existing hybrid search. `usage` echoes whatever the upstream provider returns (if any).

## Example (echo provider)

```bash
curl -X POST http://localhost:8000/coach/chat \
  -H "Content-Type: application/json" \
  -d '{
        "q": "Τί ἐστιν ἀρετή;",
        "provider": "echo"
      }'
```

The echo provider responds deterministically (helpful for smoke tests). To test BYOK providers locally, include `Authorization: Bearer …` or `X-Model-Key: …` in the headers.

## Notes

- BYOK values are stored on `request.state` only for the lifetime of the request; redaction middleware hides them from logs.
- Retrieval uses the same hybrid helper as `/reader/analyze` (Greek language filter, small `k`).
- Runtime dependencies stay lean: the OpenAI provider imports `httpx` lazily.
