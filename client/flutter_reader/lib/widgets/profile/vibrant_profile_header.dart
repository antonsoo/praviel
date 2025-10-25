import 'package:flutter/material.dart';

import '../../theme/vibrant_animations.dart';
import '../../theme/vibrant_theme.dart';
import '../avatar/character_avatar.dart';
import '../common/aurora_background.dart';
import '../gamification/xp_counter.dart';
import '../glassmorphism_card.dart';

class VibrantProfileHeader extends StatefulWidget {
  const VibrantProfileHeader({
    super.key,
    required this.level,
    required this.xp,
    required this.streak,
    required this.progressToNext,
    required this.onOpenSettings,
    required this.onOpenStats,
    required this.onOpenShop,
    this.pendingSyncCount = 0,
  });

  final int level;
  final int xp;
  final int streak;
  final double progressToNext;
  final int pendingSyncCount;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenStats;
  final VoidCallback onOpenShop;

  @override
  State<VibrantProfileHeader> createState() => _VibrantProfileHeaderState();
}

class _VibrantProfileHeaderState extends State<VibrantProfileHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _auroraController;

  @override
  void initState() {
    super.initState();
    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _auroraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeProgress = widget.progressToNext.isNaN
        ? 0.0
        : widget.progressToNext.clamp(0.0, 1.0);
    final pendingSync = widget.pendingSyncCount > 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: VibrantTheme.auroraGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        child: Stack(
          children: [
            AuroraBackground(controller: _auroraController),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VibrantSpacing.lg,
                  VibrantSpacing.lg,
                  VibrantSpacing.lg,
                  VibrantSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFECFEFF)],
                          ).createShader(bounds),
                          blendMode: BlendMode.srcIn,
                          child: Text(
                            'Scholar Profile',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _GlassIconButton(
                          icon: Icons.settings_rounded,
                          onTap: widget.onOpenSettings,
                        ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const CharacterAvatar(
                              emotion: AvatarEmotion.excited,
                              size: 92,
                            ),
                            Positioned(
                              right: -6,
                              bottom: -6,
                              child: GlassmorphismCard(
                                blur: 16,
                                opacity: 0.2,
                                borderOpacity: 0.4,
                                borderRadius: 24,
                                gradient: VibrantTheme.xpGradient,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: VibrantSpacing.md,
                                  vertical: VibrantSpacing.xs,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: VibrantSpacing.xs),
                                    Text(
                                      'Level ${widget.level}',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: VibrantSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, scholar!',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: VibrantSpacing.sm),
                              XPCounter(
                                xp: widget.xp,
                                size: XPCounterSize.medium,
                              ),
                              const SizedBox(height: VibrantSpacing.sm),
                              Wrap(
                                spacing: VibrantSpacing.sm,
                                runSpacing: VibrantSpacing.sm,
                                children: [
                                  _InfoChip(
                                    icon: Icons.local_fire_department_rounded,
                                    label: 'Streak',
                                    value:
                                        '${widget.streak} day${widget.streak == 1 ? '' : 's'}',
                                  ),
                                  if (pendingSync)
                                    _InfoChip(
                                      icon: Icons.cloud_upload_rounded,
                                      label: 'Offline sync',
                                      value:
                                          '${widget.pendingSyncCount} pending',
                                      accent: const Color(0xFFFFD700),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    _LevelProgressBar(progress: safeProgress),
                    const SizedBox(height: VibrantSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.timeline_rounded,
                            label: 'View stats',
                            onTap: widget.onOpenStats,
                          ),
                        ),
                        const SizedBox(width: VibrantSpacing.md),
                        Expanded(
                          child: _QuickActionButton(
                            icon: Icons.shopping_bag_rounded,
                            label: 'Power-up shop',
                            onTap: widget.onOpenShop,
                            gradient: VibrantTheme.sunsetGradient,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassmorphismCard(
      blur: 18,
      opacity: 0.18,
      borderOpacity: 0.3,
      borderRadius: 16,
      padding: const EdgeInsets.all(8),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (accent ?? Colors.white).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: accent ?? Colors.white, size: 18),
          const SizedBox(width: VibrantSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelProgressBar extends StatelessWidget {
  const _LevelProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: VibrantDuration.moderate,
      curve: VibrantCurve.smooth,
      builder: (context, value, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: VibrantTheme.premiumGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: VibrantSpacing.xs),
            Text(
              '${(value * 100).round()}% to next level',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.gradient,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.lg,
          vertical: VibrantSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: gradient ?? VibrantTheme.premiumGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: VibrantSpacing.sm),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
