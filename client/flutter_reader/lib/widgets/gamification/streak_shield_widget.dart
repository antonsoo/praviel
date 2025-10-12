import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_providers.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../services/haptic_service.dart';

/// Widget for purchasing and managing streak shields
class StreakShieldWidget extends ConsumerWidget {
  const StreakShieldWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressServiceAsync = ref.watch(progressServiceProvider);

    return progressServiceAsync.when(
      data: (progressService) {
        return ListenableBuilder(
          listenable: progressService,
          builder: (context, _) {
            final freezes = progressService.streakFreezes;
            final coins = progressService.coins;
            final isUsingBackend = progressService.isUsingBackend;
            final canPurchase = isUsingBackend && coins >= 100;

            return PulseCard(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.blue.shade600,
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(VibrantSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(VibrantRadius.md),
                        ),
                        child: const Icon(
                          Icons.ac_unit_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Streak Shield',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.xxs),
                            Text(
                              'Protect your streak if you miss a day',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VibrantSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(VibrantSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(VibrantRadius.md),
                          ),
                          child: Column(
                            children: [
                              Text(
                                freezes.toString(),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: VibrantSpacing.xxs),
                              Text(
                                'Owned',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.md),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(VibrantSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(VibrantRadius.md),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.monetization_on_rounded,
                                    color: Colors.amber.shade300,
                                    size: 24,
                                  ),
                                  const SizedBox(width: VibrantSpacing.xs),
                                  Text(
                                    '100',
                                    style: theme.textTheme.headlineMedium?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: VibrantSpacing.xxs),
                              Text(
                                'Cost',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VibrantSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: !isUsingBackend
                          ? () => _promptLogin(context)
                          : canPurchase
                              ? () => _purchaseStreakShield(context, ref)
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue.shade700,
                        disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(
                          vertical: VibrantSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VibrantRadius.lg),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_cart_rounded),
                      label: Text(
                        !isUsingBackend
                            ? 'Sign in to protect your streak'
                            : coins >= 100
                            ? 'Purchase Streak Shield'
                            : 'Need ${100 - coins} more coins',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (coins < 100) ...[
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      'Complete more lessons to earn coins (1 coin per 10 XP)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _promptLogin(BuildContext context) {
    HapticService.light();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sign in to buy streak shields and sync your progress.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _purchaseStreakShield(BuildContext context, WidgetRef ref) async {
    HapticService.light();

    final progressApi = ref.read(progressApiProvider);
    final progressService = await ref.read(progressServiceProvider.future);

    final navigator = Navigator.of(context, rootNavigator: true);
    var dialogOpen = false;

    try {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      ).then((_) => dialogOpen = false);
      dialogOpen = true;

      await progressApi.purchaseStreakFreeze();
      await progressService.refresh();

      if (context.mounted) {
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Streak shield purchased successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      HapticService.error();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (dialogOpen && navigator.canPop()) {
        navigator.pop();
        dialogOpen = false;
      }
    }
  }
}

/// Widget for repairing a broken streak
class StreakRepairWidget extends ConsumerWidget {
  const StreakRepairWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final progressServiceAsync = ref.watch(progressServiceProvider);

    return progressServiceAsync.when(
      data: (progressService) {
        return ListenableBuilder(
          listenable: progressService,
          builder: (context, _) {
            final streakDays = progressService.streakDays;
            final maxStreak = progressService.maxStreak;

            // Only show if streak was recently broken (streak is 1 but max is higher)
            if (streakDays != 1 || maxStreak <= 1) {
              return const SizedBox.shrink();
            }

            return PulseCard(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade400,
                  Colors.red.shade500,
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(VibrantSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(VibrantRadius.md),
                        ),
                        child: const Icon(
                          Icons.build_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Repair Your Streak!',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.xxs),
                            Text(
                              'Complete a double lesson to restore your $maxStreak-day streak',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VibrantSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '⚠️ Time Limit: 48 Hours',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: VibrantSpacing.xs),
                        Text(
                          'You can repair your streak within 48 hours of breaking it. Complete a lesson with perfect score to restore it!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to lessons with repair mode
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Complete a lesson with perfect score to repair your streak!'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.orange.shade700,
                        padding: const EdgeInsets.symmetric(
                          vertical: VibrantSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VibrantRadius.lg),
                        ),
                      ),
                      icon: const Icon(Icons.whatshot_rounded),
                      label: Text(
                        'Start Repair Lesson',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }
}
