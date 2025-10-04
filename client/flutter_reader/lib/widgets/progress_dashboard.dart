import 'package:flutter/material.dart';
import '../services/progress_store.dart';
import '../theme/app_theme.dart';
import 'surface.dart';

class ProgressDashboard extends StatefulWidget {
  const ProgressDashboard({super.key});

  @override
  State<ProgressDashboard> createState() => _ProgressDashboardState();
}

class _ProgressDashboardState extends State<ProgressDashboard> {
  final ProgressStore _store = ProgressStore();
  Map<String, dynamic>? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final data = await _store.load();
    if (mounted) {
      setState(() {
        _progress = data;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox.shrink();
    }

    final progress = _progress ?? {};
    final xp = progress['xpTotal'] as int? ?? 0;
    final streak = progress['streakDays'] as int? ?? 0;
    final lastLessonAt = progress['lastLessonAt'] as String?;

    if (xp == 0 && streak == 0) {
      // Don't show dashboard if no progress yet
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return Surface(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: theme.colorScheme.primary),
              SizedBox(width: spacing.xs),
              Text(
                'Your Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.stars,
                  label: 'Total XP',
                  value: xp.toString(),
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Day Streak',
                  value: streak.toString(),
                  color: streak > 0 ? Colors.orange : theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          if (lastLessonAt != null) ...[
            SizedBox(height: spacing.xs),
            Text(
              'Last lesson: ${_formatTime(lastLessonAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.month}/${date.day}';
      }
    } catch (_) {
      return 'recently';
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: spacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
