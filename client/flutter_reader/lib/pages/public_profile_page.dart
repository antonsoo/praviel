import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_exception.dart';
import '../api/progress_api.dart';
import '../app_providers.dart';
import '../theme/vibrant_theme.dart';

/// Read-only profile view for friends and public users.
class PublicProfilePage extends ConsumerStatefulWidget {
  const PublicProfilePage({
    super.key,
    required this.userId,
    required this.username,
  });

  final String userId;
  final String username;

  @override
  ConsumerState<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends ConsumerState<PublicProfilePage>
    with SingleTickerProviderStateMixin {
  late Future<GamificationUserProgress> _progressFuture;
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
    _reload();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _reload() {
    final api = ref.read(progressApiProvider);
    _progressFuture = api.getUserProgressById(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('@${widget.username}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(_reload);
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<GamificationUserProgress>(
          future: _progressFuture,
          builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            if (error is ApiException && error.statusCode == 403) {
              return _buildMessageCard(
                context,
                title: 'Profile Locked',
                message:
                    'This learner keeps their progress private. Send a friend request to view their stats.',
                icon: Icons.lock_outline,
              );
            }
            return _buildMessageCard(
              context,
              title: 'Unable to load profile',
              message: error?.toString() ?? 'An unknown error occurred.',
              icon: Icons.error_outline,
            );
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeroCard(context, data),
                const SizedBox(height: VibrantSpacing.xl),
                _buildStatGrid(context, data),
                const SizedBox(height: VibrantSpacing.xl),
                _buildWeeklyActivity(context, data),
              ],
            ),
          );
        },
      ),
    ),
  );
  }

  Widget _buildHeroCard(BuildContext context, GamificationUserProgress data) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        gradient: VibrantTheme.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level ${data.level}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            '${data.totalXp} XP earned',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          LinearProgressIndicator(
            value: data.progressToNextLevel,
            minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            '${data.xpToNextLevel} XP until next level',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, GamificationUserProgress data) {
    final stats = [
      _StatTileData('Current Streak', '${data.currentStreak} days', Icons.local_fire_department_outlined),
      _StatTileData('Lessons Completed', '${data.lessonsCompleted}', Icons.menu_book_outlined),
      _StatTileData('Words Learned', '${data.wordsLearned}', Icons.translate_outlined),
      _StatTileData('Minutes Studied', '${data.minutesStudied}', Icons.timer_outlined),
      _StatTileData('Last Active', data.lastActivityDate, Icons.today_outlined),
    ];

    return Wrap(
      spacing: VibrantSpacing.lg,
      runSpacing: VibrantSpacing.lg,
      children: stats
          .map(
            (stat) => SizedBox(
              width: 180,
              child: _StatCard(data: stat),
            ),
          )
          .toList(),
    );
  }

  Widget _buildWeeklyActivity(BuildContext context, GamificationUserProgress data) {
    final theme = Theme.of(context);
    if (data.weeklyActivity.isEmpty) {
      return _buildMessageCard(
        context,
        title: 'No recent activity',
        message: 'This learner hasn\'t recorded lessons in the past week yet.',
        icon: Icons.calendar_today_outlined,
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Activity',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: VibrantSpacing.md),
            ...data.weeklyActivity.map(
              (day) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline),
                title: Text(day.date),
                subtitle: Text(
                  '${day.lessonsCompleted} lessons • ${day.xpEarned} XP • ${day.minutesStudied} min',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatTileData {
  const _StatTileData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatTileData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(data.icon, color: colorScheme.primary),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              data.value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: VibrantSpacing.xs),
            Text(
              data.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
