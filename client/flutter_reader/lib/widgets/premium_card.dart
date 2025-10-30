import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/premium_gradients.dart';
import '../theme/design_tokens.dart';

/// Premium glass-morphism card with blur effect
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.margin,
    this.blur = 10.0,
  });

  final Widget child;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.large),
        boxShadow: PremiumShadows.medium(),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.large),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.space20),
            decoration: BoxDecoration(
              gradient:
                  gradient ??
                  LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            Colors.white.withValues(alpha: 0.1),
                            Colors.white.withValues(alpha: 0.05),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.9),
                            Colors.white.withValues(alpha: 0.7),
                          ],
                  ),
              borderRadius:
                  borderRadius ?? BorderRadius.circular(AppRadius.large),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Premium gradient card with depth
class GradientCard extends StatelessWidget {
  const GradientCard({
    required this.child,
    required this.gradient,
    super.key,
    this.borderRadius,
    this.padding,
    this.margin,
    this.shadowColor,
    this.onTap,
  });

  final Widget child;
  final Gradient gradient;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? shadowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.large),
        boxShadow: shadowColor != null
            ? PremiumShadows.colored(shadowColor!)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.large),
          child: Ink(
            padding: padding ?? const EdgeInsets.all(AppSpacing.space20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius:
                  borderRadius ?? BorderRadius.circular(AppRadius.large),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Elevated card with sophisticated shadow
class ElevatedCard extends StatelessWidget {
  const ElevatedCard({
    required this.child,
    super.key,
    this.gradient,
    this.color,
    this.borderRadius,
    this.padding,
    this.margin,
    this.elevation = 'medium',
    this.onTap,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String elevation; // 'soft', 'medium', 'strong'
  final VoidCallback? onTap;

  List<BoxShadow> _getShadow() {
    switch (elevation) {
      case 'soft':
        return PremiumShadows.soft();
      case 'strong':
        return PremiumShadows.strong();
      default:
        return PremiumShadows.medium();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.large),
        boxShadow: _getShadow(),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.large),
          child: Ink(
            padding: padding ?? const EdgeInsets.all(AppSpacing.space20),
            decoration: BoxDecoration(
              gradient: gradient,
              color: gradient == null ? (color ?? Colors.white) : null,
              borderRadius:
                  borderRadius ?? BorderRadius.circular(AppRadius.large),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Shimmer card for loading states
class ShimmerCard extends StatefulWidget {
  const ShimmerCard({
    super.key,
    this.width,
    this.height = 120,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppRadius.large),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Hero card with stunning visual impact
class HeroCard extends StatelessWidget {
  const HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    super.key,
    this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(AppSpacing.space24),
      shadowColor: gradient.colors.first,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.space16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Icon(icon, size: 32, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.space16),
            trailing!,
          ] else
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
        ],
      ),
    );
  }
}

/// Stat card with glow effect
class StatCard extends StatelessWidget {
  const StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    super.key,
    this.suffix = '',
    this.onTap,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final String suffix;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.space12),
            Text(
              value + suffix,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
