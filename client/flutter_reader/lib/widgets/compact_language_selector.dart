import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/language_controller.dart';
import '../theme/vibrant_theme.dart';
import '../models/language.dart';
import 'ancient_label.dart';

/// Compact language selector for use in app bars
class CompactLanguageSelector extends ConsumerWidget {
  const CompactLanguageSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageAsync = ref.watch(languageControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return languageAsync.when(
      data: (currentLanguage) {
        return PopupMenuButton<AncientLanguage>(
          tooltip: 'Select language',
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? VibrantSpacing.sm : VibrantSpacing.md,
              vertical: VibrantSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  size: compact ? 16 : 18,
                  color: colorScheme.primary,
                ),
                if (!compact) ...[
                  SizedBox(width: VibrantSpacing.xs),
                  Text(
                    currentLanguage.code.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                SizedBox(width: VibrantSpacing.xs),
                Icon(
                  Icons.arrow_drop_down,
                  size: compact ? 16 : 18,
                  color: colorScheme.primary,
                ),
              ],
            ),
          ),
          onSelected: (language) {
            ref.read(languageControllerProvider.notifier).setLanguage(language);
          },
          itemBuilder: (context) {
            // Get available languages from the model
            final availableLangs = availableLanguages.where((lang) => lang.isAvailable).toList();

            return [
              for (final langInfo in availableLangs)
                PopupMenuItem<AncientLanguage>(
                  value: AncientLanguage.values.firstWhere(
                    (lang) => lang.code == langInfo.code,
                    orElse: () => AncientLanguage.greek,
                  ),
                  child: Row(
                    children: [
                      if (langInfo.code == currentLanguage.code)
                        Icon(Icons.check, size: 18, color: colorScheme.primary)
                      else
                        const SizedBox(width: 18),
                      SizedBox(width: VibrantSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              langInfo.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: langInfo.code == currentLanguage.code
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            // Use AncientLabel for historically accurate rendering
                            AncientLabel(
                              language: langInfo,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.start,
                              showTooltip: false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ];
          },
        );
      },
      loading: () => Container(
        padding: EdgeInsets.all(
          compact ? VibrantSpacing.sm : VibrantSpacing.md,
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => Icon(
        Icons.language,
        size: compact ? 16 : 20,
        color: colorScheme.error,
      ),
    );
  }
}
