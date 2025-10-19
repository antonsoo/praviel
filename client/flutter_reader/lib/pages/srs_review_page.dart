import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/srs_api.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/premium_buttons.dart';
import '../widgets/premium_snackbars.dart';
import 'package:confetti/confetti.dart';

/// SRS Flashcard Review Screen - Beautiful, addictive review experience
class SrsReviewPage extends ConsumerStatefulWidget {
  const SrsReviewPage({super.key, required this.srsApi, this.deck});

  final SrsApi srsApi;
  final String? deck;

  @override
  ConsumerState<SrsReviewPage> createState() => _SrsReviewPageState();
}

class _SrsReviewPageState extends ConsumerState<SrsReviewPage>
    with SingleTickerProviderStateMixin {
  List<SrsCard> _dueCards = [];
  int _currentIndex = 0;
  bool _showingBack = false;
  bool _loading = true;
  String? _error;
  int _reviewedCount = 0;
  int _totalXpEarned = 0;
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _loadDueCards();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadDueCards() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cards = await widget.srsApi.getDueCards(
        deck: widget.deck,
        limit: 20,
      );

      setState(() {
        _dueCards = cards;
        _loading = false;
        _currentIndex = 0;
        _showingBack = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load cards: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submitReview(int quality) async {
    if (_currentIndex >= _dueCards.length) return;

    final card = _dueCards[_currentIndex];

    try {
      HapticService.medium();

      // Submit review
      await widget.srsApi.reviewCard(cardId: card.id, quality: quality);

      // Calculate XP earned (based on quality)
      final xpEarned = {1: 5, 2: 8, 3: 12, 4: 15}[quality] ?? 10;
      _totalXpEarned += xpEarned;
      _reviewedCount++;

      // Show confetti for Good/Easy
      if (quality >= 3) {
        _confettiController.play();
      }

      // Move to next card
      setState(() {
        _currentIndex++;
        _showingBack = false;
      });

      // Reset flip animation
      _flipController.reset();
    } catch (e) {
      if (mounted) {
        PremiumSnackBar.error(
          context,
          title: 'Review Failed',
          message: 'Could not submit review: $e',
        );
      }
    }
  }

  void _flipCard() {
    HapticService.light();
    setState(() {
      _showingBack = !_showingBack;
    });

    if (_showingBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.deck != null ? '${widget.deck} Review' : 'SRS Review',
        ),
        actions: [
          // Progress indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$_reviewedCount reviewed • $_totalXpEarned XP',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          _buildBody(theme, colorScheme),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            PremiumButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: () {
                HapticService.medium();
                _loadDueCards();
              },
            ),
          ],
        ),
      );
    }

    if (_dueCards.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    if (_currentIndex >= _dueCards.length) {
      return _buildCompletionState(theme, colorScheme);
    }

    return _buildReviewCard(theme, colorScheme);
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'No cards due!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Come back later for more reviews',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          PremiumButton(
            label: 'Back to Decks',
            icon: Icons.arrow_back_rounded,
            onPressed: () {
              HapticService.medium();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SlideInFromBottom(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Review Complete!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PulseCard(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '$_reviewedCount',
                      style: theme.textTheme.displayLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text('Cards Reviewed', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Text(
                      '+$_totalXpEarned XP',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PremiumButton(
                  label: 'Review More',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    HapticService.medium();
                    _loadDueCards();
                  },
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    HapticService.medium();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme, ColorScheme colorScheme) {
    final card = _dueCards[_currentIndex];
    final cardsRemaining = _dueCards.length - _currentIndex;

    return Column(
      children: [
        // Progress bar
        SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            value: _currentIndex / _dueCards.length,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ),

        // Card count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '$cardsRemaining cards remaining',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Flashcard
                  GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value * 3.14159;
                        final isBack = angle > 1.5708;

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(angle),
                          alignment: Alignment.center,
                          child: Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(
                              minHeight: 300,
                              maxHeight: 400,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isBack
                                    ? [
                                        colorScheme.secondary,
                                        colorScheme.secondary.withValues(
                                          alpha: 0.8,
                                        ),
                                      ]
                                    : [
                                        colorScheme.primary,
                                        colorScheme.primary.withValues(
                                          alpha: 0.8,
                                        ),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Transform(
                                transform: Matrix4.identity()
                                  ..rotateX(isBack ? 3.14159 : 0),
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    isBack ? card.back : card.front,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Tap to reveal hint
                  if (!_showingBack)
                    Text(
                      'Tap card to reveal answer',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                  // Review buttons (only show when answer is revealed)
                  if (_showingBack) ...[
                    const SizedBox(height: 16),
                    _buildReviewButtons(theme, colorScheme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewButtons(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReviewButton(
                label: 'Again',
                subtitle: '<1 min',
                color: colorScheme.error,
                onPressed: () => _submitReview(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReviewButton(
                label: 'Hard',
                subtitle: '<10 min',
                color: Colors.orange,
                onPressed: () => _submitReview(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ReviewButton(
                label: 'Good',
                subtitle: '1 day',
                color: colorScheme.primary,
                onPressed: () => _submitReview(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ReviewButton(
                label: 'Easy',
                subtitle: '4 days',
                color: Colors.green,
                onPressed: () => _submitReview(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Review button with label and next interval
class _ReviewButton extends StatelessWidget {
  const _ReviewButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
