import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/language.dart';
import '../services/byok_controller.dart';
import '../services/haptic_service.dart';
import '../services/language_controller.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/byok_onboarding_sheet.dart';
import '../widgets/language_info_sheet.dart';
import 'onboarding/auth_choice_screen.dart';

enum _KeyPreference { demo, byo, echo }

class PremiumOnboarding2025 extends ConsumerStatefulWidget {
  const PremiumOnboarding2025({super.key});

  @override
  ConsumerState<PremiumOnboarding2025> createState() =>
      _PremiumOnboarding2025State();
}

class _PremiumOnboarding2025State extends ConsumerState<PremiumOnboarding2025>
    with TickerProviderStateMixin {
  static const _totalSteps = 3;

  final PageController _pageController = PageController();
  int _pageIndex = 0;
  _KeyPreference _keyPreference = _KeyPreference.demo;
  bool _saving = false;

  void _goTo(int index) {
    if (_pageIndex == index) return;
    setState(() => _pageIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_pageIndex < _totalSteps - 1) {
      HapticService.light();
      _goTo(_pageIndex + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _back() {
    if (_pageIndex == 0) return;
    HapticService.light();
    _goTo(_pageIndex - 1);
  }

  Future<void> _completeOnboarding() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_welcome', true);
      await prefs.setBool('onboarding_complete', true);

      final languageController = ref.read(languageControllerProvider.notifier);
      final selected = ref.read(languageControllerProvider).value;
      if (selected != null) {
        await languageController.setLanguage(selected);
      }

      final byokController = ref.read(byokControllerProvider.notifier);
      final currentSettings = await ref.read(byokControllerProvider.future);

      switch (_keyPreference) {
        case _KeyPreference.demo:
          await byokController.saveSettings(
            currentSettings.copyWith(
              apiKey: '',
              lessonProvider: 'openai',
              useDemoLessonKey: true,
            ),
          );
          break;
        case _KeyPreference.echo:
          await byokController.saveSettings(
            currentSettings.copyWith(
              apiKey: '',
              lessonProvider: 'echo',
              clearLessonModel: true,
              useDemoLessonKey: false,
            ),
          );
          break;
        case _KeyPreference.byo:
          final hasKey = currentSettings.apiKey.trim().isNotEmpty;
          if (!hasKey && mounted) {
            final result = await ByokOnboardingSheet.show(
              context: context,
              initial: currentSettings,
            );
            if (result != null) {
              await byokController.saveSettings(result.settings);
            }
          } else {
            await byokController.saveSettings(
              currentSettings.copyWith(useDemoLessonKey: false),
            );
          }
          break;
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
      );
    } catch (error) {
      debugPrint('[Onboarding] Unable to finish: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to finish onboarding. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (_pageIndex + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          _GradientBackdrop(colorScheme: colorScheme),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.lg,
                    vertical: VibrantSpacing.md,
                  ),
                  child: _TopBar(
                    progress: progress,
                    stepLabel: 'Step ${_pageIndex + 1} of $_totalSteps',
                    onBack: _pageIndex == 0 ? null : _back,
                    onSkip: _pageIndex == _totalSteps - 1
                        ? null
                        : () => _goTo(_totalSteps - 1),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcomeStep(),
                      _buildLanguageStep(),
                      _buildKeyStep(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VibrantSpacing.lg,
                    0,
                    VibrantSpacing.lg,
                    VibrantSpacing.xl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _next,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: VibrantSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VibrantRadius.xl),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _pageIndex == _totalSteps - 1
                                  ? 'Start learning'
                                  : 'Continue',
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.xl,
        vertical: VibrantSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Praviel',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'A modern academy for mastering ancient languages. Personalized lessons, a responsive reader, and musical ambiance transport you into the classical world.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xl),
          const _FeatureCard(
            icon: Icons.auto_awesome_rounded,
            title: 'Adaptive lessons',
            description:
                'Exercises respond to your pace with cinematic feedback and rich explanations.',
          ),
          const SizedBox(height: VibrantSpacing.md),
          const _FeatureCard(
            icon: Icons.menu_book_rounded,
            title: 'Scholarly reader',
            description:
                'Inline morphology, lexicon lookups, translations, and curated excerpts per language.',
          ),
          const SizedBox(height: VibrantSpacing.md),
          const _FeatureCard(
            icon: Icons.timeline_rounded,
            title: 'Motivating progression',
            description:
                'Track streaks, unlock achievements, and celebrate milestones with festival-style effects.',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedAsync = ref.watch(languageControllerProvider);
    final selectedCode = selectedAsync.value;

    final languages = List<LanguageInfo>.from(availableLanguages)
      ..sort((a, b) {
        if (a.isAvailable == b.isAvailable) {
          return a.name.compareTo(b.name);
        }
        return b.isAvailable ? 1 : -1;
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your first language',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            'Switch or add more anytime from settings. Languages marked “Coming soon” are already on the roadmap.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xl),
          Wrap(
            spacing: VibrantSpacing.md,
            runSpacing: VibrantSpacing.md,
            children: languages.map((language) {
              final selected = language.code == selectedCode;
              return _LanguageChip(
                language: language,
                selected: selected,
                onTap: () async {
                  HapticService.medium();
                  await ref
                      .read(languageControllerProvider.notifier)
                      .setLanguage(language.code);
                },
                onInfo: () => LanguageInfoSheet.show(
                  context: context,
                  language: language,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyStep() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How should we generate lessons?',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            'Choose the engine that powers your content. You can switch at any time.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xl),
          _KeyChoiceCard(
            icon: Icons.rocket_launch_rounded,
            title: 'Use Praviel demo key',
            subtitle:
                'Jump in instantly with generous free usage, perfect for evaluation or casual study.',
            selected: _keyPreference == _KeyPreference.demo,
            accent: colorScheme.primary,
            badge: 'Recommended',
            onTap: () {
              setState(() => _keyPreference = _KeyPreference.demo);
              HapticService.success();
            },
          ),
          const SizedBox(height: VibrantSpacing.md),
          _KeyChoiceCard(
            icon: Icons.vpn_key_rounded,
            title: 'Bring your own key',
            subtitle:
                'Connect OpenAI, Anthropic, or Google keys for personalised, unlimited lessons.',
            selected: _keyPreference == _KeyPreference.byo,
            accent: colorScheme.secondary,
            trailing: TextButton(
              onPressed: () async {
                final settings = await ref.read(byokControllerProvider.future);
                if (!mounted) return;
                final result = await ByokOnboardingSheet.show(
                  context: context,
                  initial: settings,
                );
                if (result != null) {
                  await ref
                      .read(byokControllerProvider.notifier)
                      .saveSettings(result.settings);
                }
              },
              child: const Text('Add key now'),
            ),
            onTap: () {
              setState(() => _keyPreference = _KeyPreference.byo);
              HapticService.medium();
            },
          ),
          const SizedBox(height: VibrantSpacing.md),
          _KeyChoiceCard(
            icon: Icons.offline_bolt_rounded,
            title: 'Echo mode (offline)',
            subtitle:
                'Use curated practice without external APIs. Great for classrooms or low-bandwidth contexts.',
            selected: _keyPreference == _KeyPreference.echo,
            accent: colorScheme.tertiary,
            onTap: () {
              setState(() => _keyPreference = _KeyPreference.echo);
              HapticService.light();
            },
          ),
        ],
      ),
    );
  }
}

class _GradientBackdrop extends StatelessWidget {
  const _GradientBackdrop({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.45),
              colorScheme.surface,
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.progress,
    required this.stepLabel,
    this.onBack,
    this.onSkip,
  });

  final double progress;
  final String stepLabel;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        if (onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: onBack,
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Column(
            children: [
              Text(
                stepLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: VibrantSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: progress, minHeight: 6),
              ),
            ],
          ),
        ),
        if (onSkip != null)
          TextButton(onPressed: onSkip, child: const Text('Skip'))
        else
          const SizedBox(width: 48),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: VibrantSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
    required this.language,
    required this.selected,
    required this.onTap,
    required this.onInfo,
  });

  final LanguageInfo language;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = language.isAvailable;

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(VibrantSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          gradient: selected && enabled
              ? LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.9),
                    colorScheme.secondary.withValues(alpha: 0.75),
                  ],
                )
              : null,
          color: selected && enabled ? null : colorScheme.surfaceContainerHigh,
          border: Border.all(
            color: selected && enabled
                ? Colors.transparent
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: selected && enabled ? VibrantShadow.md(colorScheme) : null,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          onTap: enabled ? onTap : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(language.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: VibrantSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: selected && enabled
                          ? Colors.white
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    language.nativeName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: selected && enabled
                          ? Colors.white.withValues(alpha: 0.85)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (!enabled)
                    Padding(
                      padding: const EdgeInsets.only(top: VibrantSpacing.xs),
                      child: Text(
                        'Coming soon',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: VibrantSpacing.sm),
              IconButton(
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: selected && enabled
                      ? Colors.white
                      : colorScheme.onSurfaceVariant,
                ),
                onPressed: onInfo,
              ),
              if (selected && enabled)
                const Icon(Icons.check_circle_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyChoiceCard extends StatelessWidget {
  const _KeyChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.badge,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final String? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        gradient: selected
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.9),
                  accent.withValues(alpha: 0.75),
                ],
              )
            : null,
        color: selected ? null : colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: selected
              ? Colors.transparent
              : colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: selected ? VibrantShadow.lg(colorScheme) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.sm),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white24
                        : accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: selected ? Colors.white : accent),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: selected ? Colors.white : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white24
                          : accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: selected ? Colors.white : accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(height: VibrantSpacing.md),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
