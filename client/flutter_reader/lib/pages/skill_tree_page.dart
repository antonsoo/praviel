import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/lesson_path/lesson_node.dart';
import '../widgets/avatar/character_avatar.dart';
import '../widgets/home/xp_ring_progress.dart';

/// Skill tree page showing lesson progression path
class SkillTreePage extends ConsumerStatefulWidget {
  const SkillTreePage({super.key});

  @override
  ConsumerState<SkillTreePage> createState() => _SkillTreePageState();
}

class _SkillTreePageState extends ConsumerState<SkillTreePage> {
  // Mock lesson data - would come from backend/state
  final List<LessonData> _lessons = [
    LessonData(
      id: 1,
      title: 'The Greek Alphabet',
      status: LessonNodeStatus.perfect,
      xpReward: 50,
    ),
    LessonData(
      id: 2,
      title: 'Basic Greetings',
      status: LessonNodeStatus.completed,
      xpReward: 50,
    ),
    LessonData(
      id: 3,
      title: 'Simple Nouns',
      status: LessonNodeStatus.unlocked,
      xpReward: 75,
    ),
    LessonData(
      id: 4,
      title: 'Common Verbs',
      status: LessonNodeStatus.locked,
      xpReward: 75,
    ),
    LessonData(
      id: 5,
      title: 'Articles',
      status: LessonNodeStatus.locked,
      xpReward: 100,
    ),
    LessonData(
      id: 6,
      title: 'Basic Sentences',
      status: LessonNodeStatus.locked,
      xpReward: 100,
    ),
    LessonData(
      id: 7,
      title: 'Questions',
      status: LessonNodeStatus.locked,
      xpReward: 125,
    ),
    LessonData(
      id: 8,
      title: 'Numbers',
      status: LessonNodeStatus.locked,
      xpReward: 125,
    ),
    LessonData(
      id: 9,
      title: 'Time & Dates',
      status: LessonNodeStatus.locked,
      xpReward: 150,
    ),
    LessonData(
      id: 10,
      title: 'Colors & Adjectives',
      status: LessonNodeStatus.locked,
      xpReward: 150,
    ),
  ];

  int get _currentLessonIndex {
    // Find first unlocked lesson
    return _lessons.indexWhere(
      (lesson) => lesson.status == LessonNodeStatus.unlocked,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Your Learning Path'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          children: [
            // Hero section with avatar
            SlideInFromBottom(
              delay: const Duration(milliseconds: 100),
              child: _buildHeroSection(theme, colorScheme),
            ),

            const SizedBox(height: VibrantSpacing.xxl),

            // Lesson path
            _buildLessonPath(theme, colorScheme),

            const SizedBox(height: VibrantSpacing.xxl),

            // Coming soon section
            _buildComingSoon(theme, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, ColorScheme colorScheme) {
    final completedCount = _lessons
        .where(
          (l) =>
              l.status == LessonNodeStatus.completed ||
              l.status == LessonNodeStatus.perfect,
        )
        .length;
    final totalCount = _lessons.length;
    final progress = completedCount / totalCount;

    return PulseCard(
      child: Column(
        children: [
          Row(
            children: [
              BounceIn(
                child: const CharacterAvatar(
                  emotion: AvatarEmotion.excited,
                  size: 64,
                ),
              ),
              const SizedBox(width: VibrantSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Progress',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      '$completedCount of $totalCount lessons',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  gradient: VibrantTheme.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${(progress * 100).round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.lg),
          CompactXPBar(
            currentXP: completedCount,
            maxXP: totalCount,
            height: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildLessonPath(ThemeData theme, ColorScheme colorScheme) {
    final children = <Widget>[];

    for (int i = 0; i < _lessons.length; i++) {
      final lesson = _lessons[i];
      final isCurrentPosition = i == _currentLessonIndex;
      final previousCompleted =
          i == 0 ||
          _lessons[i - 1].status == LessonNodeStatus.completed ||
          _lessons[i - 1].status == LessonNodeStatus.perfect;

      // Add connector before node (except first)
      if (i > 0) {
        children.add(
          SlideInFromBottom(
            delay: Duration(milliseconds: 100 + (i * 50)),
            child: PathConnector(isCompleted: previousCompleted, length: 40),
          ),
        );
      }

      // Add node
      children.add(
        SlideInFromBottom(
          delay: Duration(milliseconds: 100 + (i * 50)),
          child: LessonNode(
            title: lesson.title,
            status: lesson.status,
            lessonNumber: lesson.id,
            xpReward: lesson.xpReward,
            isCurrentPosition: isCurrentPosition,
            onTap: () => _handleLessonTap(lesson),
          ),
        ),
      );

      // Add branching path every 3 lessons for visual interest
      if ((i + 1) % 3 == 0 && i < _lessons.length - 1) {
        children.add(const SizedBox(height: VibrantSpacing.md));
        children.add(
          SlideInFromBottom(
            delay: Duration(milliseconds: 100 + (i * 50)),
            child: _buildCheckpoint(theme, colorScheme, i + 1),
          ),
        );
        children.add(const SizedBox(height: VibrantSpacing.md));
      }
    }

    return Column(children: children);
  }

  Widget _buildCheckpoint(
    ThemeData theme,
    ColorScheme colorScheme,
    int lessons,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: VibrantTheme.xpGradient,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        boxShadow: VibrantShadow.md(colorScheme),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 24),
          const SizedBox(width: VibrantSpacing.sm),
          Text(
            'Checkpoint: $lessons Lessons!',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant, width: 2),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
      ),
      child: Column(
        children: [
          Icon(
            Icons.construction_rounded,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'More Lessons Coming Soon!',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            'We\'re adding new content regularly. Keep learning!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleLessonTap(LessonData lesson) {
    // Show lesson details modal with start button
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lesson.title),
        content: Text(
          lesson.status == LessonNodeStatus.locked
              ? 'Complete previous lessons to unlock!'
              : 'Lesson ${lesson.id}: ${lesson.title}\n\nReward: ${lesson.xpReward} XP',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (lesson.status != LessonNodeStatus.locked)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to lessons page or trigger lesson generation
                // This would typically navigate to the lessons tab
                // For now, show a message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Starting lesson: ${lesson.title}'),
                    action: SnackBarAction(
                      label: 'Go to Lessons',
                      onPressed: () {
                        // This would navigate to the lessons tab in the main app
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                );
              },
              child: const Text('Start Lesson'),
            ),
        ],
      ),
    );
  }
}

/// Lesson data model
class LessonData {
  const LessonData({
    required this.id,
    required this.title,
    required this.status,
    required this.xpReward,
  });

  final int id;
  final String title;
  final LessonNodeStatus status;
  final int xpReward;
}
