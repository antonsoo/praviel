#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Complete verification script for all bug fixes
Runs model verification + integration tests + Flutter check
"""
import subprocess
import sys
import io

if sys.platform == "win32":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def run_command(cmd, description):
    """Run a command and return success/failure"""
    print(f"\n{'='*70}")
    print(f"Running: {description}")
    print(f"{'='*70}")
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            capture_output=True,
            text=True,
            timeout=180
        )
        print(result.stdout)
        if result.stderr and "UserWarning" not in result.stderr:
            print(f"STDERR: {result.stderr}")
        return result.returncode == 0
    except Exception as e:
        print(f"[ERROR] {e}")
        return False

def main():
    print("="*70)
    print("COMPREHENSIVE VERIFICATION - All Bug Fixes")
    print("="*70)

    tests = []

    # Test 1: Model name verification
    success = run_command("py test_byok_fix.py", "Model Name Verification")
    tests.append(("Model Names (OpenAI + Anthropic)", success))

    # Test 2: Integration tests (requires backend running)
    print("\n" + "="*70)
    print("Note: Integration tests require backend running on port 8000")
    print("If backend not running, this test will fail (expected)")
    print("="*70)
    success = run_command("py integration_test.py", "Integration Test Suite (6 tests)")
    tests.append(("Integration Tests (Backend APIs)", success))

    # Test 3: Flutter analyzer
    success = run_command(
        "cd client/flutter_reader && flutter analyze",
        "Flutter Analyzer (Frontend)"
    )
    tests.append(("Flutter Analyzer", success))

    # Summary
    print("\n" + "="*70)
    print("VERIFICATION SUMMARY")
    print("="*70)

    passed = 0
    failed = 0
    for name, success in tests:
        status = "[PASS]" if success else "[FAIL]"
        print(f"{status} {name}")
        if success:
            passed += 1
        else:
            failed += 1

    print("="*70)
    print(f"Total: {passed}/{len(tests)} tests passed")

    if failed == 0:
        print("\n✅ ALL VERIFICATIONS PASSED!")
        print("\nBug Fixes Verified:")
        print("  ✅ BYOK model names updated to October 2025")
        print("  ✅ Chat duplication fix working")
        print("  ✅ Reader API functional")
        print("  ✅ Flutter frontend clean")
        print("\nReady for production!")
        return 0
    else:
        print(f"\n⚠️  {failed} verification(s) failed")
        print("\nNote: If integration tests failed, ensure backend is running:")
        print("  py -m uvicorn app.main:app --reload --port 8000")
        return 1

if __name__ == "__main__":
    sys.exit(main())
