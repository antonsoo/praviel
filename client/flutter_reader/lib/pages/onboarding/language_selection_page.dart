import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/language_preferences.dart';

/// Language selection screen for onboarding
class LanguageSelectionPage extends ConsumerStatefulWidget {
  const LanguageSelectionPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  ConsumerState<LanguageSelectionPage> createState() =>
      _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends ConsumerState<LanguageSelectionPage> {
  final Set<String> _selectedLanguages = {};
  bool _saving = false;

  final List<_LanguageOption> _languages = [
    _LanguageOption(
      code: 'grc',
      name: 'Ancient Greek',
      nativeName: 'Ἑλληνική',
      description: 'Read Homer, Plato, and the New Testament',
      gradient: const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      ),
      icon: Icons.history_edu_rounded,
    ),
    _LanguageOption(
      code: 'lat',
      name: 'Latin',
      nativeName: 'Lingua Latina',
      description: 'Read Virgil, Cicero, and the Vulgate',
      gradient: const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      ),
      icon: Icons.account_balance_rounded,
    ),
    _LanguageOption(
      code: 'hbo',
      name: 'Biblical Hebrew',
      nativeName: 'עִבְרִית',
      description: 'Read the Hebrew Bible and Talmud',
      gradient: const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ),
      icon: Icons.menu_book_rounded,
    ),
    _LanguageOption(
      code: 'san',
      name: 'Sanskrit',
      nativeName: 'संस्कृतम्',
      description: 'Read the Vedas and Bhagavad Gita',
      gradient: const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
      icon: Icons.self_improvement_rounded,
    ),
  ];

  Future<void> _saveAndContinue() async {
    if (_selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one language to continue'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      // Set the first selected language as active
      final firstLanguage = _selectedLanguages.first;
      await ref.read(selectedLanguageProvider.notifier).setLanguage(firstLanguage);

      // For now, we only support one active language at a time
      // Multiple language support can be added later

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              child: Column(
                children: [
                  Text(
                    'Choose Your Path',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    'Select one or more ancient languages to learn',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Language cards
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.lg,
                ),
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final language = _languages[index];
                  final isSelected = _selectedLanguages.contains(language.code);

                  return SlideInFromBottom(
                    delay: Duration(milliseconds: 100 + (index * 50)),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: VibrantSpacing.lg),
                      child: _LanguageCard(
                        language: language,
                        isSelected: isSelected,
                        onToggle: () {
                          setState(() {
                            if (isSelected) {
                              _selectedLanguages.remove(language.code);
                            } else {
                              _selectedLanguages.add(language.code);
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              child: AnimatedScaleButton(
                onTap: _saving ? () {} : _saveAndContinue,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: VibrantSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    gradient: _selectedLanguages.isEmpty
                        ? LinearGradient(
                            colors: [
                              colorScheme.surfaceContainerHighest,
                              colorScheme.surfaceContainerHigh,
                            ],
                          )
                        : VibrantTheme.heroGradient,
                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                    boxShadow: _selectedLanguages.isEmpty
                        ? []
                        : [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: _saving
                      ? const Center(
                          child: SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _selectedLanguages.isEmpty
                                  ? 'Select at least one language'
                                  : 'Continue with ${_selectedLanguages.length} ${_selectedLanguages.length == 1 ? "language" : "languages"}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: _selectedLanguages.isEmpty
                                    ? colorScheme.onSurfaceVariant
                                    : Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (_selectedLanguages.isNotEmpty) ...[
                              const SizedBox(width: VibrantSpacing.sm),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String description;
  final Gradient gradient;
  final IconData icon;

  _LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.description,
    required this.gradient,
    required this.icon,
  });
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onToggle,
  });

  final _LanguageOption language;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedScaleButton(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          gradient: isSelected ? language.gradient : null,
          color: isSelected ? null : colorScheme.surface,
          borderRadius: BorderRadius.circular(VibrantRadius.xl),
          border: Border.all(
            color: isSelected ? Colors.transparent : colorScheme.outlineVariant,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : VibrantShadow.sm(colorScheme),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Icon(
                language.icon,
                size: 28,
                color: isSelected
                    ? Colors.white
                    : colorScheme.onPrimaryContainer,
              ),
            ),

            const SizedBox(width: VibrantSpacing.lg),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xxs),
                  Text(
                    language.nativeName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    language.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.85)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark
            AnimatedScale(
              scale: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
