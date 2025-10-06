#!/usr/bin/env python3
"""Test that the validation script actually catches API regressions.

This creates temporary "regressed" versions of provider files and verifies
that validate_october_2025_apis.py fails as expected.
"""

import shutil
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent


def test_regression_detection():
    """Test that validation script catches common regression patterns."""

    print("=" * 80)
    print("[TEST] Validation Protection System Test")
    print("=" * 80)
    print()

    # Backup original file
    original_file = REPO_ROOT / "backend" / "app" / "lesson" / "providers" / "openai.py"
    backup_file = original_file.with_suffix(".py.test_backup")

    print(f"1. Backing up {original_file.name}...")
    shutil.copy(original_file, backup_file)

    # Read original content
    content = original_file.read_text(encoding="utf-8")

    # Test 1: Change max_output_tokens to max_tokens (common regression)
    print("2. Testing regression: max_output_tokens -> max_tokens...")
    regressed_content = content.replace("max_output_tokens", "max_tokens")
    original_file.write_text(regressed_content, encoding="utf-8")

    # Run validation - should FAIL
    result = subprocess.run(
        [sys.executable, "scripts/validate_october_2025_apis.py"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        print("   [FAIL] Validation passed when it should have failed!")
        print("   ERROR: Validation script does NOT catch max_output_tokens regression")
        shutil.copy(backup_file, original_file)
        backup_file.unlink()
        return False
    else:
        print("   [PASS] Validation correctly failed (exit code 1)")
        if "max_output_tokens" in result.stdout:
            print("   [PASS] Error message mentions 'max_output_tokens'")

    # Restore original
    shutil.copy(backup_file, original_file)

    # Test 2: Change text.format to response_format (common regression)
    print("3. Testing regression: text.format -> response_format...")
    regressed_content = content.replace('"text"', '"response_format"')
    original_file.write_text(regressed_content, encoding="utf-8")

    result = subprocess.run(
        [sys.executable, "scripts/validate_october_2025_apis.py"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        print("   [FAIL] Validation passed when it should have failed!")
        print("   ERROR: Validation script does NOT catch text.format regression")
        shutil.copy(backup_file, original_file)
        backup_file.unlink()
        return False
    else:
        print("   [PASS] Validation correctly failed (exit code 1)")

    # Restore original
    shutil.copy(backup_file, original_file)

    # Test 3: Change /v1/responses to /v1/chat/completions (common regression)
    print("4. Testing regression: /v1/responses -> /v1/chat/completions...")
    regressed_content = content.replace("/v1/responses", "/v1/chat/completions")
    original_file.write_text(regressed_content, encoding="utf-8")

    result = subprocess.run(
        [sys.executable, "scripts/validate_october_2025_apis.py"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )

    if result.returncode == 0:
        print("   [FAIL] Validation passed when it should have failed!")
        print("   ERROR: Validation script does NOT catch endpoint regression")
        shutil.copy(backup_file, original_file)
        backup_file.unlink()
        return False
    else:
        print("   [PASS] Validation correctly failed (exit code 1)")

    # Restore original and cleanup
    print("5. Restoring original file...")
    shutil.copy(backup_file, original_file)
    backup_file.unlink()

    # Final verification - should pass now
    print("6. Final verification (should pass)...")
    result = subprocess.run(
        [sys.executable, "scripts/validate_october_2025_apis.py"],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        print("   [FAIL] Validation failed after restore!")
        print("   ERROR: File may not have been restored correctly")
        return False
    else:
        print("   [PASS] Validation passes after restore")

    print()
    print("=" * 80)
    print("[PASS] Validation Protection System Works!")
    print("=" * 80)
    print()
    print("[OK] The validation script successfully catches:")
    print("   - max_output_tokens -> max_tokens regressions")
    print("   - text.format -> response_format regressions")
    print("   - /v1/responses -> /v1/chat/completions regressions")
    print()
    print("[OK] Protection system is functioning correctly.")
    return True


if __name__ == "__main__":
    success = test_regression_detection()
    sys.exit(0 if success else 1)
