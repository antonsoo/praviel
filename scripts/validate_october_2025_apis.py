#!/usr/bin/env python3
"""Validate that October 2025 API implementations haven't been regressed.

This script checks critical files to ensure they still use October 2025 APIs:
- Lesson providers: GPT-5, Claude 4.5/4.1, Gemini 2.5
- Chat providers: GPT-5, Claude 4.5 Sonnet, Gemini 2.5 Flash
- GPT-5 uses Responses API with max_output_tokens, text.format, etc.
- Claude 4.5/4.1 model names are correct
- Gemini 2.5 model names are correct
- TTS models are correct (tts-1, tts-1-hd, not fake models)

Run this script before committing changes to provider files to catch regressions.

Exit codes:
    0: All validations passed
    1: One or more validations failed (code has been regressed)
"""

import sys
from pathlib import Path
from typing import List, Tuple

# Base directory is repo root
REPO_ROOT = Path(__file__).parent.parent


class ValidationError(Exception):
    """Raised when a validation check fails."""

    pass


def validate_openai_lesson_provider() -> List[str]:
    """Validate backend/app/lesson/providers/openai.py uses October 2025 APIs."""
    errors = []
    file_path = REPO_ROOT / "backend" / "app" / "lesson" / "providers" / "openai.py"

    if not file_path.exists():
        return [f"❌ File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # Check for GPT-5 model names
    if '"gpt-5-' not in content and "'gpt-5-" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing GPT-5 models. "
            "Should include gpt-5-2025-08-07, gpt-5-mini-2025-08-07, etc."
        )

    # Check for max_output_tokens (GPT-5 Responses API)
    if "max_output_tokens" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing 'max_output_tokens'. "
            "GPT-5 Responses API requires max_output_tokens (not max_tokens)"
        )

    # Check for text.format (GPT-5 Responses API)
    if '"text"' not in content or '"format"' not in content:
        errors.append(
            f"❌ {file_path.name}: Missing 'text' and 'format' keys. "
            "GPT-5 Responses API uses text.format (not response_format)"
        )

    # Check for /v1/responses endpoint
    if "/v1/responses" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing '/v1/responses' endpoint. "
            "GPT-5 uses /v1/responses (not /v1/chat/completions)"
        )

    # Check for reasoning parameter (GPT-5 only)
    if '"reasoning"' not in content and "'reasoning'" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing 'reasoning' parameter. "
            "GPT-5 Responses API includes reasoning.effort parameter"
        )

    return errors


def validate_anthropic_lesson_provider() -> List[str]:
    """Validate backend/app/lesson/providers/anthropic.py uses October 2025 models."""
    errors = []
    file_path = REPO_ROOT / "backend" / "app" / "lesson" / "providers" / "anthropic.py"

    if not file_path.exists():
        return [f"❌ File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # Check for Claude 4.5 Sonnet
    if "claude-sonnet-4-5-20250929" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing Claude 4.5 Sonnet model. Should include claude-sonnet-4-5-20250929"
        )

    # Check for Claude 4.1 Opus
    if "claude-opus-4-1-20250805" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing Claude 4.1 Opus model. Should include claude-opus-4-1-20250805"
        )

    return errors


def validate_google_lesson_provider() -> List[str]:
    """Validate backend/app/lesson/providers/google.py uses October 2025 models."""
    errors = []
    file_path = REPO_ROOT / "backend" / "app" / "lesson" / "providers" / "google.py"

    if not file_path.exists():
        return [f"❌ File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # Check for Gemini 2.5 models
    if "gemini-2.5-" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing Gemini 2.5 models. "
            "Should include gemini-2.5-pro, gemini-2.5-flash, gemini-2.5-flash-lite"
        )

    # Check for Gemini 2.5 Flash specifically
    if "gemini-2.5-flash" not in content:
        errors.append(f"❌ {file_path.name}: Missing Gemini 2.5 Flash model")

    # Check for Gemini 2.5 Pro
    if "gemini-2.5-pro" not in content:
        errors.append(f"❌ {file_path.name}: Missing Gemini 2.5 Pro model")

    return errors


def validate_tts_config() -> List[str]:
    """Validate backend/app/core/config.py has correct TTS model."""
    errors = []
    file_path = REPO_ROOT / "backend" / "app" / "core" / "config.py"

    if not file_path.exists():
        return [f"❌ File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # Check TTS_DEFAULT_MODEL is tts-1
    if "TTS_DEFAULT_MODEL" in content:
        if 'default="tts-1"' not in content and "default='tts-1'" not in content:
            errors.append(
                f"❌ {file_path.name}: TTS_DEFAULT_MODEL should be 'tts-1' or 'tts-1-hd'. "
                "DO NOT use gpt-4o-mini-tts (does not exist)"
            )

    # Explicitly check for the fake model that doesn't exist
    if "gpt-4o-mini-tts" in content:
        errors.append(
            f"❌ {file_path.name}: Found 'gpt-4o-mini-tts' which DOES NOT EXIST. Use tts-1 or tts-1-hd only"
        )

    return errors


def validate_openai_chat_provider() -> List[str]:
    """Validate backend/app/chat/openai_provider.py uses October 2025 Responses API."""
    errors = []
    file_path = REPO_ROOT / "backend" / "app" / "chat" / "openai_provider.py"

    if not file_path.exists():
        return [f"❌ File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # Check for GPT-5 model names
    if '"gpt-5-' not in content and "'gpt-5-" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing GPT-5 models. "
            "Should include gpt-5-nano-2025-08-07, gpt-5-mini-2025-08-07, etc."
        )

    # Check for max_output_tokens (GPT-5 Responses API)
    if "max_output_tokens" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing 'max_output_tokens'. "
            "GPT-5 Responses API requires max_output_tokens (not max_tokens)"
        )

    # Check for text.format (GPT-5 Responses API)
    if '"text"' not in content or '"format"' not in content:
        errors.append(
            f"❌ {file_path.name}: Missing 'text' and 'format' keys. "
            "GPT-5 Responses API uses text.format (not response_format)"
        )

    # Check for /v1/responses endpoint
    if "/v1/responses" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing '/v1/responses' endpoint. "
            "GPT-5 uses /v1/responses (not /v1/chat/completions)"
        )

    # Check for reasoning parameter (GPT-5 only)
    if '"reasoning"' not in content and "'reasoning'" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing 'reasoning' parameter. "
            "GPT-5 Responses API includes reasoning.effort parameter"
        )

    return errors


