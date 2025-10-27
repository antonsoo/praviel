"""Verify migration chain integrity."""

import re
from pathlib import Path

migrations_dir = Path(__file__).parent.parent / "backend" / "migrations" / "versions"

# Collect all revision IDs
revisions = {}
for migration_file in migrations_dir.glob("*.py"):
    content = migration_file.read_text(encoding="utf-8")

    # Extract revision ID
    rev_match = re.search(r'^revision[:\s]*=\s*["\']([^"\']+)["\']', content, re.MULTILINE)
    if rev_match:
        rev_id = rev_match.group(1)
        revisions[rev_id] = migration_file.name

# Check all down_revisions
issues = []
for migration_file in migrations_dir.glob("*.py"):
    content = migration_file.read_text(encoding="utf-8")

    # Extract down_revision
    down_rev_match = re.search(r"^down_revision[:\s]*=\s*(.+?)$", content, re.MULTILINE)
    if down_rev_match:
        down_rev_str = down_rev_match.group(1).strip()

        # Skip None
        if down_rev_str in ("None", "None,"):
            continue

        # Extract all revision IDs from the down_revision line
        # Handles both single strings and tuples
        rev_ids = re.findall(r'["\']([a-f0-9_]+)["\']', down_rev_str)

        for rev_id in rev_ids:
            if rev_id not in revisions:
                issues.append(
                    f"MISSING: {migration_file.name} references down_revision '{rev_id}' which doesn't exist"
                )

if issues:
    print("Migration chain issues found:")
    for issue in issues:
        print(f"  - {issue}")
    exit(1)
else:
    print(f"All migrations verified successfully! ({len(revisions)} revisions checked)")
    print("\nMigration chain appears healthy:")
    print(f"  - {len(revisions)} total migrations")
    print("  - All down_revision references are valid")
    exit(0)
