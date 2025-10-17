#!/usr/bin/env python3
"""
Script to fix retry logic in Flutter API services by replacing string-based
error detection with type-safe exception checking.
"""

import re
import sys
from pathlib import Path


def fix_api_service(file_path: Path, api_name: str):
    """Fix retry logic in a single API service file."""
    content = file_path.read_text(encoding="utf-8")

    # Check if already fixed
    if f"{api_name}ApiException" in content:
        print(f"[OK] {file_path.name} already fixed")
        return False

    # 1. Add exception class after imports
    exception_class = f"""
class {api_name}ApiException implements Exception {{
  const {api_name}ApiException(this.message, {{this.statusCode}});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}}

"""

    # Find where to insert (after last import before first class/comment)
    import_end = 0
    for match in re.finditer(r"^import .+;$", content, re.MULTILINE):
        import_end = match.end()

    if import_end > 0:
        # Find next newline after imports
        next_newline = content.find("\n", import_end)
        content = content[: next_newline + 1] + exception_class + content[next_newline + 1 :]

    # 2. Fix retry logic - replace string checking with type checking
    old_retry = r"""      catch \(e\) \{
        // Don't retry on HTTP 4xx errors \(client errors\)
        if \(e\.toString\(\)\.contains\('Failed to'\) &&
            \(e\.toString\(\)\.contains\('40'\) \|\|
                e\.toString\(\)\.contains\('41'\) \|\|
                e\.toString\(\)\.contains\('42'\) \|\|
                e\.toString\(\)\.contains\('43'\)\)\) \{
          rethrow;
        \}"""

    new_retry = f"""      catch (e) {{
        // Don't retry on API errors (4xx/5xx) - only transient network errors
        if (e is {api_name}ApiException) {{
          rethrow;
        }}"""

    content = re.sub(old_retry, new_retry, content, flags=re.MULTILINE)

    # 3. Replace all Exception throws with XxxApiException
    def replace_exception(match):
        message = match.group(1)
        return f"""throw {api_name}ApiException(
          '{message}: ${{response.body}}',
          statusCode: response.statusCode,
        );"""

    content = re.sub(r"throw Exception\('([^']+): \$\{response\.body\}'\);", replace_exception, content)

    # Write back
    file_path.write_text(content, encoding="utf-8")
    print(f"[FIXED] {file_path.name}")
    return True


def main():
    base_dir = Path(__file__).parent / "client" / "flutter_reader" / "lib" / "services"

    files_to_fix = [
        ("coach_api.dart", "Coach"),
        ("search_api.dart", "Search"),
        ("password_reset_api.dart", "PasswordReset"),
        ("srs_api.dart", "Srs"),
        ("user_preferences_api.dart", "UserPreferences"),
        ("api_keys_api.dart", "ApiKeys"),
    ]

    fixed_count = 0
    for filename, api_name in files_to_fix:
        file_path = base_dir / filename
        if file_path.exists():
            if fix_api_service(file_path, api_name):
                fixed_count += 1
        else:
            print(f"[ERROR] File not found: {filename}")

    print(f"\n[DONE] Fixed {fixed_count}/{len(files_to_fix)} files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
