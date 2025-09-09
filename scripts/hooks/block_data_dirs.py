#!/usr/bin/env python3
import os
import subprocess
import sys

ALLOWED = {"README", "README.md", ".gitkeep"}
BLOCKED_PREFIXES = ("data/vendor/", "data/derived/")

ERROR_HDR = "ERROR: The following files are under data/vendor or data/derived and must not be committed:\n"
GUIDANCE = (
    "\nUse the fetch scripts; keep vendor/derived data out of Git. "
    "If you need tiny fixtures, add them under tests/.\n"
)


def main():
    out = subprocess.check_output(["git", "diff", "--cached", "--name-only"], text=True)
    bad = []
    for path in out.splitlines():
        if any(path.startswith(p) for p in BLOCKED_PREFIXES):
            base = os.path.basename(path)
            if base not in ALLOWED:
                bad.append(path)
    if bad:
        sys.stderr.write(ERROR_HDR + "\n".join(f"  - {p}" for p in bad) + GUIDANCE)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
