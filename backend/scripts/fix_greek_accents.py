"""Fix accent inconsistencies in Classical Greek vocabulary files.

This script removes all accents, breathings, and diacriticals from Classical Greek
vocabulary to match the language configuration (has_accents=False).
"""

import sys
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

import yaml

from app.lesson.script_utils import _remove_accents


def fix_greek_yaml(file_path: Path) -> None:
    """Remove accents from all text entries in a Greek vocabulary YAML file.

    Args:
        file_path: Path to the YAML file to fix
    """
    print(f"Processing {file_path.name}...")

    # Read the YAML file
    with open(file_path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)

    # Get the root key (e.g., 'daily_grc', 'canonical_grc')
    root_key = list(data.keys())[0]
    entries = data[root_key]

    # Track changes
    changed_count = 0

    # Process each entry
    for entry in entries:
        if "text" in entry:
            original = entry["text"]
            cleaned = _remove_accents(original).upper()  # Also ensure uppercase

            if original != cleaned:
                entry["text"] = cleaned
                changed_count += 1
                print(f"  {original} → {cleaned}")

    # Write back the cleaned YAML
    with open(file_path, "w", encoding="utf-8") as f:
        yaml.dump(data, f, allow_unicode=True, sort_keys=False, width=1000)

    print(f"✓ Fixed {changed_count} entries in {file_path.name}\n")


def main():
    """Fix accent issues in all Classical Greek vocabulary files."""
    seed_dir = Path(__file__).parent.parent / "app" / "lesson" / "seed"

    # Files that need fixing (Classical Greek with has_accents=False)
    greek_files = [
        seed_dir / "daily_grc.yaml",
        seed_dir / "canonical_grc.yaml",
    ]

    # Also check colloquial_grc.yaml exists (this one SHOULD have accents as alternative form)
    colloquial_file = seed_dir / "colloquial_grc.yaml"

    for file_path in greek_files:
        if file_path.exists():
            fix_greek_yaml(file_path)
        else:
            print(f"⚠ File not found: {file_path}")

    if colloquial_file.exists():
        print(f"Note: {colloquial_file.name} was NOT modified (it uses accented lowercase as an alternative modern editorial form)")

    print("✓ All Classical Greek vocabulary files have been updated to remove accents.")
    print("  This matches the language configuration: has_accents=False (epigraphic form)")


if __name__ == "__main__":
    main()
