import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;

import '../app_providers.dart';
import '../models/lesson.dart';
import '../services/byok_controller.dart';
import '../services/lesson_api.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/layout/section_header.dart';
import '../widgets/layout/vibrant_background.dart';
import '../widgets/premium_snackbars.dart';

class TextRangePickerPage extends frp.ConsumerStatefulWidget {
  const TextRangePickerPage({super.key});

  @override
  frp.ConsumerState<TextRangePickerPage> createState() =>
      _TextRangePickerPageState();
}

class _TextRangePickerPageState extends frp.ConsumerState<TextRangePickerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _textRanges = [
    {
      'title': 'Iliad 1.1-1.10 (Opening)',
      'subtitle': 'μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος',
      'ref_start': 'Il.1.1',
      'ref_end': 'Il.1.10',
    },
    {
      'title': 'Iliad 1.20-1.50 (Chryses)',
      'subtitle': 'Χρύσην ἀρητῆρα Διὸς',
      'ref_start': 'Il.1.20',
      'ref_end': 'Il.1.50',
    },
    {
      'title': 'Iliad 1.50-1.100 (Apollo\'s Wrath)',
      'subtitle': 'ἔκλαγξαν δ᾽ ἄρ᾽ ὀϊστοὶ',
      'ref_start': 'Il.1.50',
      'ref_end': 'Il.1.100',
    },
    {
      'title': 'Iliad 1.100-1.200 (Assembly)',
      'subtitle': 'ἀγορὴν δὲ καλέσσατο',
      'ref_start': 'Il.1.100',
      'ref_end': 'Il.1.200',
    },
    {
      'title': 'Iliad Book 1 (Complete)',
      'subtitle': '611 lines of epic glory',
      'ref_start': 'Il.1.1',
      'ref_end': 'Il.1.611',
    },
  ];

  bool _isLoading = false;
  String? _error;

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

  Future<void> _generateFromRange(
    String refStart,
    String refEnd,
    String title,
  ) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessonApi = ref.read(lessonApiProvider);
      final settings = await ref.read(byokControllerProvider.future);
      final provider = settings.lessonProvider.trim().isEmpty
          ? 'echo'
          : settings.lessonProvider.trim();

      if (provider != 'echo' && !settings.hasKey) {
        if (!mounted) return;
        HapticService.error();
        PremiumSnackBar.error(
          context,
          message: 'Add your OpenAI key to enable BYOK generation.',
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final params = GeneratorParams(
        language: 'grc',
        profile: 'beginner',
        sources: const ['canon'],
        exerciseTypes: const ['match', 'cloze', 'translate'],
        kCanon: 0,
        provider: provider,
        model: settings.lessonModel,
        textRange: TextRange(refStart: refStart, refEnd: refEnd),
      );

      final response = await lessonApi.generate(params, settings);

      if (!mounted) return;

      if (response.tasks.isEmpty) {
        setState(() {
          _error = 'No tasks generated from selected text range.';
          _isLoading = false;
        });
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _TextRangeLessonPage(
            lesson: response,
            title: title,
            refStart: refStart,
            refEnd: refEnd,
          ),
        ),
      );
    } on LessonApiException catch (error) {
      if (!mounted) return;

      // Provide helpful message for errors
      String userMessage = error.message;

      setState(() {
        _error = userMessage;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to generate lesson: ${error.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final featuredRange = _textRanges.first;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Classical text library'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: VibrantBackground(
          child: SafeArea(
            child: Stack(
            children: [
              AbsorbPointer(
                absorbing: _isLoading,
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    VibrantSpacing.lg,
                    VibrantSpacing.lg,
                    VibrantSpacing.lg,
                    VibrantSpacing.xxxl,
                  ),
                  children: [
                    PulseCard(
                      gradient: VibrantTheme.heroGradient,
                      padding: const EdgeInsets.all(VibrantSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Curated Homeric passages',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.sm),
                          Text(
                            'Jump into legendary lines with vocabulary scaffolding ready to go. Generate a lesson in seconds.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.md),
                          Wrap(
                            spacing: VibrantSpacing.sm,
                            runSpacing: VibrantSpacing.sm,
                            children: const [
                              _LibraryBadge(
                                icon: Icons.auto_graph_outlined,
                                label: 'Adaptive difficulty',
                              ),
                              _LibraryBadge(
                                icon: Icons.menu_book_outlined,
                                label: 'LSJ & Smyth ready',
                              ),
                              _LibraryBadge(
                                icon: Icons.queue_play_next,
                                label: 'One-tap generation',
                              ),
                            ],
                          ),
                          const SizedBox(height: VibrantSpacing.lg),
                          TextButton.icon(
                            onPressed: _isLoading
                                ? null
                                : () => _generateFromRange(
                                    featuredRange['ref_start'] as String,
                                    featuredRange['ref_end'] as String,
                                    featuredRange['title'] as String,
                                  ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: VibrantSpacing.lg,
                                vertical: VibrantSpacing.sm,
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  VibrantRadius.lg,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Start with the proem'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xl),
                    if (_error != null)
                      PulseCard(
                        color: colorScheme.errorContainer,
                        padding: const EdgeInsets.all(VibrantSpacing.lg),
                        margin: const EdgeInsets.only(
                          bottom: VibrantSpacing.md,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: colorScheme.error),
                            SizedBox(width: VibrantSpacing.sm),
                            Expanded(
                              child: Text(
                                _error!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onErrorContainer
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SectionHeader(
                      title: 'Featured excerpts',
                      subtitle:
                          'Hand-picked Iliad passages that showcase core grammar and vocabulary patterns.',
                      icon: Icons.collections_bookmark_outlined,
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    ..._textRanges.map(
                      (range) =>
                          _buildRangeCard(context: context, range: range),
                    ),
                  ],
                ),
              ),
              if (_isLoading) const _TextRangeLoadingOverlay(),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildRangeCard({
    required BuildContext context,
    required Map<String, String> range,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = range['title']!;
    final subtitle = range['subtitle']!;
    final refStart = range['ref_start']!;
    final refEnd = range['ref_end']!;

    return PulseCard(
      margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
      color: colorScheme.surface,
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      onTap: _isLoading
          ? null
          : () => _generateFromRange(refStart, refEnd, title),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: VibrantTheme.subtleGradient,
              borderRadius: BorderRadius.circular(VibrantRadius.md),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          SizedBox(width: VibrantSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$refStart -> $refEnd',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.outline),
        ],
      ),
    );
  }
}

class _LibraryBadge extends StatelessWidget {
  const _LibraryBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: VibrantSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextRangeLoadingOverlay extends StatelessWidget {
  const _TextRangeLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.45),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TextRangeLessonPage extends StatelessWidget {
  const _TextRangeLessonPage({
    required this.lesson,
    required this.title,
    required this.refStart,
    required this.refEnd,
  });

  final LessonResponse lesson;
  final String title;
  final String refStart;
  final String refEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: VibrantBackground(
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              VibrantSpacing.lg,
              VibrantSpacing.lg,
              VibrantSpacing.lg,
              VibrantSpacing.xxxl,
            ),
            children: [
              PulseCard(
                gradient: VibrantTheme.heroGradient,
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson ready!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      'Generated from $refStart -> $refEnd. Open the Lessons tab to practice the tailored exercises.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VibrantSpacing.xl),
              SectionHeader(
                title: 'What\'s inside',
                subtitle:
                    'This set includes ${lesson.tasks.length} adaptive exercises templated from your chosen passage.',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: VibrantSpacing.md),
              PulseCard(
                color: colorScheme.surface,
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${lesson.tasks.length} exercises',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.md,
                            vertical: VibrantSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(
                              VibrantRadius.md,
                            ),
                          ),
                          child: Text(
                            'Homeric Greek',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      'Return to the Lessons tab from the bottom navigation to run through the full experience with scoring, hints, and XP.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VibrantSpacing.xl),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.school),
                label: const Text('Open Lessons'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: VibrantSpacing.md,
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
