#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import PurePosixPath

# Directories that must never be committed (except allowlisted basenames)
BLOCKED_PREFIXES = ("data/vendor/", "data/derived/")
# File basenames that are allowed inside those dirs
ALLOW_BASENAMES = {"README", "README.md", ".gitkeep"}
# Set to bypass once: ALLOW_DATA_COMMITS=1 git commit ...
ENV_BYPASS = "ALLOW_DATA_COMMITS"


def _staged_paths() -> list[str]:
    """
    Return the list of staged file paths (A/C/M/R) as POSIX-like strings so
    prefix checks behave consistently on Windows.
    """
    try:
        out = subprocess.check_output(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=ACMR"],
            text=True,
            errors="replace",
        )
    except subprocess.CalledProcessError as e:
        print(f"[block_data_dirs] failed to list staged files: {e}", file=sys.stderr)
        return []
    paths = []
    for line in out.splitlines():
        p = line.strip()
        if not p:
            continue
        # normalize to forward slashes for prefix checks
        p = PurePosixPath(p.replace("\\", "/")).as_posix()
        paths.append(p)
    return paths


def main() -> int:
    if os.environ.get(ENV_BYPASS):
        return 0

    bad: list[str] = []
    for path in _staged_paths():
        base = os.path.basename(path)
        if base in ALLOW_BASENAMES:
            continue
        if any(path.startswith(prefix) for prefix in BLOCKED_PREFIXES):
            bad.append(path)

    if not bad:
        return 0

    msg = [
        "ERROR: The following staged paths live under data/vendor or data/derived and must not be committed:",
        *[f"  - {p}" for p in bad],
        "",
        "Keep vendor/derived data out of Git. Use fetch/derive scripts instead.",
        "For tiny fixtures, prefer tests/fixtures/.",
        f"Temporary override (single commit): set {ENV_BYPASS}=1 before committing.",
    ]
    sys.stderr.write("\n".join(msg) + "\n")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
