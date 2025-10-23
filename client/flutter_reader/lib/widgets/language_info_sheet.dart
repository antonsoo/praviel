/// Beautiful modal sheet displaying historical and cultural information about a language.
library;

import 'package:flutter/material.dart';
import '../data/language_descriptions.dart';
import '../models/language.dart';
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';

class LanguageInfoSheet extends StatelessWidget {
  const LanguageInfoSheet({
    super.key,
    required this.language,
    required this.description,
  });

  final LanguageInfo language;
  final LanguageDescription description;

  static Future<void> show({
    required BuildContext context,
    required LanguageInfo language,
  }) async {
    final description = languageDescriptions[language.code];
    if (description == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No information available for ${language.name} yet.'),
        ),
      );
      return;
    }

    HapticService.light();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LanguageInfoSheet(
        language: language,
        description: description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VibrantRadius.xl),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                child: Row(
                  children: [
                    // Language flag/emoji
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: VibrantTheme.heroGradient,
                        borderRadius: BorderRadius.circular(VibrantRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          language.flag,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: VibrantSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            language.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.xs),
                          Text(
                            language.nativeName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  children: [
                    // When/Where spoken
                    _buildInfoCard(
                      context,
                      icon: Icons.calendar_today_rounded,
                      title: 'When Spoken',
                      content: description.whenSpoken,
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    _buildInfoCard(
                      context,
                      icon: Icons.public_rounded,
                      title: 'Where Spoken',
                      content: description.whereSpoken,
                    ),

                    const SizedBox(height: VibrantSpacing.xl),

                    // Why Important
                    _buildSection(
                      context,
                      title: 'Why It Matters',
                      icon: Icons.star_rounded,
                      child: Text(
                        description.whyImportant,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.xl),

                    // Fun Facts
                    _buildSection(
                      context,
                      title: 'Fun Facts',
                      icon: Icons.lightbulb_rounded,
                      child: Column(
                        children: description.funFacts.asMap().entries.map((entry) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: entry.key < description.funFacts.length - 1
                                  ? VibrantSpacing.md
                                  : 0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${entry.key + 1}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: VibrantSpacing.md),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.xl),

                    // Famous Quotes
                    _buildSection(
                      context,
                      title: 'Famous Quotes',
                      icon: Icons.format_quote_rounded,
                      child: Column(
                        children: description.famousQuotes.map((quote) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: VibrantSpacing.lg),
                            padding: const EdgeInsets.all(VibrantSpacing.lg),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                                  colorScheme.tertiaryContainer.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(VibrantRadius.md),
                              border: Border.all(
                                color: colorScheme.outline.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quote.text,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: VibrantSpacing.sm),
                                Text(
                                  '"${quote.translation}"',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: VibrantSpacing.sm),
                                Text(
                                  '— ${quote.source}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.xl),

                    // Notable Works
                    _buildSection(
                      context,
                      title: 'Notable Works',
                      icon: Icons.menu_book_rounded,
                      child: Wrap(
                        spacing: VibrantSpacing.sm,
                        runSpacing: VibrantSpacing.sm,
                        children: description.notableWorks.map((work) {
                          return Chip(
                            label: Text(work),
                            backgroundColor: colorScheme.secondaryContainer,
                            labelStyle: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: VibrantSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.sm),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(VibrantRadius.sm),
            ),
            child: Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.lg),
        child,
      ],
    );
  }
}
