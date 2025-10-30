import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/lesson_path/lesson_node.dart';
import '../widgets/avatar/character_avatar.dart';
import '../widgets/home/xp_ring_progress.dart';
import '../widgets/premium_snackbars.dart';
import '../services/lesson_history_store.dart';

/// Skill tree page showing lesson progression path
class SkillTreePage extends ConsumerStatefulWidget {
  const SkillTreePage({super.key});

  @override
  ConsumerState<SkillTreePage> createState() => _SkillTreePageState();
}

class _SkillTreePageState extends ConsumerState<SkillTreePage>
    with SingleTickerProviderStateMixin {
  final LessonHistoryStore _historyStore = LessonHistoryStore();
  List<LessonData> _lessons = [];
  bool _loading = true;
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
    _loadLessonHistory();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadLessonHistory() async {
    final entries = await _historyStore.load();
    if (!mounted) return;

    setState(() {
      _lessons = _convertHistoryToLessons(entries);
      _loading = false;
    });
  }

  List<LessonData> _convertHistoryToLessons(List<LessonHistoryEntry> entries) {
    if (entries.isEmpty) {
      // Show placeholder if no lessons completed yet
      return [
        LessonData(
          id: 1,
          title: 'Start your first lesson!',
          status: LessonNodeStatus.unlocked,
          xpReward: 50,
          textSnippet: 'Complete a lesson to begin your journey',
        ),
      ];
    }

    // Convert history entries to lesson nodes
    final lessons = <LessonData>[];
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final scorePercent = entry.totalTasks > 0
          ? (entry.correctCount / entry.totalTasks * 100).round()
          : 0;

      // Determine status based on score
      LessonNodeStatus status;
      if (scorePercent >= 90) {
        status = LessonNodeStatus.perfect;
      } else if (scorePercent >= 60) {
        status = LessonNodeStatus.completed;
      } else {
        status = LessonNodeStatus.completed; // Still completed, just low score
      }

      lessons.add(
        LessonData(
          id: i + 1,
          title: _generateTitle(entry, i),
          status: status,
          xpReward: _calculateXP(entry),
          textSnippet: entry.textSnippet,
          timestamp: entry.timestamp,
          score: entry.score,
        ),
      );
    }

    // Add one "next lesson" node
    lessons.add(
      LessonData(
        id: lessons.length + 1,
        title: 'Continue Learning',
        status: LessonNodeStatus.unlocked,
        xpReward: 75,
        textSnippet: 'Ready for your next lesson?',
      ),
    );

    return lessons;
  }

  String _generateTitle(LessonHistoryEntry entry, int index) {
    // Use text snippet as title, truncated
    String title = entry.textSnippet;
    if (title.length > 30) {
      title = '${title.substring(0, 27)}...';
    }
    return title.isNotEmpty ? title : 'Lesson ${index + 1}';
  }

  int _calculateXP(LessonHistoryEntry entry) {
    // Base XP on task count and performance
    return ((entry.totalTasks * 2.5) * (entry.score / 100)).round();
  }

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
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
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
                PremiumSnackBar.success(
                  context,
                  message: 'Ready to start: ${lesson.title}',
                  title: 'Lesson Selected',
                  onTap: () {
                    // Navigate to lessons tab
                    Navigator.of(context).pop();
                  },
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
    this.textSnippet,
    this.timestamp,
    this.score,
  });

  final int id;
  final String title;
  final LessonNodeStatus status;
  final int xpReward;
  final String? textSnippet;
  final DateTime? timestamp;
  final double? score;
}
