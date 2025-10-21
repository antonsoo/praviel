#!/usr/bin/env python3
"""Sync language display order from docs/LANGUAGE_LIST.md to all language-related files.

This script:
1. Parses docs/LANGUAGE_LIST.md to extract language ordering
2. Maps language names to codes
3. Updates display_order values in language_config.py
4. Reorders Flutter language.dart list
5. Reorders LANGUAGE_WRITING_RULES.md entries
6. Reorders TOP_TEN_WORKS_PER_LANGUAGE.md entries

Usage:
    python scripts/sync_language_order.py          # Sync the order
    python scripts/sync_language_order.py --check  # Validate only (for pre-commit)
"""

import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

# Path constants
REPO_ROOT = Path(__file__).parent.parent
LANGUAGE_LIST_MD = REPO_ROOT / "docs" / "LANGUAGE_LIST.md"
LANGUAGE_CONFIG_PY = REPO_ROOT / "backend" / "app" / "lesson" / "language_config.py"
FLUTTER_LANGUAGE_DART = REPO_ROOT / "client" / "flutter_reader" / "lib" / "models" / "language.dart"
LANGUAGE_WRITING_RULES_MD = REPO_ROOT / "docs" / "LANGUAGE_WRITING_RULES.md"
TOP_TEN_WORKS_MD = REPO_ROOT / "docs" / "TOP_TEN_WORKS_PER_LANGUAGE.md"


def parse_language_list_md() -> List[Tuple[int, str]]:
    """Parse LANGUAGE_LIST.md and return ordered list of (display_order, language_name).

    Returns:
        List of tuples: [(1, "Classical Greek"), (2, "Classical Latin"), ...]
    """
    if not LANGUAGE_LIST_MD.exists():
        raise FileNotFoundError(f"LANGUAGE_LIST.md not found at {LANGUAGE_LIST_MD}")

    content = LANGUAGE_LIST_MD.read_text(encoding="utf-8")
    languages = []
    display_order = 1

    # Pattern: "1. 🏺 **Classical Greek** — ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ"
    # We want to extract "Classical Greek"
    pattern = r"^\d+\.\s+\S+\s+\*\*(.+?)\*\*"

    for line in content.splitlines():
        line = line.strip()
        match = re.match(pattern, line)
        if match:
            language_name = match.group(1)
            # Normalize names to match language_config.py
            # "Yehudit (Paleo-Hebrew script)" -> "Yehudit (Paleo-Hebrew)"
            language_name = language_name.replace(" script)", ")")
            languages.append((display_order, language_name))
            display_order += 1

    if not languages:
        raise ValueError(f"No languages found in {LANGUAGE_LIST_MD}")

    return languages


def extract_language_code_mapping(config_py_content: str) -> Dict[str, str]:
    """Extract mapping from language name to code from language_config.py.

    Args:
        config_py_content: Content of language_config.py

    Returns:
        Dict mapping language name to code: {"Classical Greek": "grc", ...}
    """
    name_to_code = {}

    # Pattern to find language entries like:
    #   "grc": LanguageConfig(
    #       code="grc",
    #       name="Classical Greek",
    code_pattern = r'"([a-z\-]+)":\s+LanguageConfig\('
    name_pattern = r'name="([^"]+)"'

    # Find all code blocks
    for code_match in re.finditer(code_pattern, config_py_content):
        code = code_match.group(1)
        # Search for name within the next 500 characters
        start_pos = code_match.start()
        snippet = config_py_content[start_pos : start_pos + 500]
        name_match = re.search(name_pattern, snippet)
        if name_match:
            name = name_match.group(1)
            name_to_code[name] = code

    return name_to_code


