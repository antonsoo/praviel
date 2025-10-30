import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/vibrant_animations.dart';
import '../../theme/vibrant_theme.dart';
import '../avatar/character_avatar.dart';
import '../common/aurora_background.dart';
import '../glassmorphism_card.dart';
import '../gamification/xp_counter.dart';

class VibrantHeroHeader extends StatefulWidget {
  const VibrantHeroHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.streak,
    required this.level,
    required this.totalXp,
    required this.progress,
    required this.xpIntoLevel,
    required this.xpRequiredForLevel,
    required this.hasProgress,
    required this.emotion,
    required this.onStartLearning,
    required this.onOpenSkillTree,
    required this.onViewHistory,
    required this.onOpenShop,
  });

  final String greeting;
  final String subtitle;
  final int streak;
  final int level;
  final int totalXp;
  final double progress;
  final int xpIntoLevel;
  final int xpRequiredForLevel;
  final bool hasProgress;
  final AvatarEmotion emotion;
  final VoidCallback onStartLearning;
  final VoidCallback onOpenSkillTree;
  final VoidCallback onViewHistory;
  final VoidCallback onOpenShop;

  @override
  State<VibrantHeroHeader> createState() => _VibrantHeroHeaderState();
}

class _VibrantHeroHeaderState extends State<VibrantHeroHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeProgress = widget.progress.isNaN
        ? 0.0
        : widget.progress.clamp(0.0, 1.0).toDouble();
    final safeRequired = widget.xpRequiredForLevel <= 0
        ? 1
        : widget.xpRequiredForLevel;
    final safeInto = widget.xpIntoLevel.clamp(0, safeRequired);
    final remaining = (safeRequired - safeInto).clamp(0, safeRequired);
    final momentumScore = _calculateMomentumScore(
      progress: safeProgress,
      streak: widget.streak,
      level: widget.level,
    );

    final shopBadge = _HeroShopBadge(
      totalXp: widget.totalXp,
      onTap: widget.onOpenShop,
    );

    return GlassmorphismCard(
      blur: 24,
      borderRadius: 32,
      opacity: 0.18,
      borderOpacity: 0.24,
      elevation: 3,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: VibrantTheme.auroraGradient,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              AuroraBackground(controller: _controller),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.xl),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 760;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroHeadline(
                          greeting: widget.greeting,
                          subtitle: widget.subtitle,
                          emotion: widget.emotion,
                          hasProgress: widget.hasProgress,
                          level: widget.level,
                          momentumScore: momentumScore,
                          shopBadge: isCompact ? null : shopBadge,
                          isCompact: isCompact,
                        ),
                        if (isCompact) ...[
                          const SizedBox(height: VibrantSpacing.lg),
                          shopBadge,
                        ],
                        const SizedBox(height: VibrantSpacing.lg),
                        Wrap(
                          spacing: VibrantSpacing.md,
                          runSpacing: VibrantSpacing.sm,
                          children: [
                            _HeroStatPill(
                              icon: Icons.local_fire_department_rounded,
                              label: 'Current streak',
                              value: widget.streak > 0
                                  ? '${widget.streak} day${widget.streak == 1 ? '' : 's'}'
                                  : 'Ready to ignite',
                            ),
                            _HeroStatPill(
                              icon: Icons.workspace_premium_rounded,
                              label: 'Level',
                              value: 'Level ${widget.level}',
                            ),
                            _HeroMomentumPill(
                              score: momentumScore,
                              streak: widget.streak,
                            ),
                          ],
                        ),
                        const SizedBox(height: VibrantSpacing.lg),
                        _HeroProgressMeter(
                          progress: safeProgress,
                          xpIntoLevel: safeInto,
                          xpRequired: safeRequired,
                          xpRemaining: remaining,
                        ),
                        const SizedBox(height: VibrantSpacing.lg),
                        _HeroActionsRow(
                          hasProgress: widget.hasProgress,
                          onStartLearning: widget.onStartLearning,
                          onOpenSkillTree: widget.onOpenSkillTree,
                          onViewHistory: widget.onViewHistory,
                          isCompact: isCompact,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateMomentumScore({
    required double progress,
    required int streak,
    required int level,
  }) {
    final streakFactor = math.min(streak / 21.0, 1.0);
    final levelFactor = math.min(level / 40.0, 1.0);
    final progressFactor = progress.clamp(0.0, 1.0);
    final score =
        (progressFactor * 50) + (streakFactor * 30) + (levelFactor * 20);
    return score.clamp(0, 100).round();
  }
}

class _HeroHeadline extends StatelessWidget {
  const _HeroHeadline({
    required this.greeting,
    required this.subtitle,
    required this.emotion,
    required this.hasProgress,
    required this.level,
    required this.momentumScore,
    required this.isCompact,
    this.shopBadge,
  });

