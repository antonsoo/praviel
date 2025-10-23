import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../features/gamification/presentation/providers/gamification_providers.dart';
import '../widgets/reader/enhanced_text_display.dart';
import '../widgets/quiz/comprehension_quiz.dart';

/// Professional reader page with immersive reading experience
/// Follows Material Design 3 reading best practices and e-reader patterns
class EnhancedReaderPage extends ConsumerStatefulWidget {
  const EnhancedReaderPage({
    super.key,
    required this.passageId,
    required this.title,
    required this.reference,
    required this.text,
    required this.translation,
    required this.languageCode,
  });

  final String passageId;
  final String title;
  final String reference;
  final String text;
  final String? translation;
  final String languageCode;

  @override
  ConsumerState<EnhancedReaderPage> createState() => _EnhancedReaderPageState();
}

class _EnhancedReaderPageState extends ConsumerState<EnhancedReaderPage>
    with TickerProviderStateMixin {
  bool _showTranslation = false;
  bool _showGrammarHints = true;
  bool _isFullscreen = false;
  double _fontSize = 18.0;
  int _wordsRead = 0;
  late DateTime _startTime;
  late AnimationController _toolbarController;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    _toolbarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _toolbarController.forward();
  }

  @override
  void dispose() {
    _completeReading();
    _toolbarController.dispose();
    super.dispose();
  }

  Future<void> _completeReading() async {
    final minutesStudied = DateTime.now().difference(_startTime).inMinutes;
    if (minutesStudied < 1) return; // Ignore very short sessions

    final controller = ref.read(gamificationControllerProvider);
    try {
      await controller.completeLesson(
        languageCode: widget.languageCode,
        xpEarned: 25, // Base XP for reading
        wordsLearned: _wordsRead ~/ 10, // Estimate new words learned
        minutesStudied: minutesStudied,
      );
    } catch (e) {
      debugPrint('Failed to save reading progress: $e');
    }
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        _toolbarController.reverse();
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        _toolbarController.forward();
      }
    });
    HapticService.light();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Main reading area
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App bar (hidden in fullscreen)
              if (!_isFullscreen)
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.reference,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded),
                      onPressed: _toggleFullscreen,
                      tooltip: 'Fullscreen',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_outline_rounded),
                      onPressed: () {
                        HapticService.light();
                        SoundService.instance.tap();
                        // TODO: Bookmark passage
                      },
                      tooltip: 'Bookmark',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      onPressed: () {
                        HapticService.light();
                        SoundService.instance.tap();
                        // TODO: Share passage
                      },
                      tooltip: 'Share',
                    ),
                  ],
                ),

              // Reading content
              SliverPadding(
                padding: EdgeInsets.all(
                  _isFullscreen ? VibrantSpacing.xl : VibrantSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: EnhancedTextDisplay(
                    text: widget.text,
                    translation: widget.translation,
                    languageCode: widget.languageCode,
                    showTranslation: _showTranslation,
                    showGrammarHints: _showGrammarHints,
                    fontSize: _fontSize,
                    onWordTap: (word, index) {
                      setState(() => _wordsRead++);
                      HapticService.light();
                      SoundService.instance.tap();
                      // Word tap handled by EnhancedTextDisplay
                    },
                  )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.05, end: 0),
                ),
              ),

              // Bottom spacing for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),

          // Floating toolbar (bottom)
          if (!_isFullscreen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _toolbarController,
                  curve: Curves.easeOut,
                )),
                child: _ReaderToolbar(
                  showTranslation: _showTranslation,
                  showGrammarHints: _showGrammarHints,
                  fontSize: _fontSize,
                  onToggleTranslation: () {
                    setState(() => _showTranslation = !_showTranslation);
                    HapticService.light();
                    SoundService.instance.tap();
                  },
                  onToggleGrammarHints: () {
                    setState(() => _showGrammarHints = !_showGrammarHints);
                    HapticService.light();
                    SoundService.instance.tap();
                  },
                  onFontSizeChanged: (size) {
                    setState(() => _fontSize = size);
                    HapticService.light();
                  },
                  onQuizTap: () {
                    _showQuizBottomSheet();
                  },
                ),
              ),
            ),

          // Fullscreen tap to show/hide controls
          if (_isFullscreen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleFullscreen,
                behavior: HitTestBehavior.translucent,
                child: Container(),
              ),
            ),
        ],
      ),
    );
  }

  void _showQuizBottomSheet() {
    HapticService.medium();
    SoundService.instance.tap();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VibrantRadius.xl),
            ),
          ),
          child: ComprehensionQuiz(
            questions: _generateMockQuestions(),
            onComplete: (result) {
              Navigator.pop(context);
              _showQuizResults(result);
            },
            passageTitle: widget.title,
            passageReference: widget.reference,
          ),
        ),
      ),
    );
  }

  void _showQuizResults(QuizResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Complete!'),
        content: QuizResultsScreen(
          result: result,
          onRetry: () {
            Navigator.pop(context);
            _showQuizBottomSheet();
          },
          onContinue: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  List<QuizQuestion> _generateMockQuestions() {
    // TODO: Generate real questions from passage analysis
    return [
      QuizQuestion(
        id: '1',
        type: QuestionType.multipleChoice,
        difficulty: QuestionDifficulty.medium,
        question: 'What is the main theme of this passage?',
        options: [
          'Love and relationships',
          'War and conflict',
          'Philosophy and wisdom',
          'Nature and beauty',
        ],
        correctAnswer: 'Philosophy and wisdom',
        explanation:
            'The passage discusses fundamental questions about knowledge and truth.',
        points: 10,
      ),
      QuizQuestion(
        id: '2',
        type: QuestionType.multipleChoice,
        difficulty: QuestionDifficulty.hard,
        question: 'Which grammatical construction is used in the first sentence?',
        options: [
          'Ablative absolute',
          'Accusative with infinitive',
          'Genitive absolute',
          'Dative of possession',
        ],
        correctAnswer: 'Accusative with infinitive',
        explanation:
            'The accusative with infinitive is a common Latin construction for indirect discourse.',
        hint: 'Look for an infinitive verb with an accusative subject.',
        points: 15,
      ),
    ];
  }
}

/// Reader toolbar with reading controls
class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.showTranslation,
    required this.showGrammarHints,
    required this.fontSize,
    required this.onToggleTranslation,
    required this.onToggleGrammarHints,
    required this.onFontSizeChanged,
    required this.onQuizTap,
  });

  final bool showTranslation;
  final bool showGrammarHints;
  final double fontSize;
  final VoidCallback onToggleTranslation;
  final VoidCallback onToggleGrammarHints;
  final Function(double) onFontSizeChanged;
  final VoidCallback onQuizTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Font size slider
            Row(
              children: [
                Icon(
                  Icons.text_fields_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                Expanded(
                  child: Slider(
                    value: fontSize,
                    min: 12.0,
                    max: 32.0,
                    divisions: 10,
                    label: fontSize.round().toString(),
                    onChanged: onFontSizeChanged,
                  ),
                ),
                Text(
                  '${fontSize.round()}',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),

            const SizedBox(height: VibrantSpacing.sm),

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolbarButton(
                  icon: Icons.translate_rounded,
                  label: 'Translation',
                  isActive: showTranslation,
                  onTap: onToggleTranslation,
                ),
                _ToolbarButton(
                  icon: Icons.auto_stories_rounded,
                  label: 'Grammar',
                  isActive: showGrammarHints,
                  onTap: onToggleGrammarHints,
                ),
                _ToolbarButton(
                  icon: Icons.quiz_rounded,
                  label: 'Quiz',
                  isActive: false,
                  onTap: onQuizTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: VibrantSpacing.md,
            vertical: VibrantSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: isActive ? VibrantTheme.heroGradient : null,
            color: isActive ? null : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(VibrantRadius.md),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
