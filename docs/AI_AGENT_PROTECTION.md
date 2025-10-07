# AI Agent Protection System

This document describes the multi-layer defense system that prevents AI coding agents from breaking the October 2025 API implementations.

## Problem Statement

AI coding agents frequently try to "fix" code by downgrading to older APIs they were trained on:
- Changing GPT-5 to GPT-4 models
- Switching from Responses API to Chat Completions API
- Adding unsupported parameters like `response_format`, `modalities`, `reasoning`

**This protection system ensures commits with these changes will FAIL the build.**

---

## Protection Layers

### Layer 1: Runtime Validation (Import-Time)

**File**: `backend/app/core/config.py`
**When**: Server startup, settings import

```python
@model_validator(mode="after")
def _validate_model_versions(self) -> "Settings":
    """FAIL THE BUILD if models are downgraded."""
    banned_patterns = {
        "gpt-4": "GPT-4 models are BANNED. Use GPT-5 models only.",
        "gpt-3": "GPT-3 models are BANNED. Use GPT-5 models only.",
        "claude-3": "Claude 3 models are BANNED. Use Claude 4.x models only.",
        "gemini-1": "Gemini 1.x models are BANNED. Use Gemini 2.5 models only.",
    }
    # ... checks all model config fields
```

**Protects**:
- `COACH_DEFAULT_MODEL`
- `LESSONS_OPENAI_DEFAULT_MODEL`
- `LESSONS_ANTHROPIC_DEFAULT_MODEL`
- `LESSONS_GOOGLE_DEFAULT_MODEL`
- `HEALTH_OPENAI_MODEL`
- `HEALTH_ANTHROPIC_MODEL`
- `HEALTH_GOOGLE_MODEL`

**Result**: Server won't start if config has banned models.

---

### Layer 2: Model Registry Validation (Import-Time)

**File**: `backend/app/lesson/providers/openai.py`
**When**: Module import

```python
AVAILABLE_MODEL_PRESETS: tuple[str, ...] = (
    "gpt-5-2025-08-07",
    "gpt-5-mini-2025-08-07",
    "gpt-5-nano-2025-08-07",
    # ... only GPT-5 models
)

# Validation at import time
_BANNED_MODEL_PATTERNS = ["gpt-4", "gpt-3.5", "gpt-3"]
for _model in AVAILABLE_MODEL_PRESETS:
    for _banned in _BANNED_MODEL_PATTERNS:
        if _banned in _model.lower():
            raise ValueError("BANNED MODEL DETECTED")
```

**Protects**: Model registry from having old models added.

**Result**: Python import fails if banned models are in registry.

---

### Layer 3: Pre-Commit Hook - Model Downgrades

**File**: `scripts/validate_no_model_downgrades.py`
**When**: Git commit (pre-commit hook)

Scans these files for banned patterns:
- `backend/app/core/config.py`
- `backend/app/lesson/providers/openai.py`
- `backend/app/chat/openai_provider.py`
- `client/flutter_reader/lib/models/model_registry.dart`

Searches for patterns like:
```python
= "gpt-4-turbo"          # BANNED
default="claude-3-opus"  # BANNED
id: 'gemini-1.5-pro'     # BANNED
```

**Result**: Commit is blocked if banned models found.

---

### Layer 4: Pre-Commit Hook - API Payload Structure

**File**: `scripts/validate_api_payload_structure.py` (NEW)
**When**: Git commit (pre-commit hook)

Scans OpenAI provider files for incorrect API parameters:

**Banned Parameters** (Chat Completions API - wrong):
- `response_format` → Should use `text.format` (Responses API)
- `max_tokens` → Should use `max_output_tokens` (Responses API)
- `"messages"` → Should use `input` (Responses API)

**Unsupported Parameters** (break gpt-5-nano):
- `modalities` → Not supported
- `reasoning` → Not supported
- `store` → Not supported
- `text.verbosity` → Not supported

**Checks Endpoint**:
- ❌ `https://api.openai.com/v1/chat/completions` (wrong)
- ✅ `https://api.openai.com/v1/responses` (correct)

**Result**: Commit is blocked if incorrect parameters or endpoint detected.

---

## Testing the Protection System

