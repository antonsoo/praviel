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

class _LanguageSelectionPageState extends ConsumerState<LanguageSelectionPage>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedLanguages = {};
  bool _saving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Use only available languages from our updated model
  List<LanguageInfo> get _languages => availableLanguages
      .where((lang) => lang.isAvailable)
      .toList();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth =
                      constraints.maxWidth.clamp(320.0, double.infinity);
                  int columns;
                  if (availableWidth >= 1080) {
                    columns = 4;
                  } else if (availableWidth >= 820) {
                    columns = 3;
                  } else if (availableWidth >= 540) {
                    columns = 2;
                  } else {
                    columns = 1;
                  }
                  final gutter = VibrantSpacing.md;
                  final tileWidth =
                      (availableWidth - (columns - 1) * gutter) / columns;
                  final normalizedWidth =
                      tileWidth.clamp(180.0, 320.0).toDouble();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.lg,
                    ),
                    child: Wrap(
                      spacing: gutter,
                      runSpacing: VibrantSpacing.md,
                      children: _languages.map((language) {
                        final isSelected =
                            _selectedLanguages.contains(language.code);
                        return SizedBox(
                          width: normalizedWidth,
                          child: _CompactLanguageTile(
                            language: language,
                            selected: isSelected,
                            onTap: () {
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
                        );
                      }).toList(),
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
    ),
  );
  }
}

class _CompactLanguageTile extends StatelessWidget {
  const _CompactLanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final LanguageInfo language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final foregroundColor =
        selected ? Colors.white : colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(alpha: 0.92),
                  colorScheme.secondary.withValues(alpha: 0.78),
                ],
              )
            : null,
        color: selected ? null : colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: selected
              ? Colors.transparent
              : colorScheme.outlineVariant.withValues(alpha: 0.28),
        ),
        boxShadow: selected ? VibrantShadow.sm(colorScheme) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VibrantSpacing.md,
            vertical: VibrantSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                language.flag,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      language.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: selected ? Colors.white : colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      language.nativeName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (language.altEndonym != null &&
                        language.altEndonym!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: VibrantSpacing.xxs),
                        child: Text(
                          language.altEndonym!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.8)
                                : colorScheme.primary,
                          ),
                        ),
                      ),
                    const SizedBox(height: VibrantSpacing.xs),
                    AncientLabel(
                      language: language,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.9)
                            : colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.start,
                      showTooltip: false,
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: animation,
                  child: child,
                ),
                child: selected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('selected'),
                        color: Colors.white,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        key: const ValueKey('unselected'),
                        color: colorScheme.outlineVariant,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