  final String greeting;
  final String subtitle;
  final AvatarEmotion emotion;
  final bool hasProgress;
  final int level;
  final int momentumScore;
  final bool isCompact;
  final Widget? shopBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.displaySmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      fontSize: isCompact ? 28 : 34,
      letterSpacing: -0.8,
    );

    return Row(
      crossAxisAlignment: isCompact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        CharacterAvatar(emotion: emotion, size: isCompact ? 84 : 104),
        const SizedBox(width: VibrantSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.md,
                      vertical: VibrantSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: VibrantSpacing.xxs),
                        Text(
                          'Level $level Scholar',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.md,
                      vertical: VibrantSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          momentumScore >= 70
                              ? Icons.trending_up_rounded
                              : Icons.bolt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: VibrantSpacing.xxs),
                        Text(
                          'Momentum $momentumScore',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.sm),
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    colors: [Colors.white, Color(0xFFECFEFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                blendMode: BlendMode.srcIn,
                child: Text(greeting, style: headlineStyle),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              AnimatedOpacity(
                duration: VibrantDuration.moderate,
                opacity: hasProgress ? 1 : 0.85,
                child: Text(
                  hasProgress
                      ? 'We saved your spot — jump back in with one tap.'
                      : 'Your personalized journey is curated and ready.',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (shopBadge != null) ...[
          const SizedBox(width: VibrantSpacing.lg),
          SizedBox(width: isCompact ? 160 : 200, child: shopBadge),
        ],
      ],
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.sm),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x33FFFFFF),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: VibrantSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
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

class _HeroMomentumPill extends StatelessWidget {
  const _HeroMomentumPill({required this.score, required this.streak});

  final int score;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = (score / 100).clamp(0.0, 1.0);
    final accent = Color.lerp(
      const Color(0xFF8B5CF6),
      const Color(0xFF22D3EE),
      normalized,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.lg,
        vertical: VibrantSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 4,
                  value: normalized,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    accent ?? Colors.white,
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                ),
                Text(
                  '$score',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: VibrantSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Momentum',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              Text(
                streak > 0
                    ? 'x${(1 + streak / 22).toStringAsFixed(1)} streak boost'
                    : 'Streak boost ready',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroProgressMeter extends StatelessWidget {
  const _HeroProgressMeter({
    required this.progress,
    required this.xpIntoLevel,
    required this.xpRequired,
    required this.xpRemaining,
  });

  final double progress;
  final int xpIntoLevel;
  final int xpRequired;
  final int xpRemaining;

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
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFB5F5FA),
                            Color(0xFF60A5FA),
                            Color(0xFF6366F1),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF60A5FA,
                            ).withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$xpIntoLevel / $xpRequired XP',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$xpRemaining XP to next level',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HeroActionsRow extends StatelessWidget {
  const _HeroActionsRow({
    required this.hasProgress,
    required this.onStartLearning,
    required this.onOpenSkillTree,
    required this.onViewHistory,
    required this.isCompact,
  });

  final bool hasProgress;
  final VoidCallback onStartLearning;
  final VoidCallback onOpenSkillTree;
  final VoidCallback onViewHistory;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final children = [
      _HeroActionButton(
        icon: hasProgress
            ? Icons.play_arrow_rounded
            : Icons.lightbulb_outline_rounded,
        label: hasProgress ? 'Resume lesson' : 'Start learning',
        onTap: onStartLearning,
        variant: _HeroActionVariant.primary,
      ),
      _HeroActionButton(
        icon: Icons.auto_graph_rounded,
        label: 'Skill tree',
        onTap: onOpenSkillTree,
        variant: _HeroActionVariant.secondary,
      ),
      _HeroActionButton(
        icon: Icons.history_toggle_off_rounded,
        label: 'History',
        onTap: onViewHistory,
        variant: _HeroActionVariant.ghost,
      ),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final child in children) ...[
            child,
            const SizedBox(height: VibrantSpacing.sm),
          ],
        ],
      );
    }

    return Wrap(
      spacing: VibrantSpacing.md,
      runSpacing: VibrantSpacing.sm,
      children: children,
    );
  }
}

enum _HeroActionVariant { primary, secondary, ghost }

class _HeroActionButton extends StatelessWidget {
  const _HeroActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.variant,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final _HeroActionVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Gradient? gradient;
    Color? background;
    Border? border;
    List<BoxShadow>? shadows;
    Color iconColor = Colors.white;
    Color textColor = Colors.white;

    switch (variant) {
      case _HeroActionVariant.primary:
        gradient = VibrantTheme.premiumGradient;
        shadows = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ];
        break;
      case _HeroActionVariant.secondary:
        background = Colors.white.withValues(alpha: 0.14);
        border = Border.all(color: Colors.white.withValues(alpha: 0.25));
        break;
      case _HeroActionVariant.ghost:
        background = Colors.white.withValues(alpha: 0.06);
        border = Border.all(color: Colors.white.withValues(alpha: 0.14));
        iconColor = Colors.white.withValues(alpha: 0.9);
        textColor = Colors.white.withValues(alpha: 0.9);
        break;
    }

    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.xl,
          vertical: VibrantSpacing.md,
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          color: background,
          borderRadius: BorderRadius.circular(24),
          border: border,
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: VibrantSpacing.sm),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroShopBadge extends StatelessWidget {
  const _HeroShopBadge({required this.totalXp, required this.onTap});

  final int totalXp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScaleButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFA500).withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Power-ups',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.open_in_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: VibrantSpacing.xs),
            Text(
              'Boost streaks, shield progress, unlock surges.',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.3,
              ),
            ),
            const SizedBox(height: VibrantSpacing.md),
            XPCounter(xp: totalXp, size: XPCounterSize.small),
          ],
        ),
      ),
    );
  }
}