def update_display_order_in_config(
    config_py_content: str, language_orders: List[Tuple[int, str]], name_to_code: Dict[str, str]
) -> str:
    """Update display_order values in language_config.py content.

    Args:
        config_py_content: Current content of language_config.py
        language_orders: List of (display_order, language_name) from LANGUAGE_LIST.md
        name_to_code: Mapping from language name to code

    Returns:
        Updated content with new display_order values
    """
    # Build order mapping: code -> display_order
    code_to_order = {}
    for order, name in language_orders:
        if name in name_to_code:
            code = name_to_code[name]
            code_to_order[code] = order
        else:
            print(
                f"WARNING: Language '{name}' from LANGUAGE_LIST.md not found in language_config.py",
                file=sys.stderr,
            )

    # Process line by line
    lines = config_py_content.splitlines(keepends=True)
    result_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]

        # Check if this is a language definition: "code": LanguageConfig(
        match = re.match(r'    "([a-z\-]+)":\s+LanguageConfig\(', line)
        if match:
            code = match.group(1)
            order = code_to_order.get(code, 9999)

            # Add the current line
            result_lines.append(line)
            i += 1

            # Now process the LanguageConfig block
            # We need to find if display_order exists, and add/update it
            paren_depth = 1  # We've seen the opening (
            block_lines = []
            display_order_line_idx = None

            while i < len(lines) and paren_depth > 0:
                current = lines[i]
                block_lines.append(current)

                # Track if this is the display_order line
                if re.match(r"\s+display_order=", current):
                    display_order_line_idx = len(block_lines) - 1

                # Count parens to find end of LanguageConfig(...)
                paren_depth += current.count("(") - current.count(")")
                i += 1

            # Now modify block_lines to update/add display_order
            if display_order_line_idx is not None:
                # Update existing display_order
                block_lines[display_order_line_idx] = re.sub(
                    r"display_order=\d+", f"display_order={order}", block_lines[display_order_line_idx]
                )
            else:
                # Add display_order before the closing )
                # Find the last line with just whitespace and )
                for j in range(len(block_lines) - 1, -1, -1):
                    if re.match(r"^\s+\),?\s*$", block_lines[j]):
                        # Insert display_order before this line
                        indent = "        "  # Match indentation of other fields
                        block_lines.insert(j, f"{indent}display_order={order},\n")
                        break

            result_lines.extend(block_lines)
        else:
            result_lines.append(line)
            i += 1

    return "".join(result_lines)


