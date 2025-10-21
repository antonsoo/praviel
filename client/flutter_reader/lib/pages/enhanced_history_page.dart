import 'package:flutter/material.dart';
import '../services/lesson_history_store.dart';
import '../services/haptic_service.dart';
import '../theme/design_tokens.dart';
import '../theme/premium_gradients.dart';
import '../widgets/animated_progress_ring.dart';
import '../widgets/premium_snackbars.dart';
import '../widgets/premium_list_animations.dart';

/// STUNNING history page with timeline visualization
/// Makes users proud of their learning journey
class EnhancedHistoryPage extends StatefulWidget {
  const EnhancedHistoryPage({super.key});

  @override
  State<EnhancedHistoryPage> createState() => _EnhancedHistoryPageState();
}

class _EnhancedHistoryPageState extends State<EnhancedHistoryPage> {
  final LessonHistoryStore _store = LessonHistoryStore();
  List<LessonHistoryEntry>? _entries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final entries = await _store.load();
      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        PremiumSnackBar.error(
          context,
          message: 'Failed to load history: ${e.toString()}',
          title: 'Error',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: PulsingRing(size: 60));
    }

    final entries = _entries ?? [];

    if (entries.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Calculate statistics
    final totalLessons = entries.length;
    final perfectScores = entries.where((e) => e.score == 1.0).length;
    final avgScore =
        entries.map((e) => e.score).reduce((a, b) => a + b) / totalLessons;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Stats header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space20),
            child: _buildStatsSection(
              theme,
              totalLessons,
              perfectScores,
              avgScore,
            ),
          ),
        ),

        // Timeline
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
          sliver: SliverList.separated(
            itemCount: entries.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.space16),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final isFirst = index == 0;
              final isLast = index == entries.length - 1;

              return SlideScaleListItem(
                index: index,
                delay: const Duration(milliseconds: 80),
                child: _buildTimelineItem(
                  entry,
                  theme,
                  isFirst: isFirst,
                  isLast: isLast,
                ),
              );
            },
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space32)),
      ],
    );
  }

  Widget _buildStatsSection(
    ThemeData theme,
    int totalLessons,
    int perfectScores,
    double avgScore,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space24),
      decoration: BoxDecoration(
        gradient: PremiumGradients.primaryButton,
        borderRadius: BorderRadius.circular(AppRadius.xxLarge),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Learning Journey',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.space24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCircle(
                theme,
                value: totalLessons.toString(),
                label: 'Lessons',
                icon: Icons.school,
              ),
              _buildStatCircle(
                theme,
                value: perfectScores.toString(),
                label: 'Perfect',
                icon: Icons.emoji_events,
              ),
              _buildStatCircle(
                theme,
                value: '${(avgScore * 100).toInt()}%',
                label: 'Avg Score',
                icon: Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCircle(
    ThemeData theme, {
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    LessonHistoryEntry entry,
    ThemeData theme, {
    required bool isFirst,
    required bool isLast,
  }) {
    final scorePercent = (entry.score * 100).toInt();
    final gradient = _getGradientForScore(scorePercent);

    return GestureDetector(
      onTap: () {
        HapticService.light();
        PremiumSnackBar.info(
          context,
          message: entry.textSnippet,
          title: 'Lesson Details',
        );
      },
      child: IntrinsicHeight(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line and dot
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 16,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  gradient: gradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: AppSpacing.space16),

          // Card content
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (isFirst ? 0 : 100)),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(20 * (1 - value), 0),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.space16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(
                    color: gradient.colors.first.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.textSnippet,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        AnimatedProgressRing(
                          progress: entry.score,
                          size: 50,
                          strokeWidth: 5,
                          gradient: gradient,
                          child: Text(
                            '$scorePercent%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: gradient.colors.first,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.space4),
                        Text(
                          '${entry.correctCount}/${entry.totalTasks} correct',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.space4),
                        Text(
                          _formatDate(entry.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
        ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: PremiumGradients.primaryButton.scale(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.space24),
            Text(
              'Your Journey Starts Here',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              'Complete lessons to build your learning timeline',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Gradient _getGradientForScore(int percentage) {
    if (percentage >= 90) return PremiumGradients.successButton;
    if (percentage >= 70) return PremiumGradients.premiumButton;
    return PremiumGradients.streakButton;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return 'Today · $hour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}';
    }
  }
}

// Add this extension to support gradient scaling
extension GradientScale on Gradient {
  Gradient scale(double opacity) {
    if (this is LinearGradient) {
      final linear = this as LinearGradient;
      return LinearGradient(
        begin: linear.begin,
        end: linear.end,
        colors: linear.colors
            .map((c) => c.withValues(alpha: c.a * opacity))
            .toList(),
      );
    }
    return this;
  }
}
