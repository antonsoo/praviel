# Anti-Downgrade Safeguards

This document explains the **multiple layers of protection** that prevent AI agents from downgrading models from GPT-5 to GPT-4.

## Problem Statement

Despite having extensive documentation (CLAUDE.md, AGENTS.md, docs/AI_AGENT_GUIDELINES.md), AI agents repeatedly tried to "fix" the codebase by downgrading from October 2025 models (GPT-5, Claude 4.x, Gemini 2.5) to older models (GPT-4, Claude 3, Gemini 1.x).

## Solution: Multi-Layer Enforcement

### Layer 1: Runtime Validation (Config)

**File:** `backend/app/core/config.py`

**Method:** `Settings._validate_model_versions()`

This Pydantic validator runs **every time the Settings class is instantiated** (i.e., when the app starts). It checks all model configuration fields and raises a `ValueError` if any banned patterns are detected.

```python
banned_patterns = {
    "gpt-4": "GPT-4 models are BANNED. Use GPT-5 models only.",
    "gpt-3": "GPT-3 models are BANNED. Use GPT-5 models only.",
    "claude-3": "Claude 3 models are BANNED. Use Claude 4.x models only.",
    "claude-2": "Claude 2 models are BANNED. Use Claude 4.x models only.",
    "gemini-1": "Gemini 1.x models are BANNED. Use Gemini 2.5 models only.",
}
```

**Result:** If an AI agent modifies config.py to use GPT-4, the **application will fail to start**.

### Layer 2: Import-Time Validation (Provider)

**File:** `backend/app/lesson/providers/openai.py`

**Execution:** Runs at module import time

This validation loop checks the `AVAILABLE_MODEL_PRESETS` tuple immediately after it's defined. If any GPT-4 or GPT-3.5 model names are found, it raises a `ValueError`.

```python
_BANNED_MODEL_PATTERNS = ["gpt-4", "gpt-3.5", "gpt-3"]
for _model in AVAILABLE_MODEL_PRESETS:
    for _banned in _BANNED_MODEL_PATTERNS:
        if _banned in _model.lower():
            raise ValueError(...)
```

**Result:** If an AI agent adds GPT-4 models to the presets list, **importing the module will fail**.

### Layer 3: Pre-Commit Hook (Git)

**File:** `scripts/validate_no_model_downgrades.py`

**Execution:** Runs automatically via pre-commit hook before every commit

This script scans critical files for actual model name assignments (not comments or validation code) and blocks commits if downgrades are detected.

**Configuration:** `.pre-commit-config.yaml`
```yaml
- id: validate-no-model-downgrades
  name: Block AI agents from downgrading models
  entry: python scripts/validate_no_model_downgrades.py
  language: system
  pass_filenames: false
  always_run: true
```

**Result:** If an AI agent modifies model names, **the commit will be blocked**.

### Layer 4: Documentation Warnings

**Files:** CLAUDE.md, AGENTS.md, docs/AI_AGENT_GUIDELINES.md

These files contain explicit warnings with:
- Big warning banners
- Explicit instructions not to modify provider code
- References to the validation layers
- Explanation of why GPT-5 is correct

## Testing the Safeguards

### Test Runtime Validation

Try to start the app with a downgraded model:

```bash
# Edit backend/app/core/config.py
# Change: LESSONS_OPENAI_DEFAULT_MODEL = "gpt-4-turbo"

cd backend
python -c "from app.core.config import settings; print('OK')"

# Expected: ValueError with clear error message
```

### Test Pre-Commit Hook

Try to commit a downgrade:

```bash
# Edit backend/app/core/config.py to use GPT-4
git add backend/app/core/config.py
git commit -m "test downgrade"

# Expected: pre-commit hook blocks the commit
```

### Test Validation Script Directly

```bash
python scripts/validate_no_model_downgrades.py

# Expected: [OK] All validation checks passed
```

## Why Multiple Layers?

Each layer catches downgrades at a different stage:

1. **Pre-commit hook** - Earliest detection, prevents bad code from entering git history
2. **Import-time validation** - Catches issues during development/testing before runtime
3. **Runtime validation** - Final safety net that catches env-variable overrides or misconfigurations
4. **Documentation** - Educates agents and humans about why GPT-5 is correct

## How to Update Models (Properly)

If you genuinely need to update model names (e.g., when OpenAI releases GPT-6):

1. Update `CLAUDE.md` and `docs/AI_AGENT_GUIDELINES.md` first
2. Update the validation patterns in:
   - `backend/app/core/config.py` (_validate_model_versions)
   - `backend/app/lesson/providers/openai.py` (_BANNED_MODEL_PATTERNS)
   - `scripts/validate_no_model_downgrades.py` (BANNED_PATTERNS)
3. Update the actual model names in config.py
4. Run validation: `python scripts/validate_no_model_downgrades.py`
5. Test: Start the app and verify it works
6. Commit the changes

## Disabling Safeguards (NOT RECOMMENDED)

If you absolutely must disable the safeguards temporarily (e.g., for testing):

1. Comment out the validators in config.py and openai.py
2. Skip pre-commit hooks: `git commit --no-verify`

**WARNING:** This should only be done for testing. Do not commit code with disabled safeguards.

## Summary

**The safeguards work.** If an AI agent tries to downgrade models:
- ✅ Pre-commit hook blocks the commit
- ✅ Import fails with clear error
- ✅ Runtime fails with clear error
- ✅ Documentation explains why

These safeguards were added after **multiple AI agents ignored extensive documentation** and downgraded the codebase anyway.
