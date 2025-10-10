import 'package:flutter/material.dart';

/// Language selection widget showing available and upcoming languages
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
        _LanguageCard(
          languageCode: 'grc',
          languageName: 'Classical Greek',
          languageNative: 'Ἑλληνική',
          icon: '🏛️',
          isAvailable: true,
          isSelected: currentLanguage == 'grc',
          keyTexts: 'Homer\'s Iliad, Odyssey',
          onTap: () => onLanguageSelected?.call('grc'),
        ),
        _LanguageCard(
          languageCode: 'lat',
          languageName: 'Classical Latin',
          languageNative: 'Lingua Latīna',
          icon: '🏛️',
          isAvailable: false,
          status: 'In Development',
          keyTexts: 'Caesar, Cicero, Virgil',
          onTap: null,
        ),
        _LanguageCard(
          languageCode: 'hbo',
          languageName: 'Biblical Hebrew',
          languageNative: 'עִבְרִית',
          icon: '✡️',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Hebrew Bible (Tanakh)',
          onTap: null,
        ),
        _LanguageCard(
          languageCode: 'egy',
          languageName: 'Ancient Egyptian',
          languageNative: 'r n km.t',
          icon: '𓂧',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Pyramid Texts, Book of the Dead',
          onTap: null,
        ),
        _LanguageCard(
          languageCode: 'sux',
          languageName: 'Sumerian',
          languageNative: '𒅴𒂠',
          icon: '𒀭',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Royal Inscriptions, Literary Texts',
          onTap: null,
        ),
        _LanguageCard(
          languageCode: 'grc-koine',
          languageName: 'Koine Greek',
          languageNative: 'Κοινὴ Ἑλληνική',
          icon: '✝️',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'New Testament, Septuagint',
          onTap: null,
        ),
        _LanguageCard(
          languageCode: 'akk',
          languageName: 'Akkadian',
          languageNative: 'Akkadû',
          icon: '𒁀',
          isAvailable: false,
          status: 'Planned',
          keyTexts: 'Epic of Gilgamesh, Code of Hammurabi',
          onTap: null,
        ),
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

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.languageCode,
    required this.languageName,
    required this.languageNative,
    required this.icon,
    required this.isAvailable,
    this.isSelected = false,
    this.status,
    this.keyTexts,
    this.onTap,
  });

  final String languageCode;
  final String languageName;
  final String languageNative;
  final String icon;
  final bool isAvailable;
  final bool isSelected;
  final String? status;
  final String? keyTexts;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              // Icon
              Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 16),
              // Language info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          languageName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isAvailable
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isAvailable && status != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: status == 'In Development'
                                  ? Colors.orange.withOpacity(0.2)
                                  : colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: status == 'In Development'
                                    ? Colors.orange[700]
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        if (isSelected)
                          Container(
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
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageNative,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (keyTexts != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        keyTexts!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow or lock icon
              if (isAvailable)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                )
              else
                Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
