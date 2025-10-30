import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;

import '../app_providers.dart';
import '../models/lesson.dart';
import '../services/byok_controller.dart';
import '../services/lesson_api.dart';
import '../services/haptic_service.dart';
import '../services/language_preferences.dart';
import '../models/language.dart';
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

class _TextRangeSuggestion {
  const _TextRangeSuggestion({
    required this.title,
    required this.subtitle,
    this.refStart,
    this.refEnd,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final String? refStart;
  final String? refEnd;
  final bool enabled;
}

class _TextRangePickerPageState extends frp.ConsumerState<TextRangePickerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const List<_TextRangeSuggestion> _greekRanges = [
    _TextRangeSuggestion(
      title: 'Iliad 1.1–1.10 (Proem)',
      subtitle: 'Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος',
      refStart: 'Il.1.1',
      refEnd: 'Il.1.10',
    ),
    _TextRangeSuggestion(
      title: 'Iliad 1.20–1.50 (Chryses)',
      subtitle: 'Χρύσην ἀρητῆρα Διὸς',
      refStart: 'Il.1.20',
      refEnd: 'Il.1.50',
    ),
    _TextRangeSuggestion(
      title: 'Iliad 1.50–1.100 (Apolloʼs wrath)',
      subtitle: 'ἔκλαγξαν δʼ ἄρʼ ὀϊστοὶ',
      refStart: 'Il.1.50',
      refEnd: 'Il.1.100',
    ),
    _TextRangeSuggestion(
      title: 'Iliad 1.100–1.200 (Assembly)',
      subtitle: 'ἀγορὴν δὲ καλέσσατο',
      refStart: 'Il.1.100',
      refEnd: 'Il.1.200',
    ),
    _TextRangeSuggestion(
      title: 'Iliad Book 1 (Complete)',
      subtitle: '611 lines of epic glory',
      refStart: 'Il.1.1',
      refEnd: 'Il.1.611',
    ),
  ];

  static const List<_TextRangeSuggestion> _koineRanges = [
    _TextRangeSuggestion(
      title: 'John 1:1–1:5 (Prologue)',
      subtitle: 'Ἐν ἀρχῇ ἦν ὁ λόγος…',
      refStart: 'Jn.1.1',
      refEnd: 'Jn.1.5',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Beatitudes (Matthew 5:3–10)',
      subtitle: 'Μακάριοι οἱ πτωχοὶ τῷ πνεύματι…',
      refStart: 'Mt.5.3',
      refEnd: 'Mt.5.10',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Acts 17:22–31 (Areopagus speech)',
      subtitle: 'Ἄνδρες Ἀθηναῖοι…',
      refStart: 'Ac.17.22',
      refEnd: 'Ac.17.31',
      enabled: false,
    ),
  ];

  static const List<_TextRangeSuggestion> _latinRanges = [
    _TextRangeSuggestion(
      title: 'Aeneid 1.1–1.11 (Invocation)',
      subtitle: 'Arma virumque canō…',
      refStart: 'Aen.1.1',
      refEnd: 'Aen.1.11',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Caesar, Bellum Gallicum 1.1–1.3',
      subtitle: 'Gallia est omnis dīvīsa in partēs trēs…',
      refStart: 'BG.1.1',
      refEnd: 'BG.1.3',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Cicero, In Catilinam 1.1–1.5',
      subtitle: 'Quō ūsque tandem abūtēre, Catilīna…',
      refStart: 'Cat.1.1',
      refEnd: 'Cat.1.5',
      enabled: false,
    ),
  ];

  static const List<_TextRangeSuggestion> _hebrewRanges = [
    _TextRangeSuggestion(
      title: 'Genesis 1:1–1:5 (Creation)',
      subtitle: 'בְּרֵאשִׁית בָּרָא אֱלֹהִים…',
      refStart: 'Gen.1.1',
      refEnd: 'Gen.1.5',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Psalm 23',
      subtitle: 'מִזְמוֹר לְדָוִד יְהוָה רֹעִי…',
      refStart: 'Ps.23.1',
      refEnd: 'Ps.23.6',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Deuteronomy 6:4–9 (Shema)',
      subtitle: 'שְׁמַע יִשְׂרָאֵל…',
      refStart: 'Deut.6.4',
      refEnd: 'Deut.6.9',
      enabled: false,
    ),
  ];

  static const List<_TextRangeSuggestion> _sanskritRanges = [
    _TextRangeSuggestion(
      title: 'Bhagavad Gita 1.1–1.10',
      subtitle: 'धर्मक्षेत्रे कुरुक्षेत्रे…',
      refStart: 'BGita.1.1',
      refEnd: 'BGita.1.10',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Ramayana 1.1–1.20',
      subtitle: 'तपःस्वाध्यायनिरतं…',
      refStart: 'Ram.1.1',
      refEnd: 'Ram.1.20',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Hitopadeśa (Friend and Crow)',
      subtitle: 'शिविराख्यो द्विजातिः…',
      enabled: false,
    ),
  ];

  static const List<_TextRangeSuggestion> _classicalChineseRanges = [
    _TextRangeSuggestion(
      title: 'Analects 1.1',
      subtitle: '子曰：「學而時習之，不亦說乎？」',
      refStart: 'Lunyu.1.1',
      refEnd: 'Lunyu.1.1',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Mencius 1A:1',
      subtitle: '孟子見梁惠王…',
      refStart: 'Mengzi.1A.1',
      refEnd: 'Mengzi.1A.1',
      enabled: false,
    ),
    _TextRangeSuggestion(
      title: 'Dao De Jing 1',
      subtitle: '道可道，非常道；名可名，非常名。',
      refStart: 'DDJ.1',
      refEnd: 'DDJ.1',
      enabled: false,
    ),
  ];

  final Map<String, List<_TextRangeSuggestion>> _rangeCatalog = {
    'grc-cls': _greekRanges,
    'grc-koi': _koineRanges,
    'lat': _latinRanges,
    'hbo': _hebrewRanges,
    'san': _sanskritRanges,
    'lzh': _classicalChineseRanges,
  };

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
      final languageCode = ref.read(selectedLanguageProvider);
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
        language: languageCode,
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

  List<_TextRangeSuggestion> _comingSoonSuggestions(LanguageInfo languageInfo) {
    return [
      _TextRangeSuggestion(
        title: 'Curated passages coming soon',
        subtitle: 'Lessons for ${languageInfo.name} will be available shortly',
        enabled: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCode = ref.watch(selectedLanguageProvider);
    final languageInfo = availableLanguages.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => availableLanguages.first,
    );
    final languageName = languageInfo.name;
    final suggestions = _rangeCatalog[languageCode];
    final suggestionList = (suggestions != null && suggestions.isNotEmpty)
        ? suggestions
        : _comingSoonSuggestions(languageInfo);
    final primarySuggestion = suggestionList.first;
    final generationSupported =
        primarySuggestion.enabled &&
        primarySuggestion.refStart != null &&
        primarySuggestion.refEnd != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Curated passages • $languageName'),
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
                              'Curated passages for $languageName',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.sm),
                            Text(
                              generationSupported
                                  ? 'Jump into curated lines with vocabulary scaffolding ready to go. Generate a lesson in seconds.'
                                  : 'Lesson templates for $languageName are in active development. Explore the Reader while we finish the generator.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.md),
                            Wrap(
                              spacing: VibrantSpacing.sm,
                              runSpacing: VibrantSpacing.sm,
                              children: generationSupported
                                  ? const [
                                      _LibraryBadge(
                                        icon: Icons.auto_graph_outlined,
                                        label: 'Adaptive difficulty',
                                      ),
                                      _LibraryBadge(
                                        icon: Icons.menu_book_outlined,
                                        label: 'Lexicon ready',
                                      ),
                                      _LibraryBadge(
                                        icon: Icons.queue_play_next,
                                        label: 'One-tap generation',
                                      ),
                                    ]
                                  : const [
                                      _LibraryBadge(
                                        icon: Icons.menu_book_outlined,
                                        label: 'Reader library ready',
                                      ),
                                      _LibraryBadge(
                                        icon: Icons.timer_outlined,
                                        label: 'Lessons coming soon',
                                      ),
                                      _LibraryBadge(
                                        icon: Icons.feedback_outlined,
                                        label: 'Share feedback in Settings',
                                      ),
                                    ],
                            ),
                            const SizedBox(height: VibrantSpacing.lg),
                            TextButton.icon(
                              onPressed: !_isLoading && generationSupported
                                  ? () => _generateFromRange(
                                      primarySuggestion.refStart!,
                                      primarySuggestion.refEnd!,
                                      primarySuggestion.title,
                                    )
                                  : null,
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
                              icon: Icon(
                                generationSupported
                                    ? Icons.play_arrow_rounded
                                    : Icons.lock_clock_outlined,
                              ),
                              label: Text(
                                generationSupported
                                    ? 'Generate sample lesson'
                                    : 'Lessons coming soon',
                              ),
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
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                              ),
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
                        subtitle: generationSupported
                            ? 'Hand-picked passages that showcase core grammar and vocabulary patterns in $languageName.'
                            : 'Preview passages from $languageName. Lesson generation will unlock soon.',
                        icon: Icons.collections_bookmark_outlined,
                      ),
                      const SizedBox(height: VibrantSpacing.md),
                      ...suggestionList.map(
                        (suggestion) => _buildRangeCard(
                          context: context,
                          suggestion: suggestion,
                        ),
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
    required _TextRangeSuggestion suggestion,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled =
        suggestion.enabled &&
        suggestion.refStart != null &&
        suggestion.refEnd != null &&
        !_isLoading;

    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: PulseCard(
        margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
        color: colorScheme.surface,
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        onTap: enabled
            ? () => _generateFromRange(
                suggestion.refStart!,
                suggestion.refEnd!,
                suggestion.title,
              )
            : null,
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
                    suggestion.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    suggestion.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (enabled) ...[
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
                          '${suggestion.refStart} → ${suggestion.refEnd}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: VibrantSpacing.sm),
                    Chip(
                      avatar: const Icon(Icons.lock_clock_outlined, size: 14),
                      label: const Text('Coming soon'),
                      backgroundColor: colorScheme.secondaryContainer
                          .withValues(alpha: 0.4),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 18, color: colorScheme.outline),
          ],
        ),
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
