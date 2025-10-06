import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_providers.dart';
import '../theme/design_tokens.dart';
import '../theme/premium_gradients.dart';

/// Premium custom app bar with streak counter, level, and XP
/// This makes every screen feel cohesive and gamified
class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressServiceAsync = ref.watch(progressServiceProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top row with title and actions
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space16,
                vertical: AppSpacing.space8,
              ),
              child: Row(
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (actions != null) ...actions!,
                ],
              ),
            ),

            // Stats row
            progressServiceAsync.when(
              data: (progressService) {
                return ListenableBuilder(
                  listenable: progressService,
                  builder: (context, _) {
                    final hasProgress = progressService.hasProgress;

                    if (!hasProgress) {
                      return const SizedBox(height: AppSpacing.space48);
                    }

                    final streak = progressService.streakDays;
                    final level = progressService.currentLevel;
                    final xp = progressService.xpTotal;
                    final progress = progressService.progressToNextLevel;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space16,
                        vertical: AppSpacing.space8,
                      ),
                      child: Row(
                        children: [
                          // Streak counter
                          _buildStatPill(
                            icon: Icons.local_fire_department,
                            value: streak.toString(),
                            label: 'day streak',
                            gradient: PremiumGradients.streakButton,
                            context: context,
                          ),
                          const SizedBox(width: AppSpacing.space12),

                          // Level indicator
                          _buildStatPill(
                            icon: Icons.military_tech,
                            value: 'Lv.$level',
                            label: '${(progress * 100).toInt()}% to next',
                            gradient: PremiumGradients.premiumButton,
                            context: context,
                          ),
                          const Spacer(),

                          // XP display
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.space16,
                              vertical: AppSpacing.space8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFFFBBF24,
                                  ).withValues(alpha: 0.15),
                                  const Color(
                                    0xFFF59E0B,
                                  ).withValues(alpha: 0.15),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                              border: Border.all(
                                color: const Color(
                                  0xFFFBBF24,
                                ).withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  size: 18,
                                  color: Color(0xFFFBBF24),
                                ),
                                const SizedBox(width: AppSpacing.space8),
                                Text(
                                  '$xp XP',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const SizedBox(height: AppSpacing.space48),
              error: (_, __) => const SizedBox(height: AppSpacing.space48),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required String label,
    required Gradient gradient,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space12,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        gradient: gradient.scale(0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: gradient.colors.first.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: gradient.colors.first,
                  height: 1.0,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
