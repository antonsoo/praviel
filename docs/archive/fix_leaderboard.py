#!/usr/bin/env python3
# ruff: noqa: E501
"""Fix LeaderboardPage to call loadLeaderboards and handle errors properly."""

import re
import sys


def main():
    file_path = "client/flutter_reader/lib/pages/leaderboard_page.dart"

    print(f"Reading {file_path}...")
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    original_content = content

    # Step 1: Add _hasLoadedData field
    print("Step 1: Adding _hasLoadedData field...")
    content = content.replace(
        "  int _selectedTab = 0;", "  int _selectedTab = 0;\n  bool _hasLoadedData = false;"
    )

    # Step 2: Add loading methods after dispose
    print("Step 2: Adding loading methods...")
    dispose_pattern = (
        r"(@override\s+void dispose\(\) \{\s+_tabController\.dispose\(\);\s+super\.dispose\(\);\s+\})"
    )

    new_methods = r"""\1

  Future<void> _loadLeaderboardData(LeaderboardService service) async {
    if (!_hasLoadedData) {
      try {
        await service.loadLeaderboards();
        if (mounted) {
          setState(() {
            _hasLoadedData = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _hasLoadedData = true;
          });
        }
      }
    }
  }

  Future<void> _handleRefresh(LeaderboardService service) async {
    try {
      await service.refresh();
    } catch (e) {
      // Error handled by service
    }
  }"""

    content = re.sub(dispose_pattern, new_methods, content, flags=re.DOTALL)

    # Step 3: Wrap body with RefreshIndicator
    print("Step 3: Adding RefreshIndicator...")
    content = content.replace(
        "      body: CustomScrollView(\n        physics: const BouncingScrollPhysics(),",
        """      body: RefreshIndicator(
        onRefresh: () async {
          final service = await leaderboardServiceAsync.future;
          await _handleRefresh(service);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),""",
    )

    # Step 4: Close RefreshIndicator
    print("Step 4: Closing RefreshIndicator...")
    # Find the last sliver closing and add RefreshIndicator close
    content = re.sub(
        r"(\s+),\n(\s+)\],\n\s+\),\n\s+\);", r"\1,\n\2],\n        ),\n      ),\n    );", content, count=1
    )

    # Step 5: Add loading trigger in leaderboardServiceAsync.when
    print("Step 5: Adding loading trigger...")
    content = re.sub(
        r"(data: \(leaderboardService\) \{\s+return ListenableBuilder\()",
        r"""data: (leaderboardService) {
                        // Load data on first build
                        if (!_hasLoadedData) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _loadLeaderboardData(leaderboardService);
                          });
                        }

                        return ListenableBuilder(""",
        content,
        flags=re.DOTALL,
    )

    # Step 6: Add loading and error checks in ListenableBuilder
    print("Step 6: Adding loading and error checks...")
    content = re.sub(
        r"(builder: \(context, _\) \{\s+final currentUserXP = progressService\.xpTotal;\s+final currentUserLevel = progressService\.currentLevel;)",
        r"""\1

                            // Show loading indicator while loading
                            if (leaderboardService.isLoading && !_hasLoadedData) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(VibrantSpacing.xxxl),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            // Show error if there's an error
                            if (leaderboardService.error != null) {
                              return _buildErrorState(
                                theme,
                                colorScheme,
                                leaderboardService.error!,
                              );
                            }""",
        content,
        flags=re.DOTALL,
    )

    # Step 7: Update _buildErrorState signature
    print("Step 7: Updating _buildErrorState signature...")
    content = content.replace(
        "  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {",
        "  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme, String error) {",
    )

    # Step 8: Add error message to error state
    print("Step 8: Adding error message display...")
    content = re.sub(
        r"(Text\(\s+'Unable to load leaderboard',\s+style: theme\.textTheme\.titleMedium\?\.copyWith\(\s+color: colorScheme\.onErrorContainer,\s+\),\s+\),)",
        r"""\1
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),""",
        content,
        flags=re.DOTALL,
    )

    # Step 9: Update error state calls
    print("Step 9: Updating error state calls...")
    content = re.sub(
        r"error: \(error, stack\) => _buildErrorState\(theme, colorScheme\)",
        r"error: (error, stack) => _buildErrorState(\n                        theme,\n                        colorScheme,\n                        error.toString(),\n                      )",
        content,
    )

    # Check if anything changed
    if content == original_content:
        print("❌ No changes made - file may already be fixed or patterns didn't match")
        return 1

    # Write the fixed file
    print(f"Writing fixed file to {file_path}...")
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

    print("✅ LeaderboardPage fixed successfully!")
    print("\nChanges made:")
    print("  - Added _hasLoadedData state tracking")
    print("  - Added _loadLeaderboardData() method")
    print("  - Added _handleRefresh() method")
    print("  - Wrapped body with RefreshIndicator")
    print("  - Added loading state display")
    print("  - Added error state display with message")
    print("  - Updated _buildErrorState to show error details")

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)
