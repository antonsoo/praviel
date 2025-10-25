import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/vocabulary/smart_vocabulary_card.dart';
import '../services/haptic_service.dart';
import '../services/sound_service.dart';
import '../services/srs_api.dart';
import '../widgets/premium_snackbars.dart';

/// Vocabulary review page with SRS flashcards
/// Shows due cards first, allows users to rate their recall
class VocabularyReviewPage extends ConsumerStatefulWidget {
  const VocabularyReviewPage({super.key});

  @override
  ConsumerState<VocabularyReviewPage> createState() =>
      _VocabularyReviewPageState();
}

class _VocabularyReviewPageState extends ConsumerState<VocabularyReviewPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentCardIndex = 0;
  int _reviewedCount = 0;
  int _totalReviewed = 0;
  List<SrsCard>? _dueCards;
  bool _isLoading = true;
  String? _error;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    _loadDueCards();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadDueCards() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final srsApi = ref.read(srsApiProvider);
      final cards = await srsApi.getDueCards(limit: 20);

      if (mounted) {
        setState(() {
          _dueCards = cards;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRating(int rating, int cardId) async {
    HapticService.medium();

    // Update SRS data in backend
    final srsApi = ref.read(srsApiProvider);
    try {
      await srsApi.reviewCard(cardId: cardId, quality: rating);

      setState(() {
        _reviewedCount++;
        _totalReviewed++;
      });

      // Show encouraging message
      if (rating >= 3) {
        if (mounted) {
          PremiumSnackBar.success(
            context,
            message: rating == 4 ? 'Excellent! 🎯' : 'Great job! ✨',
          );
        }
      }

      // Move to next card
      if (_currentCardIndex < (_dueCards?.length ?? 1) - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Session complete
        _showSessionComplete();
      }
    } catch (e) {
      if (mounted) {
        PremiumSnackBar.error(
          context,
          message: 'Failed to save review: $e',
        );
      }
    }
  }

  void _showSessionComplete() {
    HapticService.heavy();
    SoundService.instance.levelUp();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SessionCompleteDialog(
        reviewedCount: _totalReviewed,
        onContinue: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(); // Return to previous page
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vocabulary Review')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vocabulary Review')),
        body: _buildErrorView(theme, colorScheme),
      );
    }

    final dueCards = _dueCards ?? [];

    if (dueCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vocabulary Review')),
        body: _buildNoCardsView(theme, colorScheme),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary Review'),
        actions: [
          // Progress indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$_reviewedCount / ${dueCards.length}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Progress bar
            LinearProgressIndicator(
            value: dueCards.isEmpty ? 0 : _reviewedCount / dueCards.length,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),

          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe
              onPageChanged: (index) {
                setState(() {
                  _currentCardIndex = index;
                });
              },
              itemCount: dueCards.length,
              itemBuilder: (context, index) {
                final card = dueCards[index];
                return Padding(
                  padding: const EdgeInsets.all(VibrantSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SmartVocabularyCard(
                        word: card.front,
                        definition: card.back,
                        example: 'Review this word to see it in context',
                        difficulty: card.difficulty.round().clamp(1, 5),
                        onRatingSelected: (rating) {
                          _handleRating(rating, card.id);
                        },
                      ),

                      const SizedBox(height: VibrantSpacing.xl),

                      // Skip button
                      TextButton.icon(
                        onPressed: () {
                          if (_currentCardIndex < dueCards.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Skip for now'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildErrorView(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'Failed to load vocabulary',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: VibrantSpacing.md),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xl),
            FilledButton.icon(
              onPressed: _loadDueCards,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCardsView(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.xxl),
              decoration: BoxDecoration(
                gradient: VibrantTheme.heroGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 80,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            Text(
              'All caught up!',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: VibrantSpacing.md),

            Text(
              'You have no vocabulary cards due for review right now. Come back later or learn new words in lessons.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.school_rounded),
              label: const Text('Start a Lesson'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionCompleteDialog extends StatelessWidget {
  const _SessionCompleteDialog({
    required this.reviewedCount,
    required this.onContinue,
  });

  final int reviewedCount;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              decoration: BoxDecoration(
                gradient: VibrantTheme.heroGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: VibrantSpacing.lg),

            Text(
              'Session Complete!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: VibrantSpacing.md),

            Text(
              'You reviewed $reviewedCount word${reviewedCount != 1 ? 's' : ''}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: VibrantSpacing.xl),

            FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