def reorder_flutter_languages(
    dart_content: str, language_orders: List[Tuple[int, str]], name_to_code: Dict[str, str]
) -> str:
    """Reorder language entries in Flutter language.dart file.

    Args:
        dart_content: Current content of language.dart
        language_orders: List of (display_order, language_name) from LANGUAGE_LIST.md
        name_to_code: Mapping from language name to code

    Returns:
        Updated content with reordered language entries
    """
    # Extract all LanguageInfo blocks
    # Pattern: find blocks starting with "  // N. Language Name" and ending before next comment or ];

    # Find the start and end of the availableLanguages const list
    start_marker = "const availableLanguages = ["
    end_marker = "];"

    start_idx = dart_content.find(start_marker)
    if start_idx == -1:
        raise ValueError("Could not find 'const availableLanguages = [' in Flutter file")

    # Find the closing ];
    end_idx = dart_content.find(end_marker, start_idx)
    if end_idx == -1:
        raise ValueError("Could not find closing '  ];' for availableLanguages")

    # Extract the list content
    list_start = start_idx + len(start_marker)
    list_content = dart_content[list_start:end_idx]

    # Parse language blocks
    # Each block starts with a comment like "  // 1. Classical Greek"
    # and contains a LanguageInfo( ... )  structure
    blocks = []

    lines = list_content.splitlines(keepends=True)
    in_block = False
    block_lines = []
    block_comment = ""

    for line in lines:
        # Skip section headers (we'll add them back later)
        if re.match(r"\s*// ==== (FULL|PARTIAL) COURSES", line):
            continue

        # Check if this is a comment line marking a new language
        comment_match = re.match(r"\s*// \d+\. (.+)", line)
        if comment_match:
            # Save previous block if exists
            if block_lines:
                # Extract code from the block
                code_match = re.search(r"code: '([a-z\-]+)'", "".join(block_lines))
                if code_match:
                    blocks.append(
                        {
                            "comment": block_comment,
                            "code": code_match.group(1),
                            "content": "".join(block_lines),
                        }
                    )
                block_lines = []

            # Start new block
            block_comment = line
            in_block = True
        elif in_block:
            block_lines.append(line)

    # Don't forget the last block
    if block_lines:
        code_match = re.search(r"code: '([a-z\-]+)'", "".join(block_lines))
        if code_match:
            blocks.append(
                {"comment": block_comment, "code": code_match.group(1), "content": "".join(block_lines)}
            )

    # Build code to order mapping
    code_to_order = {}
    for order, name in language_orders:
        if name in name_to_code:
            code = name_to_code[name]
            code_to_order[code] = order

    # Sort blocks by display order
    def get_order(block):
        return code_to_order.get(block["code"], 9999)

    blocks.sort(key=get_order)

    # Reconstruct the list
    new_list_lines = []

    # Add section headers
    new_list_lines.append("\n  // ==== FULL COURSES (1-36) ====\n")

    partial_course_start_idx = None

    for i, block in enumerate(blocks):
        # Check if this is the start of partial courses (order > 36)
        order = get_order(block)
        if order > 36 and partial_course_start_idx is None:
            partial_course_start_idx = i
            new_list_lines.append("\n  // ==== PARTIAL COURSES (37-46) ====\n")

        # Update comment number
        display_num = order
        lang_name_match = re.search(r"// \d+\. (.+)", block["comment"])
        if lang_name_match:
            lang_name = lang_name_match.group(1)
            block["comment"] = f"  // {display_num}. {lang_name}\n"

        new_list_lines.append(block["comment"])
        # Normalize the content: ensure exactly one blank line between blocks
        content = block["content"]
        # Remove any trailing whitespace/newlines and normalize
        content = content.rstrip()
        # Add back the newline
        # Add blank line after each block except:
        # - the last one
        # - before a section header (section header already has leading \n)
        if i < len(blocks) - 1:
            next_order = get_order(blocks[i + 1])
            # Check if next block starts a new section (crosses from <=36 to >36)
            next_is_section_boundary = order <= 36 and next_order > 36
            if next_is_section_boundary:
                # Section header already starts with \n, so just one newline here
                new_list_lines.append(content + "\n")
            else:
                new_list_lines.append(content + "\n\n")
        else:
            new_list_lines.append(content + "\n")

    # Rebuild the file
    new_list_content = "".join(new_list_lines)
    new_dart_content = dart_content[:list_start] + new_list_content + dart_content[end_idx:]

    return new_dart_content


def reorder_writing_rules_md(
    md_content: str, language_orders: List[Tuple[int, str]], name_to_code: Dict[str, str]
) -> str:
    """Reorder language entries in LANGUAGE_WRITING_RULES.md.

    Args:
        md_content: Current content of LANGUAGE_WRITING_RULES.md
        language_orders: List of (display_order, language_name) from LANGUAGE_LIST.md
        name_to_code: Mapping from language name to code

    Returns:
        Updated content with reordered language entries
    """
    # Build order mapping: name -> display_order
    name_to_order = {name: order for order, name in language_orders}

    # Parse entries: "1)🏺 Classical Greek — ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ: [text]"
    # Pattern matches: number)emoji **Name** — native: content
    entries = []
    lines = md_content.splitlines(keepends=True)

    i = 0
    while i < len(lines):
        line = lines[i]
        # Match format like "1)🏺 Classical Greek — ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ:"
        match = re.match(r"^\d+\)(\S+)\s+(.+?)\s+—\s+(.+?):\s*(.*)$", line)
        if match:
            emoji = match.group(1)
            lang_name = match.group(2)
            native = match.group(3)
            content = match.group(4)

            # Get order
            order = name_to_order.get(lang_name, 9999)

            entries.append(
                {
                    "order": order,
                    "emoji": emoji,
                    "name": lang_name,
                    "native": native,
                    "content": content,
                    "original_line": line,
                }
            )
        i += 1

    # Sort by order
    entries.sort(key=lambda x: x["order"])

    # Rebuild content
    new_lines = []
    full_idx = 1
    partial_idx = 1
    partial_started = False

    for entry in entries:
        order = entry["order"]

        # Add partial courses divider
        if order > 36 and not partial_started:
            new_lines.append("\n— Partial courses —\n\n")
            partial_started = True

        # Determine numbering
        if order > 36:
            idx = partial_idx
            partial_idx += 1
        else:
            idx = full_idx
            full_idx += 1

        # Rebuild line
        new_line = f"{idx}){entry['emoji']} {entry['name']} — {entry['native']}: {entry['content']}"
        new_lines.append(new_line)

    return "".join(new_lines)


