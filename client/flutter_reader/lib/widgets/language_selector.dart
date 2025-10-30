import 'package:flutter/material.dart';
import '../models/language.dart';

/// Language selection widget showing all 46 languages in official order
/// Matches backend/app/lesson/language_config.py and LANGUAGE_LIST.md
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    this.currentLanguage = 'grc',
    this.onLanguageSelected,
  });

  final String currentLanguage;
  final void Function(String languageCode)? onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Separate languages into categories
    final availableLangs = availableLanguages.where((l) => l.isAvailable).toList();
    final comingSoonLangs = availableLanguages.where((l) => l.comingSoon && !l.isAvailable).toList();
    final fullCourseLangs = availableLanguages.where((l) => l.isFullCourse && !l.isAvailable && !l.comingSoon).toList();
    final partialCourseLangs = availableLanguages.where((l) => !l.isFullCourse).toList();

    return ListView(
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

        // Available languages
        if (availableLangs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Available Now',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          ...availableLangs.map((lang) => _LanguageCard(
                language: lang,
                isSelected: currentLanguage == lang.code,
                onTap: () => onLanguageSelected?.call(lang.code),
              )),
        ],

        // Coming soon languages
        if (comingSoonLangs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Coming Soon',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
          ),
          ...comingSoonLangs.map((lang) => _LanguageCard(
                language: lang,
                isSelected: false,
                status: 'Coming Soon',
                onTap: null,
              )),
        ],

        // Full course languages (future)
        if (fullCourseLangs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Full Courses (Planned)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
          ...fullCourseLangs.map((lang) => _LanguageCard(
                language: lang,
                isSelected: false,
                status: 'Planned',
                onTap: null,
              )),
        ],

        // Partial courses (inscriptions only)
        if (partialCourseLangs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Inscription Modules (Planned)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.tertiary.withValues(alpha: 0.7),
              ),
            ),
          ),
          ...partialCourseLangs.map((lang) => _LanguageCard(
                language: lang,
                isSelected: false,
                status: 'Inscription Only',
                onTap: null,
              )),
        ],

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
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    this.isSelected = false,
    this.status,
    this.onTap,
  });

  final LanguageInfo language;
  final bool isSelected;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAvailable = language.isAvailable;

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
              // Icon/emoji
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
                        if (!isAvailable && status != null)
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: status == 'Coming Soon'
                                    ? Colors.orange.withValues(alpha: 0.2)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: status == 'Coming Soon'
                                      ? Colors.orange[700]
                                      : colorScheme.onSurfaceVariant,
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
                    Text(
                      language.nativeName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      textDirection: language.textDirection,
                    ),
                    if (language.script != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Script: ${language.script}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    if (language.tooltip != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        language.tooltip!,
                        style: theme.textTheme.bodySmall?.copyWith(
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
