import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';
import 'loading_indicators.dart';

/// Engaging loading screen for lesson generation with cycling fun facts,
/// quirky phrases, and animated visuals.
class LessonLoadingScreen extends StatefulWidget {
  final String languageCode; // e.g., 'grc', 'lat', 'heb', 'san'

  const LessonLoadingScreen({
    super.key,
    required this.languageCode,
  });

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

    // Start cycling quirky text every 2 seconds
    _textCycleTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _currentTextIndex =
              (_currentTextIndex + 1) % _getQuirkyPhrases().length;
        });
      }
    });

    // Start cycling fun facts every 8 seconds
    _factCycleTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) {
        setState(() {
          _currentFactIndex =
              (_currentFactIndex + 1) % _getFunFacts().length;
        });
      }
    });

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

  List<String> _getQuirkyPhrases() {
    // Language-specific quirky phrases
    switch (widget.languageCode) {
      case 'grc': // Ancient Greek
        return [
          'ΣΥΛΛΟΓΙΖΟΜΑΙ... (Thinking...)',
          'ΔΗΜΙΟΥΡΓΩ... (Creating...)',
          'ΠΟΙΩ... (Making...)',
          'ΓΡΑΦΩ... (Writing...)',
          'ΕΥΡΙΣΚΩ... (Finding...)',
          'ΜΑΝΘΑΝΩ... (Learning...)',
          'ΔΙΔΑΣΚΩ... (Teaching...)',
          'ΣΟΦΙΖΟΜΑΙ... (Getting wise...)',
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
      case 'heb': // Hebrew
        return [
          'חושב... (Thinking...)',
          'יוצר... (Creating...)',
          'עושה... (Making...)',
          'כותב... (Writing...)',
          'מוצא... (Finding...)',
          'לומד... (Learning...)',
          'מלמד... (Teaching...)',
          'מתבונן... (Contemplating...)',
        ];
      case 'san': // Sanskrit
        return [
          'चिन्तयामि... (Thinking...)',
          'रचयामि... (Creating...)',
          'करोमि... (Making...)',
          'लिखामि... (Writing...)',
          'अन्विष्यामि... (Searching...)',
          'पठामि... (Learning...)',
          'शिक्षयामि... (Teaching...)',
          'ध्यायामि... (Meditating...)',
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

  List<Map<String, String>> _getFunFacts() {
    // Language-specific fun facts with categories
    switch (widget.languageCode) {
      case 'grc': // Ancient Greek
        return [
          {
            'fact': 'The Greek alphabet was derived from the Phoenician alphabet around 800 BCE, adding vowels for the first time.',
            'category': 'Linguistic',
          },
          {
            'fact': 'Homer\'s Iliad and Odyssey, composed around 750 BCE, are among the oldest works of Western literature.',
            'category': 'Historical',
          },
          {
            'fact': 'Ancient Greek had three genders (masculine, feminine, neuter), five cases, and optative mood for wishes.',
            'category': 'Linguistic',
          },
          {
            'fact': 'The Library of Alexandria, founded around 300 BCE, was the largest library of the ancient world.',
            'category': 'Historical',
          },
          {
            'fact': 'Greek philosophy gave us Socrates, Plato, and Aristotle, who shaped Western thought for millennia.',
            'category': 'Philosophical',
          },
          {
            'fact': 'The Olympic Games, begun in 776 BCE, were held in honor of Zeus at Olympia every four years.',
            'category': 'Historical',
          },
          {
            'fact': 'Ancient Greek drama invented tragedy and comedy, with playwrights like Sophocles and Aristophanes.',
            'category': 'Historical',
          },
          {
            'fact': 'The word "alphabet" comes from the first two Greek letters: alpha (α) and beta (β).',
            'category': 'Linguistic',
          },
          {
            'fact': 'Democracy was born in Athens around 508 BCE, meaning "rule by the people" (dēmokratia).',
            'category': 'Historical',
          },
          {
            'fact': 'Ancient Greek had pitch accent, not stress accent like Modern Greek or English.',
            'category': 'Linguistic',
          },
        ];

      case 'lat': // Latin
        return [
          {
            'fact': 'Latin was spoken by the ancient Romans and became the lingua franca of the Western world for over 1,000 years.',
            'category': 'Historical',
          },
          {
            'fact': 'The Roman Empire at its height (117 CE) stretched from Britain to Egypt, encompassing 5 million square kilometers.',
            'category': 'Historical',
          },
          {
            'fact': 'Latin has six cases: nominative, genitive, dative, accusative, ablative, and vocative.',
            'category': 'Linguistic',
          },
          {
            'fact': 'About 60% of English words are derived from Latin, especially in science, law, and medicine.',
            'category': 'Linguistic',
          },
          {
            'fact': 'The Aeneid, written by Virgil around 19 BCE, tells the legendary founding of Rome by Trojan hero Aeneas.',
            'category': 'Historical',
          },
          {
            'fact': 'Roman numerals are still used today: I, V, X, L, C, D, M represent 1, 5, 10, 50, 100, 500, 1000.',
            'category': 'Linguistic',
          },
          {
            'fact': 'Julius Caesar wrote his Gallic Wars commentary, providing firsthand accounts of Roman military campaigns.',
            'category': 'Historical',
          },
          {
            'fact': 'The Latin phrase "Veni, vidi, vici" (I came, I saw, I conquered) was Caesar\'s message after a quick victory.',
            'category': 'Historical',
          },
          {
            'fact': 'Latin had no articles (a, an, the), and word order was very flexible due to its case system.',
            'category': 'Linguistic',
          },
          {
            'fact': 'The Roman Forum was the center of political, religious, and social life in ancient Rome.',
            'category': 'Historical',
          },
        ];

      case 'heb': // Hebrew
        return [
          {
            'fact': 'Hebrew is written from right to left, and its alphabet has 22 letters, all consonants.',
            'category': 'Linguistic',
          },
          {
            'fact': 'The Dead Sea Scrolls, discovered in 1947, contain the oldest known Biblical Hebrew manuscripts (3rd century BCE).',
            'category': 'Historical',
          },
          {
            'fact': 'Hebrew was revived as a spoken language in the 19th-20th centuries, making it unique among ancient languages.',
            'category': 'Linguistic',
          },
          {
            'fact': 'The Hebrew Bible (Tanakh) comprises the Torah (Law), Nevi\'im (Prophets), and Ketuvim (Writings).',
            'category': 'Theological',
          },
          {
            'fact': 'In Hebrew, vowels were originally not written; vowel points (nikud) were added later by the Masoretes (6th-10th centuries CE).',
            'category': 'Linguistic',
          },
          {
            'fact': 'The name "Hebrew" (Ivrit) may derive from "Eber," an ancestor of Abraham, or from "ever" (beyond/across).',
            'category': 'Linguistic',
          },
          {
            'fact': 'Jerusalem, mentioned over 600 times in the Bible, has been a holy city for Judaism for over 3,000 years.',
            'category': 'Historical',
          },
          {
            'fact': 'Hebrew uses a root system: most words are built from 3-letter roots (like K-T-V for writing).',
            'category': 'Linguistic',
          },
          {
            'fact': 'The Shema ("Hear, O Israel") from Deuteronomy 6:4 is Judaism\'s most important prayer.',
            'category': 'Theological',
          },
          {
            'fact': 'Hebrew has no capital letters, and the same letters are used for both print and cursive writing.',
            'category': 'Linguistic',
          },
        ];

      case 'san': // Sanskrit
        return [
          {
            'fact': 'Sanskrit is one of the oldest Indo-European languages, with texts dating back to 1500 BCE (Rigveda).',
            'category': 'Historical',
          },
          {
            'fact': 'The word "Sanskrit" means "perfected" or "refined," distinguishing it from Prakrit ("natural") languages.',
            'category': 'Linguistic',
          },
          {
            'fact': 'Sanskrit has eight cases for nouns: nominative, accusative, instrumental, dative, ablative, genitive, locative, vocative.',
            'category': 'Linguistic',
          },
          {
            'fact': 'Panini\'s Ashtadhyayi (5th century BCE) is one of the earliest and most complete grammars of any language.',
            'category': 'Linguistic',
          },
          {
            'fact': 'The Vedas are the oldest sacred texts of Hinduism, composed in Vedic Sanskrit around 1500-500 BCE.',
            'category': 'Theological',
          },
          {
            'fact': 'Sanskrit uses the Devanagari script, meaning "script of the divine city," also used for Hindi and Marathi.',
            'category': 'Linguistic',
          },
          {
            'fact': 'The Bhagavad Gita, part of the Mahabharata epic, is a 700-verse Hindu scripture in Sanskrit.',
            'category': 'Theological',
          },
          {
            'fact': 'Sanskrit has complex sandhi (euphonic combination) rules that blend word endings with following word beginnings.',
            'category': 'Linguistic',
          },
          {
            'fact': 'Many English words derive from Sanskrit: "yoga," "karma," "mantra," "guru," "avatar," "nirvana."',
            'category': 'Linguistic',
          },
          {
            'fact': 'Sanskrit literature includes the world\'s longest epic poems: the Mahabharata (100,000 verses) and Ramayana (24,000 verses).',
            'category': 'Historical',
          },
        ];

      default:
        return [
          {
            'fact': 'Ancient languages preserve the history, culture, and thought of civilizations.',
            'category': 'General',
          },
          {
            'fact': 'Learning ancient languages helps you understand the roots of modern languages.',
            'category': 'General',
          },
        ];
    }
  }

  Widget _buildSpinningIcon(ColorScheme colorScheme) {
    // Language-specific icons (spinning)
    IconData icon;
    switch (widget.languageCode) {
      case 'grc':
        icon = Icons.school_rounded; // Scroll/academy icon for Greek philosophy
        break;
      case 'lat':
        icon = Icons.account_balance_rounded; // Roman temple/columns
        break;
      case 'heb':
        icon = Icons.menu_book_rounded; // Torah scroll/book
        break;
      case 'san':
        icon = Icons.spa_rounded; // Lotus/meditation icon for Sanskrit
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
        child: Icon(
          icon,
          size: 48,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final quirkyPhrases = _getQuirkyPhrases();
    final funFacts = _getFunFacts();

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
              'Generating your lesson...',
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
                'This may take a moment. Please stay on this screen and don\'t switch tabs while your lesson is being crafted.',
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
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
