# BYOK Provider Setup

This guide explains how to configure server-side API keys for vendor LLM providers (OpenAI, Anthropic, Google).

## Overview

The application supports two modes for API key management:

1. **Server-side keys** (configured in `.env`) - Keys are stored on the server and used automatically
2. **BYOK (Bring Your Own Key)** - Users provide their own API keys per-request via headers

Server-side keys take precedence over BYOK tokens. This setup guide focuses on server-side configuration.

## Environment Variables

Add these variables to `backend/.env`:

```bash
# Vendor API Keys (server-side)
OPENAI_API_KEY=sk-proj-...
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=AIza...

# Echo Fallback Control (disabled by default - show real errors)
ECHO_FALLBACK_ENABLED=false
```

### Obtaining API Keys

- **OpenAI**: https://platform.openai.com/api-keys
- **Anthropic**: https://console.anthropic.com/settings/keys
- **Google AI Studio**: https://aistudio.google.com/app/apikey

## Setup Methods

### Method 1: .env file (recommended)

1. Create `backend/.env` (or edit existing)
2. Add API keys as shown above
3. Restart server: `py -m uvicorn app.main:app --reload`

### Method 2: Shell environment

```bash
export OPENAI_API_KEY=sk-proj-...
export ANTHROPIC_API_KEY=sk-ant-...
export GOOGLE_API_KEY=AIza...
export ECHO_FALLBACK_ENABLED=false

cd backend
py -m uvicorn app.main:app --reload
```

## Verification

### Step 1: Check Startup Logs

When the server starts, you should see:

```
INFO - Checking vendor API keys...
INFO - OpenAI API key loaded (length: 164)
INFO - Anthropic API key loaded (length: 108)
INFO - Google API key loaded (length: 39)
INFO - Echo fallback enabled: False
```

### Step 2: Test Health Endpoint

```bash
curl http://localhost:8000/health/providers | jq
```

**Expected response:**

```json
{
  "anthropic": {
    "ok": true,
    "status": 200,
    "error": null
  },
  "google": {
    "ok": true,
    "status": 200,
    "error": null
  },
  "openai": {
    "ok": true,
    "status": 200,
    "error": null
  },
  "timestamp": 1759442842
}
```

**Note:** OpenAI may show `"ok": false, "status": 429` if you've exceeded your quota or rate limit.

### Step 3: Test Lesson Generation

**Anthropic:**

```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H "Content-Type: application/json" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily"],
    "exercise_types": ["match"],
    "provider": "anthropic"
  }' | jq '.meta'
```

**Expected:**

```json
{
  "language": "grc",
  "profile": "beginner",
  "provider": "anthropic",
  "model": "claude-sonnet-4-5-20250929"
}
```

**Google/Gemini:**

```bash
curl -X POST http://localhost:8000/lesson/generate \
  -H "Content-Type: application/json" \
  -d '{
    "language": "grc",
    "profile": "beginner",
    "sources": ["daily"],
    "exercise_types": ["match"],
    "provider": "google"
  }' | jq '.meta'
```

**Expected:**

```json
{
  "language": "grc",
  "profile": "beginner",
  "provider": "google",
  "model": "gemini-2.5-flash"
}
```

## Supported Models

### Anthropic

- `claude-sonnet-4-5-20250929` (default)
- `claude-3-5-sonnet-20241022`
- `claude-3-5-haiku-20241022`

### Google

- `gemini-2.5-flash` (default)
- `gemini-2.5-flash-lite`

### OpenAI

- `gpt-5-mini-2025-08-07` (default)
- `gpt-4o-mini` (may auto-upgrade to configured default)
- `gpt-4o`

## Error Handling

### Echo Fallback Disabled (Default)

When `ECHO_FALLBACK_ENABLED=false` (default), provider failures return HTTP 503 errors with clear messages:

```json
{
  "detail": "anthropic provider requires API key. Set ANTHROPIC_API_KEY in server environment or provide BYOK token."
}
```

```json
{
  "detail": "openai provider failed: openai_http_429"
}
```

### Echo Fallback Enabled

When `ECHO_FALLBACK_ENABLED=true`, provider failures silently fall back to the echo provider:

```json
{
  "meta": {
    "provider": "echo",
    "note": "byok_missing_fell_back_to_echo"
  }
}
```

**Recommendation:** Keep fallback disabled in production to ensure errors are visible.

## Retry Logic

The OpenAI provider includes automatic retry logic for transient errors:

- **Retries:** Up to 3 attempts
- **Triggers:** HTTP 429 (rate limit) and 503 (unavailable)
- **Backoff:** Exponential with jitter (0.5s, 1s, 1.5s)
- **Logs:** Each retry is logged as WARNING

## Troubleshooting

### Provider returns "echo" instead of requested provider

**Causes:**

- Server-side API key not configured
- API key is invalid
- Echo fallback is enabled

**Solutions:**

1. Check `GET /health/providers` - is provider reachable?
2. Verify API key is set in `.env`
3. Check server startup logs for "API key loaded" messages
4. Ensure `ECHO_FALLBACK_ENABLED=false`

### HTTP 429 (Rate Limit)

**OpenAI free tier has very low limits.**

Solutions:

- Reduce request frequency
- Upgrade to paid tier
- Use Anthropic or Google instead

Server will automatically retry 3 times with backoff.

### HTTP 503 (Service Unavailable)

**Causes:**

- Provider is down
- API key is invalid
- Network connectivity issue

**Solutions:**

- Check provider status page
- Verify API key is correct
- Test with `curl` directly to vendor API

### HTTP 401/403 (Authentication Error)

**Causes:**

- Invalid API key
- Expired API key
- IP restrictions

**Solutions:**

- Regenerate API key from vendor console
- Check account billing status
- Verify no IP allow-list restrictions

## Security

- **DO NOT** commit `.env` to version control
- `.env` is listed in `.gitignore` by default
- API keys are automatically redacted from logs
- Server-side keys are only accessible to backend process

## Testing

Run integration tests:

```bash
cd backend
pytest app/tests/test_byok_providers.py -v
```

Tests verify:

- Health endpoint returns provider status
- Anthropic provider works with real API key
- Google provider works with real API key
- OpenAI handles rate limits correctly
- Echo provider works without keys
