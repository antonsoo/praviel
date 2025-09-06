#!/usr/bin/env python3
import re
import subprocess
import sys

# Detect "sk-..." tokens and api_key k[:=]v pairs
SK = re.compile(r"\bsk-[A-Za-z0-9]{10,}\b")
KVS = re.compile(r"(?i)\b\w*api_key\b\s*[:=]\s*['\"]?([A-Za-z0-9_\-]{12,})")


def main():
    diff = subprocess.check_output(
        ["git", "diff", "--cached", "-U0", "--no-color", "--diff-filter=AM"],
        text=True,
        errors="replace",
    )
    leaks = []
    current = None
    for line in diff.splitlines():
        if line.startswith("+++ b/"):
            current = line[6:]
            continue
        if not line.startswith("+") or line.startswith("+++"):
            continue
        if current and ("tests/" in current or "/tests/" in current):
            # allow secrets in tests to validate masking
            continue
        s = line[1:]
        if SK.search(s):
            leaks.append((current, s.strip()))
            continue
        m = KVS.search(s)
        if m and m.group(1) != "***":
            leaks.append((current, s.strip()))
    if leaks:
        sys.stderr.write("ERROR: Possible API keys detected in staged changes:\n")
        for fn, entry in leaks[:20]:
            sys.stderr.write(f"  {fn}: + {entry}\n")
        sys.stderr.write("\nMask keys or move them to env vars before committing.\n")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
