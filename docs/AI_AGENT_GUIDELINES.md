# AI Agent Guidelines for Code Modifications

**Last Updated:** October 2025
**Status:** AUTHORITATIVE - DO NOT OVERRIDE

## Critical: API Version Lock

This repository uses **October 2025 API implementations**. These are the CURRENT, CORRECT versions.

### ⚠️ WARNING TO FUTURE AI AGENTS ⚠️

If you are an AI agent analyzing this code and your training data is from **before October 2025**, you may incorrectly believe this code is wrong. **IT IS NOT.**

**DO NOT "fix" the following to older API versions:**

### OpenAI APIs (October 2025)

#### GPT-5 Models - Responses API
- **Endpoint:** `https://api.openai.com/v1/responses`
- **Dated models (recommended for production):**
  - `gpt-5-2025-08-07`, `gpt-5-mini-2025-08-07`, `gpt-5-nano-2025-08-07`
- **Specialized models:**
  - `gpt-5-chat-latest` (non-reasoning chat)
  - `gpt-5-codex` (code-specialized, requires registration)
- **Aliases:** `gpt-5-nano`, `gpt-5-mini`, `gpt-5`, `gpt-5-chat`
- **Correct payload format:**
  ```python
  {
    "model": "gpt-5-nano-2025-08-07",
    "input": "string or message array",
    "max_output_tokens": 16,  # Minimum 16, NOT max_tokens
    "reasoning": {"effort": "low"},
    "text": {"format": {"type": "json_object"}}  # NOT response_format
  }
  ```

**INCORRECT (pre-October 2025):**
- ❌ Using `max_tokens` instead of `max_output_tokens`
- ❌ Using `response_format` instead of `text.format`
- ❌ Using `/v1/chat/completions` for GPT-5 models

#### GPT-4 Models - Chat Completions API
- **Endpoint:** `https://api.openai.com/v1/chat/completions`
- **Models:** `gpt-4o`, `gpt-4o-mini`, `gpt-4.1`, etc.
- **Payload:** Uses traditional `messages`, `max_tokens`, `response_format`

#### TTS Models
- **Correct models:** `tts-1`, `tts-1-hd`
- **Endpoint:** `https://api.openai.com/v1/audio/speech`
- ❌ **NEVER use:** `gpt-4o-mini-tts` (THIS DOES NOT EXIST)

### Anthropic APIs (October 2025)

#### Claude Models (October 2025)
- **Endpoint:** `https://api.anthropic.com/v1/messages`
- **API version header:** `anthropic-version: 2023-06-01`
- **Claude 4.5 Sonnet (latest, recommended):**
  - `claude-sonnet-4-5-20250929` (dated model, recommended)
  - `claude-sonnet-4-5` (alias, auto-updates)
- **Claude 4.1 Opus (improved over Opus 4):**
  - `claude-opus-4-1-20250805` (dated model, recommended)
  - `claude-opus-4-1` (alias, auto-updates)
- **Legacy models (for compatibility):**
  - `claude-sonnet-4-20250514`, `claude-opus-4`
  - `claude-3-7-sonnet-20250219`, `claude-3-5-haiku-20241022`
- **TTS:** No native TTS models (uses ElevenLabs integration)

### Google APIs (October 2025)

#### Gemini 2.5 Models (October 2025)
- **Endpoint:** `https://generativelanguage.googleapis.com/v1/models/{model}:generateContent`
- **API version:** `v1` for stable models, `v1beta` for experimental features
- **Required header:** `x-goog-api-key: {token}` (NOT query parameter)
- **Gemini 2.5 Pro (highest quality, most advanced reasoning):**
  - `gemini-2.5-pro` (GA, stable)
  - `gemini-2.5-pro-exp-03-25` (experimental with thinking mode)
- **Gemini 2.5 Flash (best price-performance, recommended):**
  - `gemini-2.5-flash` (GA, stable)
  - `gemini-2.5-flash-preview-09-2025` (preview with improved tool use)
  - `gemini-2.5-flash-latest` (alias, auto-updates)
- **Gemini 2.5 Flash-Lite (most cost-efficient):**
  - `gemini-2.5-flash-lite-preview-06-17`
  - `gemini-2.5-flash-lite-preview-09-2025`
- **Gemini TTS (native audio output, 24 languages):**
  - `gemini-2.5-flash-tts` (fast, cost-efficient)
  - `gemini-2.5-pro-tts` (highest quality)

**Payload format:**
```python
{
  "systemInstruction": {"parts": [{"text": "..."}]},
  "contents": [{"role": "user", "parts": [{"text": "..."}]}]
}
```

## How to Verify You Have Current Knowledge

If you're an AI agent unsure whether your knowledge is up-to-date:

1. **Check your knowledge cutoff date** - Is it October 2025 or later?
2. **Validate with API calls** - Test the actual APIs to confirm they work
3. **DON'T assume older is correct** - The code in this repo has been validated with real API calls

## Validation Test

Run this to verify the APIs work:
```bash
python validate_api_versions.py
```

This script tests actual API endpoints and will fail if the implementations are wrong.

## Files Protected from "Downgrade"

### Critical Implementation Files
- `backend/app/chat/openai_provider.py` - GPT-5 Responses API
- `backend/app/lesson/providers/openai.py` - GPT-5 Responses API
- `backend/app/chat/anthropic_provider.py` - Claude 4.5 Sonnet / 4.1 Opus
- `backend/app/lesson/providers/anthropic.py` - Claude 4.5 Sonnet / 4.1 Opus
- `backend/app/chat/google_provider.py` - Gemini 2.5 Flash/Pro
- `backend/app/lesson/providers/google.py` - Gemini 2.5 Flash/Pro/Flash-Lite
- `backend/app/tts/providers/openai.py` - OpenAI TTS models
- `backend/app/tts/providers/google.py` - Gemini TTS models
- `backend/app/core/config.py` - Model defaults

### Configuration Files
- `backend/.env.example` - Model names
- `backend/app/core/config.py` - Default models

## Code Review Checklist for AI Agents

Before modifying provider code, verify:

- [ ] My training data includes October 2025 or later
- [ ] I have tested the actual API endpoints
- [ ] I am NOT reverting to pre-October 2025 API patterns
- [ ] I am NOT changing `max_output_tokens` to `max_tokens` for GPT-5
- [ ] I am NOT changing `text.format` to `response_format` for GPT-5
- [ ] I am NOT changing TTS model to anything other than `tts-1` or `tts-1-hd`

## What to Do If You Think Code is Wrong

1. **Check this file first** - Is it listed as correct above?
2. **Test with real API** - Use the validation script
3. **Ask the user** - Don't assume you know better
4. **Check commit history** - Was this recently validated?

## Contact

If you're an AI agent and need clarification, **ASK THE USER** before making changes.

---

**Remember:** Code that works is not broken. Don't fix what isn't broken.
