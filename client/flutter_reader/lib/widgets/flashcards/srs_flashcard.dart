import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';
import 'dart:math' as math;

/// SRS (Spaced Repetition System) interval quality ratings
enum SRSQuality {
  again, // 0 - Complete blackout
  hard, // 1 - Incorrect but recognized
  good, // 2 - Correct with difficulty
  easy, // 3 - Perfect recall
}

class FlashcardData {
  final String id;
  final String front;
  final String back;
  final String? etymology;
  final String? grammar;
  final String? example;
  final List<String>? relatedWords;
  final DateTime? nextReview;
  final int interval; // Days until next review
  final int repetitions;
  final double easeFactor;

  const FlashcardData({
    required this.id,
    required this.front,
    required this.back,
    this.etymology,
    this.grammar,
    this.example,
    this.relatedWords,
    this.nextReview,
    this.interval = 1,
    this.repetitions = 0,
    this.easeFactor = 2.5,
  });
}

/// Professional 3D flip flashcard with SRS algorithm
class SRSFlashcard extends StatefulWidget {
  const SRSFlashcard({
    super.key,
    required this.card,
    required this.onRate,
    this.showEtymology = true,
    this.showGrammar = true,
    this.languageCode = 'lat',
  });

  final FlashcardData card;
  final Function(SRSQuality) onRate;
  final bool showEtymology;
  final bool showGrammar;
  final String languageCode;

  @override
  State<SRSFlashcard> createState() => _SRSFlashcardState();
}

class _SRSFlashcardState extends State<SRSFlashcard> with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_flipController.isAnimating) return;

    setState(() => _showBack = !_showBack);
    HapticService.medium();
    SoundService.instance.tap();

    if (_showBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _handleRating(SRSQuality quality) {
    HapticService.success();
    if (quality == SRSQuality.again) {
      SoundService.instance.error();
    } else {
      SoundService.instance.success();
    }
    widget.onRate(quality);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Flashcard
        Expanded(
          child: GestureDetector(
            onTap: _flip,
            child: AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * math.pi;
                final transform = Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle);

                return Transform(
                  transform: transform,
                  alignment: Alignment.center,
                  child: angle < math.pi / 2
                      ? _CardFront(
                          text: widget.card.front,
                          languageCode: widget.languageCode,
                        )
                      : Transform(
                          transform: Matrix4.identity()..rotateY(math.pi),
                          alignment: Alignment.center,
                          child: _CardBack(
                            card: widget.card,
                            showEtymology: widget.showEtymology,
                            showGrammar: widget.showGrammar,
                          ),
                        ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: VibrantSpacing.xl),

        // SRS Rating Buttons (only show when back is visible)
        if (_showBack) ...[
          _SRSRatingButtons(
            onRate: _handleRating,
            card: widget.card,
          ),
        ] else ...[
          // Hint to tap
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.lg,
              vertical: VibrantSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Text(
                  'Tap to reveal answer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    required this.text,
    required this.languageCode,
  });

  final String text;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.8),
            colorScheme.tertiaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Text(
            text,
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.card,
    required this.showEtymology,
    required this.showGrammar,
  });

  final FlashcardData card;
  final bool showEtymology;
  final bool showGrammar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondaryContainer.withValues(alpha: 0.8),
            colorScheme.tertiaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main definition
            Center(
              child: Text(
                card.back,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            if (card.grammar != null && showGrammar) ...[
              const SizedBox(height: VibrantSpacing.lg),
              Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: VibrantSpacing.md),
              _InfoSection(
                icon: Icons.auto_stories_rounded,
                title: 'Grammar',
                content: card.grammar!,
                color: Colors.blue,
              ),
            ],

            if (card.etymology != null && showEtymology) ...[
              const SizedBox(height: VibrantSpacing.md),
              _InfoSection(
                icon: Icons.history_edu_rounded,
                title: 'Etymology',
                content: card.etymology!,
                color: Colors.purple,
              ),
            ],

            if (card.example != null) ...[
              const SizedBox(height: VibrantSpacing.md),
              _InfoSection(
                icon: Icons.format_quote_rounded,
                title: 'Example',
                content: card.example!,
                color: Colors.green,
              ),
            ],

            if (card.relatedWords != null && card.relatedWords!.isNotEmpty) ...[
              const SizedBox(height: VibrantSpacing.md),
              _RelatedWords(words: card.relatedWords!),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: VibrantSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RelatedWords extends StatelessWidget {
  const _RelatedWords({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link_rounded, size: 16, color: Colors.orange),
            const SizedBox(width: VibrantSpacing.xs),
            Text(
              'Related Words',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: VibrantSpacing.sm),
        Wrap(
          spacing: VibrantSpacing.sm,
          runSpacing: VibrantSpacing.sm,
          children: words.map((word) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.md,
                vertical: VibrantSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                word,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// SRS rating buttons with predicted intervals
class _SRSRatingButtons extends StatelessWidget {
  const _SRSRatingButtons({
    required this.onRate,
    required this.card,
  });

  final Function(SRSQuality) onRate;
  final FlashcardData card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          'How well did you know this?',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),
        Row(
          children: [
            Expanded(
              child: _RatingButton(
                label: 'Again',
                color: Colors.red,
                interval: '<1m',
                onTap: () => onRate(SRSQuality.again),
              ),
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Expanded(
              child: _RatingButton(
                label: 'Hard',
                color: Colors.orange,
                interval: _calculateInterval(card, SRSQuality.hard),
                onTap: () => onRate(SRSQuality.hard),
              ),
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Expanded(
              child: _RatingButton(
                label: 'Good',
                color: Colors.green,
                interval: _calculateInterval(card, SRSQuality.good),
                onTap: () => onRate(SRSQuality.good),
              ),
            ),
            const SizedBox(width: VibrantSpacing.sm),
            Expanded(
              child: _RatingButton(
                label: 'Easy',
                color: Colors.blue,
                interval: _calculateInterval(card, SRSQuality.easy),
                onTap: () => onRate(SRSQuality.easy),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _calculateInterval(FlashcardData card, SRSQuality quality) {
    // Simplified SM-2 algorithm
    int newInterval = card.interval;

    switch (quality) {
      case SRSQuality.again:
        newInterval = 1;
        break;
      case SRSQuality.hard:
        newInterval = (card.interval * 1.2).round();
        break;
      case SRSQuality.good:
        newInterval = (card.interval * card.easeFactor).round();
        break;
      case SRSQuality.easy:
        newInterval = (card.interval * card.easeFactor * 1.3).round();
        break;
    }

    if (newInterval < 1) return '<1d';
    if (newInterval == 1) return '1d';
    if (newInterval < 30) return '${newInterval}d';
    if (newInterval < 365) return '${(newInterval / 30).round()}mo';
    return '${(newInterval / 365).round()}y';
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.interval,
    required this.onTap,
  });

  final String label;
  final Color color;
  final String interval;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: VibrantSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(VibrantRadius.md),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                interval,
                style: theme.textTheme.labelSmall?.copyWith(
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