def reorder_top_ten_works_md(
    md_content: str, language_orders: List[Tuple[int, str]], name_to_code: Dict[str, str]
) -> str:
    """Reorder language entries in TOP_TEN_WORKS_PER_LANGUAGE.md.

    Args:
        md_content: Current content of TOP_TEN_WORKS_PER_LANGUAGE.md
        language_orders: List of (display_order, language_name) from LANGUAGE_LIST.md
        name_to_code: Mapping from language name to code

    Returns:
        Updated content with reordered language entries
    """
    # Build order mapping: name -> display_order
    name_to_order = {name: order for order, name in language_orders}

    # Find the header and start of content
    header_end = md_content.find("## Full Courses\n")
    if header_end == -1:
        raise ValueError("Could not find '## Full Courses' header")

    header = md_content[: header_end + len("## Full Courses\n\n")]

    # Parse entries: "1) 🏺 **Classical Greek** — ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ: [works]"
    entries = []
    lines = md_content[header_end:].splitlines(keepends=True)

    for line in lines:
        # Match format like "1) 🏺 **Classical Greek** — ΕΛΛΗΝΙΚΗ ΓΛΩΤΤΑ: [works]"
        match = re.match(r"^\d+\)\s+(\S+)\s+\*\*(.+?)\*\*\s+—\s+(.+?):\s*(.*)$", line)
        if match:
            emoji = match.group(1)
            lang_name = match.group(2)
            native = match.group(3)
            works = match.group(4)

            # Get order
            order = name_to_order.get(lang_name, 9999)

            entries.append(
                {"order": order, "emoji": emoji, "name": lang_name, "native": native, "works": works}
            )

    # Sort by order
    entries.sort(key=lambda x: x["order"])

    # Rebuild content
    new_lines = [header]

    for i, entry in enumerate(entries, 1):
        new_line = f"{i}) {entry['emoji']} **{entry['name']}** — {entry['native']}: {entry['works']}\n"
        new_lines.append(new_line)

    return "".join(new_lines)


def validate_sync() -> bool:
    """Validate that language_config.py and language.dart are synced with LANGUAGE_LIST.md.

    Returns:
        True if synced, False if out of sync
    """
    # Parse LANGUAGE_LIST.md
    language_orders = parse_language_list_md()

    # Check backend config
    current_config = LANGUAGE_CONFIG_PY.read_text(encoding="utf-8")
    name_to_code = extract_language_code_mapping(current_config)
    updated_config = update_display_order_in_config(current_config, language_orders, name_to_code)

    backend_synced = current_config == updated_config
    if backend_synced:
        print("[OK] language_config.py is synced with LANGUAGE_LIST.md")
    else:
        print("[ERROR] language_config.py is OUT OF SYNC with LANGUAGE_LIST.md", file=sys.stderr)

    # Check Flutter file
    current_dart = FLUTTER_LANGUAGE_DART.read_text(encoding="utf-8")
    updated_dart = reorder_flutter_languages(current_dart, language_orders, name_to_code)

    flutter_synced = current_dart == updated_dart
    if flutter_synced:
        print("[OK] language.dart is synced with LANGUAGE_LIST.md")
    else:
        print("[ERROR] language.dart is OUT OF SYNC with LANGUAGE_LIST.md", file=sys.stderr)

    # Check LANGUAGE_WRITING_RULES.md
    current_writing_rules = LANGUAGE_WRITING_RULES_MD.read_text(encoding="utf-8")
    updated_writing_rules = reorder_writing_rules_md(current_writing_rules, language_orders, name_to_code)

    writing_rules_synced = current_writing_rules == updated_writing_rules
    if writing_rules_synced:
        print("[OK] LANGUAGE_WRITING_RULES.md is synced with LANGUAGE_LIST.md")
    else:
        print("[ERROR] LANGUAGE_WRITING_RULES.md is OUT OF SYNC with LANGUAGE_LIST.md", file=sys.stderr)

    # Check TOP_TEN_WORKS_PER_LANGUAGE.md
    current_top_ten = TOP_TEN_WORKS_MD.read_text(encoding="utf-8")
    updated_top_ten = reorder_top_ten_works_md(current_top_ten, language_orders, name_to_code)

    top_ten_synced = current_top_ten == updated_top_ten
    if top_ten_synced:
        print("[OK] TOP_TEN_WORKS_PER_LANGUAGE.md is synced with LANGUAGE_LIST.md")
    else:
        print("[ERROR] TOP_TEN_WORKS_PER_LANGUAGE.md is OUT OF SYNC with LANGUAGE_LIST.md", file=sys.stderr)

    if not (backend_synced and flutter_synced and writing_rules_synced and top_ten_synced):
        print("  Run: python scripts/sync_language_order.py", file=sys.stderr)
        return False

    return True


