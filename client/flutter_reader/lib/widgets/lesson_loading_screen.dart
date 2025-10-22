import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';
import 'loading_indicators.dart';
import '../services/fun_fact_catalog.dart';

/// Engaging loading screen for lesson generation with cycling fun facts,
/// quirky phrases, and animated visuals.
class LessonLoadingScreen extends StatefulWidget {
  const LessonLoadingScreen({
    super.key,
    required this.languageCode,
    this.headline = 'Generating your lesson...',
    this.statusMessage =
        "This may take a moment. Please stay on this screen and don't switch tabs while your lesson is being crafted.",
    this.quirkyInterval = const Duration(seconds: 5),
    this.funFactInterval = const Duration(seconds: 30), // Increased from 20s to give more reading time
    this.enableFactControls = true,
  });

  final String languageCode; // e.g., 'grc', 'lat', 'hbo', 'san'
  final String headline;
  final String statusMessage;
  final Duration quirkyInterval;
  final Duration funFactInterval;
  final bool enableFactControls;

  @override
  State<LessonLoadingScreen> createState() => _LessonLoadingScreenState();
}

class _LessonLoadingScreenState extends State<LessonLoadingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _textCycleTimer;
  Timer? _factCycleTimer;
  int _currentTextIndex = 0;
  int _currentFactIndex = 0;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();

    _startQuirkyTimer();
    _startFactTimer();

    // Spinning animation controller
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _textCycleTimer?.cancel();
    _factCycleTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  bool _isZeroOrNegative(Duration duration) =>
      duration.inMilliseconds <= 0;

  void _startQuirkyTimer() {
    _textCycleTimer?.cancel();
    if (_isZeroOrNegative(widget.quirkyInterval)) {
      return;
    }
    _textCycleTimer = Timer.periodic(widget.quirkyInterval, (_) {
      if (!mounted) return;
      setState(() {
        _currentTextIndex =
            (_currentTextIndex + 1) % _getQuirkyPhrases().length;
      });
    });
  }

  void _startFactTimer() {
    _factCycleTimer?.cancel();
    if (_isZeroOrNegative(widget.funFactInterval)) {
      return;
    }
    final facts = FunFactCatalog.factsForLanguage(widget.languageCode);
    if (facts.isEmpty) {
      return;
    }
    _factCycleTimer = Timer.periodic(widget.funFactInterval, (_) {
      if (!mounted) return;
      setState(() {
        final currentFacts =
            FunFactCatalog.factsForLanguage(widget.languageCode);
        if (currentFacts.isEmpty) return;
        _currentFactIndex =
            (_currentFactIndex + 1) % currentFacts.length;
      });
    });
  }

  void _advanceFact(int delta) {
    final facts = FunFactCatalog.factsForLanguage(widget.languageCode);
    if (facts.isEmpty) return;
    setState(() {
      final next = _currentFactIndex + delta;
      _currentFactIndex = (next % facts.length + facts.length) % facts.length;
    });
    if (!_isZeroOrNegative(widget.funFactInterval)) {
      _startFactTimer();
    }
  }

  List<String> _getQuirkyPhrases() {
    switch (widget.languageCode) {
      case 'grc': // Classical Greek
        return [
          'νοεῖ... (Thinking...)',
          'ποιεῖ... (Creating...)',
          'γράφει... (Writing...)',
          'εὑρίσκει... (Finding...)',
          'μανθάνει... (Learning...)',
          'διδάσκει... (Teaching...)',
          'φωτίζει... (Illuminating...)',
          'σοφίζεται... (Growing wise...)',
        ];
      case 'grc-koi': // Koine Greek
        return [
          'κοινῇ... (In Koine...)',
          'συντιθεῖ... (Composing...)',
          'λογίζεται... (Reasoning...)',
          'γράφει... (Scribing papyri...)',
          'ζητεῖ... (Searching...)',
          'κατηχεῖ... (Teaching...)',
          'μελετᾷ... (Studying...)',
          'φωτίζει... (Illuminating...)',
        ];
      case 'lat': // Latin
        return [
          'COGITO... (Thinking...)',
          'CREO... (Creating...)',
          'FACIO... (Making...)',
          'SCRIBO... (Writing...)',
          'INVENIO... (Finding...)',
          'DISCO... (Learning...)',
          'DOCEO... (Teaching...)',
          'MEDITOR... (Meditating...)',
        ];
      case 'hbo': // Biblical Hebrew
        return [
          'חושב... (Thinking...)',
          'יוצר... (Creating...)',
          'כותב... (Writing...)',
          'מוצא... (Finding...)',
          'לומד... (Learning...)',
          'מלמד... (Teaching...)',
          'חוקר... (Exploring...)',
          'מאיר... (Illuminating...)',
        ];
      case 'san': // Classical Sanskrit
        return [
          'चिन्तयामि... (Thinking...)',
          'निर्मिमि... (Creating...)',
          'लेखामि... (Writing...)',
          'अन्वेषये... (Seeking...)',
          'अधीयेत... (Learning...)',
          'उपदिशामि... (Teaching...)',
          'ध्यायामि... (Meditating...)',
          'प्रकाशयामि... (Illuminating...)',
        ];
      case 'lzh': // Classical Chinese
        return [
          '思惟中… (Thinking...)',
          '著書中… (Composing...)',
          '講義中… (Explaining...)',
          '尋義中… (Seeking meaning...)',
          '習讀中… (Studying...)',
          '編纂中… (Compiling...)',
          '磨筆中… (Sharpening the brush...)',
          '推敲中… (Refining phrases...)',
        ];
      case 'pli': // Pali
        return [
          'cintemi... (Thinking...)',
          'karomi... (Creating...)',
          'likhāmi... (Writing...)',
          'vindāmi... (Finding...)',
          'sikkhāmi... (Learning...)',
          'desemi... (Teaching...)',
          'bhāvemi... (Meditating...)',
          'passāmi... (Seeing clearly...)',
        ];
      case 'cu': // Old Church Slavonic
        return [
          'мыслю... (Thinking...)',
          'творю... (Creating...)',
          'пишю... (Writing...)',
          'обрѣтѭ... (Finding...)',
          'учѫ... (Learning...)',
          'научаю... (Teaching...)',
          'разумляю... (Reasoning...)',
          'свѣщаю... (Illuminating...)',
        ];
      case 'arc': // Ancient Aramaic (Imperial)
        return [
          'meḥašvīn... (Thinking...)',
          'bārīn... (Creating...)',
          'kāṯvīn... (Writing...)',
          'baḥqīn... (Investigating...)',
          'yelapīn... (Learning...)',
          'malpīn... (Teaching...)',
          'mešaqīn... (Exploring...)',
          'nūrīn... (Illuminating...)',
        ];
      case 'ara': // Classical Arabic
        return [
          'يفكّر... (Thinking...)',
          'يبدع... (Creating...)',
          'يكتب... (Writing...)',
          'يستكشف... (Exploring...)',
          'يتعلّم... (Learning...)',
          'يعلّم... (Teaching...)',
          'يتأمّل... (Meditating...)',
          'ينير... (Illuminating...)',
        ];
      default:
        return [
          'Thinking...',
          'Creating...',
          'Generating...',
          'Processing...',
          'Crafting your lesson...',
          'Working on it...',
        ];
    }
  }

  Widget _buildSpinningIcon(ColorScheme colorScheme) {
    // Language-specific icons (spinning)
    IconData icon;
    switch (widget.languageCode) {
      case 'grc':
      case 'grc-koi':
        icon = Icons.school_rounded; // Greek philosophy & Koine study
        break;
      case 'lat':
        icon = Icons.account_balance_rounded; // Roman temple/columns
        break;
      case 'hbo':
        icon = Icons.menu_book_rounded; // Torah scroll/book
        break;
      case 'san':
        icon = Icons.spa_rounded; // Lotus/meditation icon for Sanskrit
        break;
      case 'lzh':
        icon = Icons.brush_rounded; // Calligraphy brush for Classical Chinese
        break;
      case 'pli':
        icon = Icons.self_improvement; // Meditative posture for Pali chanting
        break;
      case 'cu':
        icon = Icons.church; // Slavic liturgical heritage
        break;
      case 'arc':
        icon = Icons.history_edu_rounded; // Imperial Aramaic scrolls
        break;
      case 'ara':
        icon = Icons.auto_stories_rounded; // Classical Arabic manuscript
        break;
      default:
        icon = Icons.auto_awesome_rounded;
    }

    return RotationTransition(
      turns: _spinController,
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        decoration: BoxDecoration(
          gradient: VibrantTheme.heroGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Icon(icon, size: 48, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final quirkyPhrases = _getQuirkyPhrases();
    final funFacts = FunFactCatalog.factsForLanguage(widget.languageCode);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Spinning language-specific icon
            _buildSpinningIcon(colorScheme),

            const SizedBox(height: VibrantSpacing.xl),

            // Main title
            Text(
              widget.headline,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: VibrantSpacing.md),

            // Persistent message asking users to stay
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.lg,
                vertical: VibrantSpacing.md,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                widget.statusMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: VibrantSpacing.lg),

            // Cycling quirky text in target language
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                quirkyPhrases[_currentTextIndex],
                key: ValueKey(_currentTextIndex),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: VibrantSpacing.lg),

            // Progress bar
            const SizedBox(
              width: 200,
              child: GradientProgressBar(
                progress: 0.5,
                gradient: VibrantTheme.heroGradient,
                height: 4,
              ),
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            // Fun fact section
            Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fun fact header with category badge
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: VibrantSpacing.sm),
                      Text(
                        'Did you know?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      // Category badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          funFacts[_currentFactIndex]['category'] ?? '',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: VibrantSpacing.md),

                  // Fun fact text (animated transition)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      funFacts[_currentFactIndex]['fact'] ?? '',
                      key: ValueKey(_currentFactIndex),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  if (widget.enableFactControls)
                    Padding(
                      padding: const EdgeInsets.only(top: VibrantSpacing.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Previous fact',
                            onPressed: () => _advanceFact(-1),
                            icon: const Icon(Icons.chevron_left_rounded),
                          ),
                          IconButton(
                            tooltip: 'Next fact',
                            onPressed: () => _advanceFact(1),
                            icon: const Icon(Icons.chevron_right_rounded),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
