import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import '../effects/confetti_overlay.dart';
import '../effects/particle_effects.dart';

/// Epic bottom sheet that slides up after lesson completion
/// Shows XP earned, stars, badges unlocked, level up, etc.
class EpicResultsModal extends StatefulWidget {
  const EpicResultsModal({
    super.key,
    required this.totalXP,
    required this.correctCount,
    required this.totalQuestions,
    required this.newBadges,
    required this.leveledUp,
    required this.newLevel,
    this.longestCombo = 0,
    this.coinsEarned = 0,
    this.wordsLearned = 0,
    this.onContinueLearning,
  });

  final int totalXP;
  final int correctCount;
  final int totalQuestions;
  final List<String> newBadges; // Badge names/IDs
  final bool leveledUp;
  final int newLevel;
  final int longestCombo;
  final int coinsEarned;
  final int wordsLearned;
  final VoidCallback? onContinueLearning;

  static Future<void> show(
    BuildContext context, {
    required int totalXP,
    required int correctCount,
    required int totalQuestions,
    List<String> newBadges = const [],
    bool leveledUp = false,
    int newLevel = 1,
    int longestCombo = 0,
    int coinsEarned = 0,
    int wordsLearned = 0,
    VoidCallback? onContinueLearning,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => EpicResultsModal(
        totalXP: totalXP,
        correctCount: correctCount,
        totalQuestions: totalQuestions,
        newBadges: newBadges,
        leveledUp: leveledUp,
        newLevel: newLevel,
        longestCombo: longestCombo,
        coinsEarned: coinsEarned,
        wordsLearned: wordsLearned,
        onContinueLearning: onContinueLearning,
      ),
    );
  }

  @override
  State<EpicResultsModal> createState() => _EpicResultsModalState();
}

