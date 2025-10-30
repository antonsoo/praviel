import 'package:flutter/material.dart';
import '../models/language.dart';
import 'ancient_label.dart';

/// Modern language selection widget that uses the availableLanguages list
/// and renders endonyms with historically accurate scripts and text direction.
///
/// This replaces the hardcoded language_selector.dart with a data-driven approach.
class LanguageSelectorV2 extends StatelessWidget {
  const LanguageSelectorV2({
    super.key,
    this.currentLanguage = 'grc',
    this.onLanguageSelected,
  });

  final String currentLanguage;
  final void Function(String languageCode)? onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Learning Language',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Render all available languages from the model
        ...availableLanguages.map((language) {
          return _LanguageCardV2(
            language: language,
            isSelected: currentLanguage == language.code,
            onTap: language.isAvailable
                ? () => onLanguageSelected?.call(language.code)
                : null,
          );
        }),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Want another language? Submit a feature request on GitHub!',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguageCardV2 extends StatelessWidget {
  const _LanguageCardV2({
    required this.language,
    this.isSelected = false,
    this.onTap,
  });

  final LanguageInfo language;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAvailable = language.isAvailable;

    // Determine status badge text
    String? statusText;
    Color? statusColor;
    if (!isAvailable) {
      if (language.comingSoon) {
        statusText = 'Planned';
        statusColor = colorScheme.surfaceContainerHighest;
      } else {
        statusText = 'Later';
        statusColor = colorScheme.surfaceContainerHighest;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Flag emoji
              Text(language.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              // Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            language.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isAvailable
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isAvailable && statusText != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                statusText,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        if (isSelected)
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Active',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Use AncientLabel for historically accurate rendering
                    AncientLabel(
                      language: language,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.start,
                      showTooltip: true,
                    ),
                    // Show script information if available
                    if (language.script != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        language.script!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow or lock icon
              if (isAvailable)
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant)
              else
                Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
