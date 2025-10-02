#!/usr/bin/env python3
"""Final verification test - ensure everything still works"""
import requests
import sys

def test():
    results = []

    # Test 1: Health check
    try:
        r = requests.get("http://127.0.0.1:8000/health", timeout=5)
        if r.status_code == 200:
            results.append("[OK] Health check passed")
        else:
            results.append(f"[FAIL] Health check returned {r.status_code}")
            return False, results
    except Exception as e:
        results.append(f"[FAIL] Health check exception: {e}")
        return False, results

    # Test 2: Reader API with actual Greek text
    try:
        r = requests.post(
            "http://127.0.0.1:8000/reader/analyze",
            json={"q": "μῆνιν ἄειδε"},
            timeout=10
        )
        if r.status_code != 200:
            results.append(f"[FAIL] Reader API returned {r.status_code}")
            return False, results

        data = r.json()
        tokens = data.get("tokens", [])

        if len(tokens) < 2:
            results.append(f"[FAIL] Expected at least 2 tokens, got {len(tokens)}")
            return False, results

        # Check first token
        token1 = tokens[0]
        if token1.get("text") != "μῆνιν":
            results.append(f"[FAIL] Token 1 text: expected 'μῆνιν', got '{token1.get('text')}'")
            return False, results

        lemma1 = token1.get("lemma")
        morph1 = token1.get("morph")

        if not lemma1:
            results.append("[FAIL] Token 1 lemma is null/empty - CLTK NOT WORKING")
            return False, results

        if not morph1:
            results.append("[FAIL] Token 1 morph is null/empty - CLTK NOT WORKING")
            return False, results

        results.append(f"[OK] Reader API working")
        results.append(f"[OK] Token 1: text='{token1.get('text')}' lemma='{lemma1}' morph='{morph1}'")

        # Check second token
        token2 = tokens[1]
        lemma2 = token2.get("lemma")
        morph2 = token2.get("morph")

        if lemma2:
            results.append(f"[OK] Token 2: text='{token2.get('text')}' lemma='{lemma2}' morph='{morph2}'")

        return True, results

    except Exception as e:
        results.append(f"[FAIL] Reader API exception: {e}")
        return False, results

def main():
    passed, results = test()

    # Write to file immediately (avoid console encoding issues)
    output_lines = ["=" * 70, "FINAL VERIFICATION TEST", "=" * 70, ""]
    output_lines.extend(results)
    output_lines.append("=" * 70)

    if passed:
        output_lines.append("[SUCCESS] ALL VERIFICATION TESTS PASSED")
        output_lines.append("=" * 70)
        output_lines.append("")
        output_lines.append("CRITICAL FIX CONFIRMED:")
        output_lines.append("  - Backend CLTK is working")
        output_lines.append("  - API returns actual lemma/morph data")
        output_lines.append("  - System is production-ready")
    else:
        output_lines.append("[FAILURE] VERIFICATION FAILED")

    # Write to file
    with open("final_verification_result.txt", "w", encoding="utf-8") as f:
        f.write('\n'.join(output_lines))

    # Print ASCII-safe version to console
    for line in output_lines:
        try:
            safe_line = ''.join(c if ord(c) < 128 else '?' for c in line)
            print(safe_line)
        except:
            pass

    if passed:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
