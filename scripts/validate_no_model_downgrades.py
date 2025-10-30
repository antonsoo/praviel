#!/usr/bin/env python3
"""
Validation script to prevent AI agents from downgrading models.

This script checks for banned model patterns in critical files.
Run this in pre-commit hooks to catch downgrades before they're committed.

Exit codes:
  0 - All validations passed
  1 - Model downgrade detected (commit blocked)
"""

import re
import sys
from pathlib import Path

# Banned patterns that indicate model downgrades
BANNED_PATTERNS = {
    "gpt-4": "GPT-4 models (use GPT-5 instead)",
    "gpt-3": "GPT-3 models (use GPT-5 instead)",
    "claude-3": "Claude 3 models (use Claude 4.x instead)",
    "claude-2": "Claude 2 models (use Claude 4.x instead)",
    "gemini-1": "Gemini 1.x models (use Gemini 2.5 instead)",
}

# Files to check
FILES_TO_CHECK = [
    "backend/app/core/config.py",
    "backend/app/lesson/providers/openai.py",
    "backend/app/chat/openai_provider.py",
    "client/flutter_reader/lib/models/model_registry.dart",
]


def check_file(file_path: Path) -> list[tuple[int, str, str]]:
    """
    Check a file for banned model patterns.

    Returns list of (line_number, pattern, line_content) tuples for violations.
    """
    violations = []

    if not file_path.exists():
        return violations

    with open(file_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, start=1):
            line_lower = line.lower()
            line_stripped = line.strip()

            # Skip full-line comments
            if line_stripped.startswith("#") or line_stripped.startswith("//"):
                continue

            # Skip lines that are just defining validation rules (meta)
            if "banned" in line_lower and ("gpt-4" in line_lower or "gpt-3" in line_lower):
                continue

            # Skip lines that mention GPT-4 in comments about the API fallback
            if "#" in line and ("for gpt-4" in line_lower or "gpt-4 models" in line_lower):
                continue

            for pattern, description in BANNED_PATTERNS.items():
                if pattern in line_lower:
                    # Look for actual model name assignments (field values, default values)
                    # Pattern: `= "model-name"` or `default="model-name"` or `id: 'model-name'`
                    if re.search(rf'[=:]\s*["\'].*{re.escape(pattern)}.*["\']', line_lower) or re.search(
                        rf'Field\([^)]*default\s*=\s*["\'].*{re.escape(pattern)}.*["\']',
                        line_lower,
                    ):
                        violations.append((line_num, description, line.strip()))

    return violations


def main():
    """Run validation checks."""
    repo_root = Path(__file__).parent.parent

    print("[*] Checking for model downgrades...")
    print()

    total_violations = 0

    for file_path_str in FILES_TO_CHECK:
        file_path = repo_root / file_path_str
        violations = check_file(file_path)

        if violations:
            print(f"[X] {file_path.name}")
            print(f"   Path: {file_path}")
            print()
            for line_num, description, line_content in violations:
                print(f"   Line {line_num}: {description}")
                print(f"   > {line_content}")
                print()
            total_violations += len(violations)
        else:
            print(f"[OK] {file_path.name}")

    print()
    if total_violations > 0:
        print("=" * 80)
        print(f"[X] VALIDATION FAILED: {total_violations} model downgrade(s) detected")
        print("=" * 80)
        print()
        print("This codebase uses October 2025 APIs:")
        print("  - GPT-5 (not GPT-4 or GPT-3.5)")
        print("  - Claude 4.x (not Claude 3 or 2)")
        print("  - Gemini 2.5 (not Gemini 1.x)")
        print()
        print("Read CLAUDE.md and docs/AI_AGENT_GUIDELINES.md before making changes.")
        print("=" * 80)
        return 1

    print("[OK] All validation checks passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
