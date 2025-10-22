import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/language_controller.dart';
import '../theme/vibrant_theme.dart';
import 'language_picker_sheet.dart';

/// Compact language selector for use in app bars
class CompactLanguageSelector extends ConsumerWidget {
  const CompactLanguageSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCodeAsync = ref.watch(languageControllerProvider);
    final sections = ref.watch(languageMenuSectionsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return languageCodeAsync.when(
      data: (currentLanguageCode) {
        final allLanguages = sections.allOrdered;
        final selectable = sections.available;
        final currentInfo = allLanguages.firstWhere(
          (lang) => lang.code == currentLanguageCode,
          orElse: () =>
              selectable.isNotEmpty ? selectable.first : allLanguages.first,
        );

        Future<void> openPicker() async {
          final chosen = await LanguagePickerSheet.show(
            context: context,
            currentLanguageCode: currentLanguageCode,
          );
          if (chosen != null && chosen.isAvailable) {
            if (chosen.code != currentLanguageCode) {
              ref
                  .read(languageControllerProvider.notifier)
                  .setLanguage(chosen.code);
            }
          }
        }

        return Tooltip(
          message: 'Current language: ${currentInfo.name}',
          child: InkWell(
            borderRadius: BorderRadius.circular(VibrantRadius.md),
            onTap: openPicker,
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
                      currentInfo.code.toUpperCase(),
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
          ),
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
