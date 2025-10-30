import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/vibrant_theme.dart';
import '../../models/achievement.dart';

/// Auto-scrolling achievement carousel for home page
class AchievementCarousel extends StatefulWidget {
  const AchievementCarousel({super.key, required this.achievements});

  final List<Achievement> achievements;

  @override
  State<AchievementCarousel> createState() => _AchievementCarouselState();
}

class _AchievementCarouselState extends State<AchievementCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.achievements.length > 1) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final nextPage = (_currentPage + 1) % widget.achievements.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage = nextPage;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
          child: Text(
            'Recent Achievements',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: VibrantSpacing.md),

        // Carousel
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.achievements.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final achievement = widget.achievements[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.sm,
                ),
                child: AchievementCard(
                  achievement: achievement,
                  isActive: index == _currentPage,
                ),
              );
            },
          ),
        ),

        // Page indicators
        const SizedBox(height: VibrantSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.achievements.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: index == _currentPage ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient: index == _currentPage
                    ? VibrantTheme.heroGradient
                    : null,
                color: index == _currentPage
                    ? null
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual achievement card
class AchievementCard extends StatefulWidget {
  const AchievementCard({
    super.key,
    required this.achievement,
    this.isActive = false,
  });

  final Achievement achievement;
  final bool isActive;

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.isActive) {
      _scaleController.forward();
    }
  }

  @override
  void didUpdateWidget(AchievementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        final scale = 1.0 + (_scaleController.value * 0.05);

        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getRarityColor(),
                  _getRarityColor().withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: _getRarityColor().withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : VibrantShadow.sm(colorScheme),
            ),
            child: Padding(
              padding: const EdgeInsets.all(VibrantSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon & rarity
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(VibrantSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(VibrantRadius.sm),
                        ),
                        child: Icon(
                          _getIconForAchievement(),
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ACHIEVEMENT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Title
                  Text(
                    widget.achievement.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: VibrantSpacing.xs),

                  // Description
                  Text(
                    widget.achievement.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRarityColor() {
    // Use maxProgress to determine rarity
    if (widget.achievement.maxProgress >= 100) {
      return const Color(0xFFFBBF24); // Gold - legendary
    } else if (widget.achievement.maxProgress >= 30) {
      return const Color(0xFF7C3AED); // Purple - epic
    } else if (widget.achievement.maxProgress >= 10) {
      return const Color(0xFF3B82F6); // Blue - rare
    } else {
      return const Color(0xFF78716C); // Gray - common
    }
  }

  IconData _getIconForAchievement() {
    // Simple mapping - could be more sophisticated
    if (widget.achievement.title.toLowerCase().contains('streak')) {
      return Icons.local_fire_department_rounded;
    } else if (widget.achievement.title.toLowerCase().contains('lesson')) {
      return Icons.school_rounded;
    } else if (widget.achievement.title.toLowerCase().contains('perfect')) {
      return Icons.stars_rounded;
    } else {
      return Icons.emoji_events_rounded;
    }
  }
}