def validate_anthropic_chat_provider() -> List[str]:
    """Validate backend/app/chat/anthropic_provider.py uses October 2025 models."""
    errors = []
    file_path = REPO_ROOT / "backend" / "app" / "chat" / "anthropic_provider.py"

    if not file_path.exists():
        return [f"❌ File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # Check for Claude 4.5 Sonnet
    if "claude-sonnet-4-5-20250929" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing Claude 4.5 Sonnet model. Should include claude-sonnet-4-5-20250929"
        )

    return errors


def validate_google_chat_provider() -> List[str]:
    """Validate backend/app/chat/google_provider.py uses October 2025 models."""
    errors = []
    file_path = REPO_ROOT / "backend" / "app" / "chat" / "google_provider.py"

    if not file_path.exists():
        return [f"❌ File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # Check for Gemini 2.5 Flash
    if "gemini-2.5-flash" not in content:
        errors.append(f"❌ {file_path.name}: Missing Gemini 2.5 Flash model. Should include gemini-2.5-flash")

    # Check for Gemini 2.5 models (broader check)
    if "gemini-2.5-" not in content:
        errors.append(f"❌ {file_path.name}: Missing Gemini 2.5 models")

    return errors


def validate_config_models() -> List[str]:
    """Validate backend/app/core/config.py has October 2025 model defaults."""
    errors = []
    file_path = REPO_ROOT / "backend" / "app" / "core" / "config.py"

    if not file_path.exists():
        return [f"❌ File not found: {file_path}"]

    content = file_path.read_text(encoding="utf-8")

    # Check for GPT-5 dated models
    if "gpt-5-" not in content:
        errors.append(
            f"❌ {file_path.name}: Missing GPT-5 models in config. "
            "Should use gpt-5-nano-2025-08-07, gpt-5-mini-2025-08-07, etc."
        )

    # Check for Claude 4.5 Sonnet
    if "claude-sonnet-4-5-20250929" not in content:
        errors.append(f"❌ {file_path.name}: Missing Claude 4.5 Sonnet in config")

    # Check for Gemini 2.5
    if "gemini-2.5-flash" not in content:
        errors.append(f"❌ {file_path.name}: Missing Gemini 2.5 Flash in config")

    return errors


def main() -> int:
    """Run all validations and return exit code."""
    print("=" * 80)
    print("[VALIDATION] October 2025 API Implementations Check")
    print("=" * 80)
    print()

    all_errors: List[Tuple[str, List[str]]] = []

    # Run all validations
    validations = [
        ("OpenAI Lesson Provider (GPT-5 Responses API)", validate_openai_lesson_provider),
        ("Anthropic Lesson Provider (Claude 4.5/4.1)", validate_anthropic_lesson_provider),
        ("Google Lesson Provider (Gemini 2.5)", validate_google_lesson_provider),
        ("OpenAI Chat Provider (GPT-5 Responses API)", validate_openai_chat_provider),
        ("Anthropic Chat Provider (Claude 4.5 Sonnet)", validate_anthropic_chat_provider),
        ("Google Chat Provider (Gemini 2.5 Flash)", validate_google_chat_provider),
        ("TTS Configuration", validate_tts_config),
        ("Model Configuration", validate_config_models),
    ]

    for name, validator in validations:
        print(f"Checking: {name}...", end=" ")
        errors = validator()
        if errors:
            print("[FAIL]")
            all_errors.append((name, errors))
        else:
            print("[PASS]")

    print()
    print("=" * 80)

    if all_errors:
        print("[FAIL] VALIDATION FAILED - October 2025 APIs have been regressed!")
        print("=" * 80)
        print()
        for name, errors in all_errors:
            print(f"[FAIL] {name}:")
            for error in errors:
                print(f"   {error}")
            print()
        print("=" * 80)
        print()
        print("[WARNING] CRITICAL: These files contain October 2025 API implementations.")
        print("[WARNING] AI agents with outdated training data may incorrectly 'fix' them.")
        print()
        print("Before committing these changes:")
        print("1. Read docs/AI_AGENT_GUIDELINES.md")
        print("2. Verify changes are correct with: python scripts/validate_api_versions.py")
        print("3. Ask yourself: Do I have October 2025 or later API knowledge?")
        print()
        return 1
    else:
        print("[PASS] ALL VALIDATIONS PASSED")
        print("=" * 80)
        print()
        print("[OK] October 2025 API implementations are intact:")
        print("   - Lesson providers: GPT-5, Claude 4.5/4.1, Gemini 2.5")
        print("   - Chat providers: GPT-5, Claude 4.5 Sonnet, Gemini 2.5 Flash")
        print("   - GPT-5 uses Responses API with max_output_tokens, text.format")
        print("   - All provider model names are correctly configured")
        print("   - TTS models are correct (tts-1, not fake models)")
        print()
        return 0


if __name__ == "__main__":
    sys.exit(main())