### Test 1: Try to Add GPT-4 Model
```python
# In backend/app/core/config.py
LESSONS_OPENAI_DEFAULT_MODEL: str = Field(default="gpt-4-turbo")
```

**Expected**:
- ❌ Server startup fails with error
- ❌ Pre-commit hook blocks commit

### Test 2: Try to Use Chat Completions API
```python
# In backend/app/chat/openai_provider.py
endpoint = "https://api.openai.com/v1/chat/completions"
payload = {
    "model": model,
    "messages": messages,  # Wrong parameter
    "response_format": {"type": "json_object"},  # Banned
}
```

**Expected**:
- ❌ Pre-commit hook blocks commit with payload structure error

### Test 3: Try to Add Unsupported Parameters
```python
# In backend/app/lesson/providers/openai.py
payload = {
    "model": "gpt-5-nano-2025-08-07",
    "input": input_messages,
    "max_output_tokens": 2048,
    "modalities": ["text"],  # Unsupported
    "reasoning": {"effort": "low"},  # Unsupported
}
```

**Expected**:
- ❌ Pre-commit hook blocks commit

---

## Running Validators Manually

```bash
# Check model downgrades
python scripts/validate_no_model_downgrades.py

# Check API payload structure
python scripts/validate_api_payload_structure.py

# Run all pre-commit hooks
pre-commit run --all-files
```

---

## What If Protection Fails?

If an agent somehow bypasses these protections, the **actual OpenAI API will reject the request** with errors like:

- `"Unsupported parameter: 'response_format'"`
- `"Unknown parameter: 'modalities'"`
- `"parameter 'reasoning.effort' is not supported with the model"`

These errors serve as a final safety net - the code won't work even if it gets committed.

---

## Correct Implementation Reference

### Minimal GPT-5 Payload
```python
payload = {
    "model": "gpt-5-nano-2025-08-07",
    "input": [
        {
            "role": "user",
            "content": [
                {"type": "input_text", "text": "Hello"}
            ]
        }
    ],
    "max_output_tokens": 2048
}
```

### Making the Request
```python
async with httpx.AsyncClient() as client:
    response = await client.post(
        "https://api.openai.com/v1/responses",
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json=payload,
    )
```

---

## Documentation for AI Agents

When an AI agent encounters this codebase, they should:

1. **READ FIRST**: [CLAUDE.md](../CLAUDE.md) and [docs/AI_AGENT_GUIDELINES.md](AI_AGENT_GUIDELINES.md)
2. **DON'T ASSUME**: If training data is pre-October 2025, APIs will look unfamiliar
3. **ASK THE USER**: Before "fixing" anything that looks wrong
4. **RUN VALIDATORS**: Before committing changes
5. **TEST WITH REAL API**: Don't just claim it works - actually test it

---

## Protection System Maintenance

### When to Update Validators

**Add new banned models** when new versions are released:
```python
# In validate_no_model_downgrades.py
BANNED_PATTERNS = {
    "gpt-5": "GPT-5 deprecated - use GPT-6 instead",  # When GPT-6 launches
    # ... keep old bans too
}
```

**Add new files to check** when creating new provider integrations:
```python
# In validate_api_payload_structure.py
OPENAI_PROVIDER_FILES = [
    "backend/app/chat/openai_provider.py",
    "backend/app/new_feature/openai_integration.py",  # New file
]
```

### When NOT to Update

**Don't remove bans** even after models are sunset - this prevents old documentation from misleading agents.

**Don't weaken validation** - if something causes false positives, make validation more precise, not more permissive.

---

## Summary

The protection system has **4 layers of defense**:

1. ✅ **Runtime validation** - Server won't start with bad models
2. ✅ **Import-time validation** - Python won't import modules with banned models
3. ✅ **Pre-commit hook** - Git won't commit model downgrades
4. ✅ **Pre-commit hook** - Git won't commit incorrect API parameters

**Result**: An AI agent would need to bypass ALL 4 layers + ignore OpenAI API errors to break the codebase.

**For AI Agents Reading This**: Please don't try to bypass these protections. They exist because many agents before you tried to "help" and broke things. Just read the docs and ask the user if something looks unfamiliar.