def sync_language_order():
    """Sync language display order from LANGUAGE_LIST.md to backend and Flutter."""
    print(f"Parsing {LANGUAGE_LIST_MD}...")
    language_orders = parse_language_list_md()
    print(f"  Found {len(language_orders)} languages")

    # Update backend
    print(f"\nReading {LANGUAGE_CONFIG_PY}...")
    current_config = LANGUAGE_CONFIG_PY.read_text(encoding="utf-8")

    print("Extracting language name to code mapping...")
    name_to_code = extract_language_code_mapping(current_config)
    print(f"  Found {len(name_to_code)} language definitions")

    print("\nUpdating backend display_order values...")
    updated_config = update_display_order_in_config(current_config, language_orders, name_to_code)
    LANGUAGE_CONFIG_PY.write_text(updated_config, encoding="utf-8")
    print(f"[OK] Updated {LANGUAGE_CONFIG_PY}")

    # Update Flutter
    print(f"\nReading {FLUTTER_LANGUAGE_DART}...")
    current_dart = FLUTTER_LANGUAGE_DART.read_text(encoding="utf-8")

    print("Reordering Flutter language list...")
    updated_dart = reorder_flutter_languages(current_dart, language_orders, name_to_code)
    FLUTTER_LANGUAGE_DART.write_text(updated_dart, encoding="utf-8")
    print(f"[OK] Updated {FLUTTER_LANGUAGE_DART}")

    # Update LANGUAGE_WRITING_RULES.md
    print(f"\nReading {LANGUAGE_WRITING_RULES_MD}...")
    current_writing_rules = LANGUAGE_WRITING_RULES_MD.read_text(encoding="utf-8")

    print("Reordering LANGUAGE_WRITING_RULES.md...")
    updated_writing_rules = reorder_writing_rules_md(current_writing_rules, language_orders, name_to_code)
    LANGUAGE_WRITING_RULES_MD.write_text(updated_writing_rules, encoding="utf-8")
    print(f"[OK] Updated {LANGUAGE_WRITING_RULES_MD}")

    # Update TOP_TEN_WORKS_PER_LANGUAGE.md
    print(f"\nReading {TOP_TEN_WORKS_MD}...")
    current_top_ten = TOP_TEN_WORKS_MD.read_text(encoding="utf-8")

    print("Reordering TOP_TEN_WORKS_PER_LANGUAGE.md...")
    updated_top_ten = reorder_top_ten_works_md(current_top_ten, language_orders, name_to_code)
    TOP_TEN_WORKS_MD.write_text(updated_top_ten, encoding="utf-8")
    print(f"[OK] Updated {TOP_TEN_WORKS_MD}")

    print("\nLanguage order synced successfully!")
    print("  To reorder languages: edit docs/LANGUAGE_LIST.md and run this script again")


def main():
    """Main entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Sync language display order from LANGUAGE_LIST.md to language_config.py"
    )
    parser.add_argument(
        "--check", action="store_true", help="Validate only (don't modify files). Exit 1 if out of sync."
    )

    args = parser.parse_args()

    try:
        if args.check:
            is_synced = validate_sync()
            sys.exit(0 if is_synced else 1)
        else:
            sync_language_order()
            sys.exit(0)
    except Exception as e:
        print(f"ERROR: {e}", file=sys.stderr)
        import traceback

        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
