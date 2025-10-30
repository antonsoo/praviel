#!/usr/bin/env python3
import re
import subprocess
import sys

# Patterns kept intentionally focused to reduce false positives.
PATTERNS = [
    # OpenAI
    r"\bsk-[A-Za-z0-9]{10,}\b",
    # GitHub tokens
    r"\bghp_[A-Za-z0-9]{36}\b",
    r"\bgithub_pat_[A-Za-z0-9_]{82,}\b",
    # Hugging Face
    r"\bhf_[A-Za-z0-9]{30,}\b",
    # AWS access key id (AKIA...), naive check; secret keys are harder to match safely
    r"\bAKIA[0-9A-Z]{16}\b",
    # Generic api_key assignments like api_key: "xxx" or api_key = 'xxx'
    r"(?i)\b\w*api_key\b\s*[:=]\s*['\"][A-Za-z0-9_\-]{12,}['\"]",
]

ALLOW_IN = ("tests/", "/tests/")
RE_PATTERNS = [re.compile(p) for p in PATTERNS]


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
        if current and any(seg in current for seg in ALLOW_IN):
            continue
        s = line[1:]
        if any(p.search(s) for p in RE_PATTERNS):
            leaks.append((current, s.strip()))

    if leaks:
        sys.stderr.write("ERROR: Possible secrets detected in staged changes:\n")
        for fn, entry in leaks[:20]:
            sys.stderr.write(f"  {fn}: + {entry}\n")
        sys.stderr.write("\nMask keys or move them to env vars before committing.\n")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
