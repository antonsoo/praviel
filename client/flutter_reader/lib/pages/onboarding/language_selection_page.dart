import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/language_preferences.dart';
import '../../services/haptic_service.dart';
import '../../models/language.dart';
import '../../widgets/ancient_label.dart';
import '../../widgets/premium_snackbars.dart';

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

  // Use only available languages from our updated model
  List<LanguageInfo> get _languages => availableLanguages
      .where((lang) => lang.isAvailable)
      .toList();

  Future<void> _saveAndContinue() async {
    if (_selectedLanguages.isEmpty) {
      HapticService.error();
      PremiumSnackBar.error(
        context,
        title: 'No Language Selected',
        message: 'Please select at least one language to continue',
      );
      return;
    }

    HapticService.success();

    setState(() {
      _saving = true;
    });

    try {
      // Set the first selected language as active
      final firstLanguage = _selectedLanguages.first;
      await ref
          .read(selectedLanguageProvider.notifier)
          .setLanguage(firstLanguage);

      // For now, we only support one active language at a time
      // Multiple language support can be added later

      if (mounted) {
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        HapticService.error();
        PremiumSnackBar.error(
          context,
          title: 'Save Failed',
          message: 'Failed to save preferences: $e',
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
                          HapticService.selection();
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

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.isSelected,
    required this.onToggle,
  });

  final LanguageInfo language;
  final bool isSelected;
  final VoidCallback onToggle;

  // Map language codes to gradients and icons
  static final Map<String, Gradient> _gradients = {
    'grc': LinearGradient(
      colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'lat': LinearGradient(
      colors: [Color(0xFFE74C3C), Color(0xFFC0392B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'hbo': LinearGradient(
      colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'san': LinearGradient(
      colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  static final Map<String, IconData> _icons = {
    'grc': Icons.architecture,
    'lat': Icons.account_balance,
    'hbo': Icons.auto_stories,
    'san': Icons.self_improvement,
  };

  Gradient _getGradient() {
    return _gradients[language.code] ?? VibrantTheme.heroGradient;
  }

  IconData _getIcon() {
    return _icons[language.code] ?? Icons.language;
  }

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
          gradient: isSelected ? _getGradient() : null,
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
                _getIcon(),
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
                  // Use AncientLabel for historically accurate rendering
                  AncientLabel(
                    language: language,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.start,
                    showTooltip: false,
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  // Show script information
                  if (language.script != null)
                    Text(
                      language.script!,
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
