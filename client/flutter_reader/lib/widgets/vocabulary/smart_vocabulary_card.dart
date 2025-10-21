import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

/// Smart vocabulary flashcard with flip animation and SRS integration
/// Shows word on front, definition/usage on back
class SmartVocabularyCard extends StatefulWidget {
  const SmartVocabularyCard({
    super.key,
    required this.word,
    required this.definition,
    required this.example,
    this.etymology,
    this.partOfSpeech,
    this.pronunciation,
    this.difficulty,
    this.onRatingSelected,
  });

  final String word;
  final String definition;
  final String example;
  final String? etymology;
  final String? partOfSpeech;
  final String? pronunciation;
  final int? difficulty; // 1-5, visual indicator
  final Function(int)? onRatingSelected; // SRS rating: 1=again, 2=hard, 3=good, 4=easy

  @override
  State<SmartVocabularyCard> createState() => _SmartVocabularyCardState();
}

class _SmartVocabularyCardState extends State<SmartVocabularyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showingFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticService.light();
    SoundService.instance.tap();

    if (_showingFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _showingFront = !_showingFront;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final angle = _flipAnimation.value * 3.14159; // π radians = 180°
          final isFrontVisible = angle < 1.5708; // π/2 radians = 90°

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // perspective
              ..rotateY(angle),
            child: isFrontVisible
                ? _buildFrontSide(theme, colorScheme)
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _buildBackSide(theme, colorScheme),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFrontSide(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Difficulty indicator
          if (widget.difficulty != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  index < widget.difficulty!
                      ? Icons.circle
                      : Icons.circle_outlined,
                  size: 12,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                );
              }),
            ),

          if (widget.difficulty != null)
            const SizedBox(height: VibrantSpacing.lg),

          // Part of speech tag
          if (widget.partOfSpeech != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.md,
                vertical: VibrantSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(VibrantRadius.sm),
              ),
              child: Text(
                widget.partOfSpeech!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onTertiaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const Spacer(),

          // The word itself
          Text(
            widget.word,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),

          if (widget.pronunciation != null) ...[
            const SizedBox(height: VibrantSpacing.md),
            Text(
              widget.pronunciation!,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const Spacer(),

          // Tap hint
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 16,
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
              ),
              const SizedBox(width: VibrantSpacing.xs),
              Text(
                'Tap to reveal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.secondaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Definition
          Text(
            'Definition',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            widget.definition,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onTertiaryContainer,
              height: 1.5,
            ),
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Example
          Text(
            'Example',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(VibrantRadius.md),
            ),
            child: Text(
              widget.example,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onTertiaryContainer.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),

          if (widget.etymology != null) ...[
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'Etymology',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onTertiaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              widget.etymology!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onTertiaryContainer.withValues(alpha: 0.7),
                height: 1.4,
              ),
            ),
          ],

          const Spacer(),

          // SRS rating buttons (if callback provided)
          if (widget.onRatingSelected != null)
            Row(
              children: [
                Expanded(
                  child: _SRSButton(
                    label: 'Again',
                    color: colorScheme.error,
                    icon: Icons.replay_rounded,
                    onPressed: () {
                      HapticService.light();
                      widget.onRatingSelected!(1);
                    },
                  ),
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Expanded(
                  child: _SRSButton(
                    label: 'Hard',
                    color: Colors.orange,
                    icon: Icons.trending_down_rounded,
                    onPressed: () {
                      HapticService.light();
                      widget.onRatingSelected!(2);
                    },
                  ),
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Expanded(
                  child: _SRSButton(
                    label: 'Good',
                    color: Colors.blue,
                    icon: Icons.check_rounded,
                    onPressed: () {
                      HapticService.medium();
                      widget.onRatingSelected!(3);
                    },
                  ),
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Expanded(
                  child: _SRSButton(
                    label: 'Easy',
                    color: colorScheme.primary,
                    icon: Icons.trending_up_rounded,
                    onPressed: () {
                      HapticService.heavy();
                      widget.onRatingSelected!(4);
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SRSButton extends StatelessWidget {
  const _SRSButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: VibrantSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(VibrantRadius.sm),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