class _EpicResultsModalState extends State<EpicResultsModal>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _xpCountController;
  late AnimationController _starController;
  late AnimationController _badgeController;

  late Animation<Offset> _slideAnimation;
  late Animation<int> _xpCountAnimation;

  bool _showConfetti = false;
  bool _showCoinRain = false;
  int _currentXP = 0;
  int _stars = 0;

  @override
  void initState() {
    super.initState();

    // Calculate stars (1-3)
    final score = widget.correctCount / widget.totalQuestions;
    if (score >= 0.95) {
      _stars = 3;
    } else if (score >= 0.75) {
      _stars = 2;
    } else if (score >= 0.5) {
      _stars = 1;
    }

    // Slide up animation
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // XP count-up animation
    _xpCountController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _xpCountAnimation = IntTween(begin: 0, end: widget.totalXP).animate(
      CurvedAnimation(parent: _xpCountController, curve: Curves.easeOutQuart),
    );

    // Star animation
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Badge animation
    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Start animation sequence
    _startAnimationSequence();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _xpCountController.dispose();
    _starController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  Future<void> _startAnimationSequence() async {
    // 1. Slide up
    await _slideController.forward();

    // 2. Trigger confetti if perfect or level up
    if (_stars >= 3 || widget.leveledUp) {
      setState(() => _showConfetti = true);
      HapticService.heavy();
      SoundService.instance.levelUp();
    } else if (_stars >= 2) {
      HapticService.medium();
      SoundService.instance.success();
    }

    // 3. Count up XP with sound and coins
    _xpCountController.addListener(() {
      final newXP = _xpCountAnimation.value;
      if (newXP != _currentXP && newXP % 10 == 0) {
        SoundService.instance.tick();
      }
      setState(() => _currentXP = newXP);
    });
    await _xpCountController.forward();
    SoundService.instance.xpGain();

    // Trigger coin rain after XP counting
    if (widget.coinsEarned > 0 || widget.totalXP > 50) {
      setState(() => _showCoinRain = true);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => _showCoinRain = false);
      });
    }

    // 4. Show stars one by one
    for (int i = 0; i < _stars; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      _starController.forward(from: 0);
      HapticService.light();
      SoundService.instance.success();
    }

    // 5. Show badges if any
    if (widget.newBadges.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      _badgeController.forward();
      HapticService.medium();
      SoundService.instance.achievement();
    }
  }

  int get _starCount {
    final progress = _starController.value;
    if (progress > 0.8) return 3;
    if (progress > 0.4) return 2;
    if (progress > 0.1) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // Confetti overlay
        if (_showConfetti)
          const ConfettiOverlay(duration: Duration(seconds: 4)),

        // Coin rain overlay
        if (_showCoinRain)
          const Positioned.fill(
            child: IgnorePointer(child: CoinRain(coinCount: 30)),
          ),

        // Bottom sheet
        SlideTransition(
          position: _slideAnimation,
          child: Container(
            height: screenHeight * 0.75,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(VibrantSpacing.xl),
                      child: Column(
                        children: [
                          // Title
                          _buildTitle(theme, colorScheme),
                          const SizedBox(height: VibrantSpacing.xl),

                          // Stars
                          _buildStars(theme),
                          const SizedBox(height: VibrantSpacing.xl),

                          // XP Counter
                          _buildXPCounter(theme, colorScheme),
                          const SizedBox(height: VibrantSpacing.xl),

                          // Stats grid
                          _buildStatsGrid(theme, colorScheme),
                          const SizedBox(height: VibrantSpacing.xl),

                          // Level up badge
                          if (widget.leveledUp)
                            _buildLevelUpBadge(theme, colorScheme),

                          // New badges
                          if (widget.newBadges.isNotEmpty)
                            _buildNewBadges(theme, colorScheme),

                          const SizedBox(height: VibrantSpacing.xl),

                          // Action buttons
                          _buildActionButtons(theme, colorScheme),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(ThemeData theme, ColorScheme colorScheme) {
    final score = widget.correctCount / widget.totalQuestions;
    String title;
    String emoji;

    if (score >= 0.95) {
      title = 'Perfect!';
      emoji = '🏆';
    } else if (score >= 0.75) {
      title = 'Great Job!';
      emoji = '🌟';
    } else if (score >= 0.5) {
      title = 'Good Effort!';
      emoji = '👍';
    } else {
      title = 'Keep Practicing!';
      emoji = '💪';
    }

    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: VibrantSpacing.sm),
        Text(
          title,
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildStars(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final filled = index < _starCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: AnimatedBuilder(
            animation: _starController,
            builder: (context, child) {
              final scale = index < _stars
                  ? (index == (_starCount - 1) ? _starController.value : 1.0)
                  : 0.0;
              return Transform.scale(
                scale: scale,
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 56,
                  color: filled
                      ? const Color(0xFFFBBF24)
                      : theme.colorScheme.outlineVariant,
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildXPCounter(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        gradient: VibrantTheme.xpGradient,
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'XP Earned',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            '+$_currentXP',
            style: theme.textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 64,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            theme,
            colorScheme,
            'Correct',
            '${widget.correctCount}/${widget.totalQuestions}',
            Icons.check_circle_rounded,
            colorScheme.tertiary,
          ),
        ),
        const SizedBox(width: VibrantSpacing.md),
        Expanded(
          child: _buildStatCard(
            theme,
            colorScheme,
            'Combo',
            '${widget.longestCombo}x',
            Icons.flash_on_rounded,
            const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(width: VibrantSpacing.md),
        Expanded(
          child: _buildStatCard(
            theme,
            colorScheme,
            'Words',
            '${widget.wordsLearned}',
            Icons.book_rounded,
            colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: VibrantSpacing.xs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelUpBadge(ThemeData theme, ColorScheme colorScheme) {
    return ScaleTransition(
      scale: _badgeController,
      child: Container(
        margin: const EdgeInsets.only(bottom: VibrantSpacing.lg),
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          gradient: VibrantTheme.heroGradient,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          boxShadow: VibrantShadow.lg(colorScheme),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Text(
              'Level ${widget.newLevel} Unlocked!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewBadges(ThemeData theme, ColorScheme colorScheme) {
    return ScaleTransition(
      scale: _badgeController,
      child: Container(
        margin: const EdgeInsets.only(bottom: VibrantSpacing.lg),
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          border: Border.all(
            color: colorScheme.secondary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Text(
                  '${widget.newBadges.length} New Badge${widget.newBadges.length > 1 ? 's' : ''} Unlocked!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Wrap(
              spacing: VibrantSpacing.sm,
              children: widget.newBadges
                  .map(
                    (badge) => Chip(
                      label: Text(badge),
                      avatar: const Icon(Icons.stars_rounded, size: 18),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            HapticService.light();
            Navigator.of(context).pop();
            // Call the callback to navigate to next lesson
            widget.onContinueLearning?.call();
          },
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Continue Learning'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
        const SizedBox(height: VibrantSpacing.sm),
        OutlinedButton.icon(
          onPressed: () {
            HapticService.light();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.home_rounded),
          label: const Text('Back to Home'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }
}
