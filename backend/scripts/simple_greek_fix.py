"""Simple script to remove Greek accents without external dependencies."""

import re
import unicodedata


def remove_accents(text):
    """Remove all diacritical marks from Greek text."""
    # Greek monotonic uppercase letters that don't decompose with NFD
    replacements = {
        "\u0386": "\u0391",  # Ά → Α
        "\u0388": "\u0395",  # Έ → Ε
        "\u0389": "\u0397",  # Ή → Η
        "\u038a": "\u0399",  # Ί → Ι
        "\u038c": "\u039f",  # Ό → Ο
        "\u038e": "\u03a5",  # Ύ → Υ
        "\u038f": "\u03a9",  # Ώ → Ω
        "\u03aa": "\u0399",  # Ϊ → Ι
        "\u03ab": "\u03a5",  # Ϋ → Υ
    }

    result = text
    for accented, unaccented in replacements.items():
        result = result.replace(accented, unaccented)

    # Normalize to NFD (decomposed form)
    nfd = unicodedata.normalize("NFD", result)

    # Remove combining characters
    without_accents = "".join(char for char in nfd if unicodedata.category(char) != "Mn")

    # Normalize back to NFC
    return unicodedata.normalize("NFC", without_accents).upper()


def main():
    """Fix daily_grc.yaml."""
    import io
    import sys

    # Fix encoding for Windows console
    if sys.stdout.encoding != "utf-8":
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

    file_path = r"C:\Dev\AI_Projects\AncientLanguagesAppDirs\Current-working-dirs\AncientLanguages\backend\app\lesson\seed\daily_grc.yaml"

    print(f"Reading {file_path}...")

    with open(file_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    print("Processing...")
    changed = 0

    new_lines = []
    for line in lines:
        # Match lines with "text: " followed by Greek text
        match = re.match(r"^(\s*- text: )(.+)$", line)
        if match:
            prefix = match.group(1)
            original_text = match.group(2).strip()
            cleaned_text = remove_accents(original_text)

            if original_text != cleaned_text:
                print(f"  {original_text} → {cleaned_text}")
                changed += 1

            new_lines.append(f"{prefix}{cleaned_text}\n")
        else:
            new_lines.append(line)

    print("\nWriting cleaned file...")
    with open(file_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    print(f"✓ Fixed {changed} entries")


if __name__ == "__main__":
    main()
