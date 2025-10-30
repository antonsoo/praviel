#!/usr/bin/env python3
"""
Validate that OpenAI API calls use correct Responses API payload structure.

This script checks for incorrect parameters that would cause 400 errors:
  - BANNED: response_format, max_tokens, messages (Chat Completions API)
  - REQUIRED: input, max_output_tokens (Responses API)
  - OPTIONAL BUT UNSUPPORTED BY gpt-5-nano: modalities, reasoning, store

Exit codes:
  0 - All validations passed
  1 - Invalid API structure detected (commit blocked)
"""

import re
import sys
from pathlib import Path

# Files that make OpenAI API calls
OPENAI_PROVIDER_FILES = [
    "backend/app/chat/openai_provider.py",
    "backend/app/lesson/providers/openai.py",
    "backend/app/coach/providers.py",
    "backend/app/api/health_providers.py",
]

# Parameters that indicate Chat Completions API (old, wrong)
BANNED_CHAT_COMPLETIONS_PARAMS = {
    "response_format": "Use text.format instead (Responses API)",
    "max_tokens": "Use max_output_tokens instead (Responses API)",
    '"messages"': "Use 'input' instead (Responses API - note: searching for quoted 'messages')",
}

# Parameters that break gpt-5-nano even though they're valid for other models
UNSUPPORTED_BY_NANO = {
    "modalities": "Not supported by gpt-5-nano",
    "reasoning": "Not supported by gpt-5-nano",
    "store": "Not supported by gpt-5-nano",
    "text.verbosity": "Not supported by gpt-5-nano",
}

# Correct endpoint
RESPONSES_API_ENDPOINT = "https://api.openai.com/v1/responses"
CHAT_COMPLETIONS_ENDPOINT = "https://api.openai.com/v1/chat/completions"


def check_file_for_api_issues(file_path: Path) -> list[tuple[int, str, str]]:
    """
    Check file for incorrect API usage.

    Returns list of (line_number, error_message, line_content) tuples.
    """
    violations = []

    if not file_path.exists():
        return violations

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    in_payload_dict = False

    for line_num, line in enumerate(lines, start=1):
        line_stripped = line.strip()
        line_lower = line.lower()

        # Skip comments
        if line_stripped.startswith("#"):
            continue

        # Check for wrong endpoint
        if CHAT_COMPLETIONS_ENDPOINT in line:
            violations.append(
                (
                    line_num,
                    "WRONG ENDPOINT: Using Chat Completions API instead of Responses API",
                    line.rstrip(),
                )
            )

        # Track when we're inside a payload dict (JSON being sent to API)
        if re.search(r"payload\s*[=:]\s*\{", line_lower):
            in_payload_dict = True
        elif in_payload_dict and line_stripped.startswith("}"):
            in_payload_dict = False

        # Check for banned parameters in payload
        if in_payload_dict:
            for banned_param, reason in BANNED_CHAT_COMPLETIONS_PARAMS.items():
                # Look for parameter in dict (handle both "key": value and 'key': value)
                param_clean = banned_param.strip("\"'")
                if re.search(rf'["\']?{re.escape(param_clean)}["\']?\s*:', line_lower):
                    violations.append(
                        (line_num, f"BANNED PARAMETER '{banned_param}': {reason}", line.rstrip())
                    )

            for unsupported_param, reason in UNSUPPORTED_BY_NANO.items():
                if re.search(rf'["\']?{re.escape(unsupported_param)}["\']?\s*:', line_lower):
                    violations.append(
                        (line_num, f"UNSUPPORTED PARAMETER '{unsupported_param}': {reason}", line.rstrip())
                    )

    return violations


def main():
    """Run validation checks."""
    repo_root = Path(__file__).parent.parent

    print("[*] Checking OpenAI API payload structure...")
    print()

    total_violations = 0

    for file_path_str in OPENAI_PROVIDER_FILES:
        file_path = repo_root / file_path_str
        violations = check_file_for_api_issues(file_path)

        if violations:
            print(f"[X] {file_path.name}")
            print(f"   Path: {file_path}")
            print()
            for line_num, error_msg, line_content in violations:
                print(f"   Line {line_num}: {error_msg}")
                print(f"   > {line_content}")
                print()
            total_violations += len(violations)
        else:
            print(f"[OK] {file_path.name}")

    print()
    if total_violations > 0:
        print("=" * 80)
        print(f"[X] VALIDATION FAILED: {total_violations} API issue(s) detected")
        print("=" * 80)
        print()
        print("CORRECT MINIMAL PAYLOAD for GPT-5 Responses API:")
        print("  {")
        print('    "model": "gpt-5-nano-2025-08-07",')
        print('    "input": [{"role": "user", "content": [{"type": "input_text", "text": "..."}]}],')
        print('    "max_output_tokens": 2048')
        print("  }")
        print()
        print("ENDPOINT: https://api.openai.com/v1/responses")
        print()
        print("Read CLAUDE.md and docs/AI_AGENT_GUIDELINES.md before making changes.")
        print("=" * 80)
        return 1

    print("[OK] All OpenAI API payloads use correct structure")
    return 0


if __name__ == "__main__":
    sys.exit(main())
