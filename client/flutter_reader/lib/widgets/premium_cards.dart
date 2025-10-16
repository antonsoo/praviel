import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';

/// Premium card components with advanced shadows, gradients, and effects
/// Modern, elegant cards for various content types

/// Elevated card with layered shadows
class ElevatedCard extends StatelessWidget {
  const ElevatedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VibrantSpacing.md),
    this.margin,
    this.borderRadius,
    this.gradient,
    this.color,
    this.elevation = 2,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Gradient? gradient;
  final Color? color;
  final double elevation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(VibrantRadius.lg);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? colorScheme.surface) : null,
        borderRadius: radius,
        boxShadow: elevation > 0
            ? [
                // Primary shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08 * elevation),
                  blurRadius: 12 * elevation,
                  offset: Offset(0, 4 * elevation),
                ),
                // Ambient shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04 * elevation),
                  blurRadius: 6 * elevation,
                  offset: Offset(0, 2 * elevation),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Gradient card with glow effect
class GlowCard extends StatefulWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.gradient,
    this.glowColor,
    this.padding = const EdgeInsets.all(VibrantSpacing.md),
    this.margin,
    this.borderRadius,
    this.onTap,
    this.animated = false,
  });

  final Widget child;
  final Gradient? gradient;
  final Color? glowColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool animated;

  @override
  State<GlowCard> createState() => _GlowCardState();
}

class _GlowCardState extends State<GlowCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animated) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradient = widget.gradient ?? VibrantTheme.heroGradient;
    final glowColor = widget.glowColor ?? colorScheme.primary;
    final radius =
        widget.borderRadius ?? BorderRadius.circular(VibrantRadius.lg);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          return Container(
            margin: widget.margin,
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withValues(
                    alpha: widget.animated
                        ? _glowAnimation.value
                        : (_isHovered ? 0.5 : 0.3),
                  ),
                  blurRadius: _isHovered ? 24 : 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: radius,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: radius,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: radius,
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  child: Padding(padding: widget.padding, child: widget.child),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Stat card - for displaying metrics with icon
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.gradient,
    this.trend,
    this.trendValue,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData? icon;
  final Gradient? gradient;
  final bool? trend; // true = up, false = down, null = neutral
  final String? trendValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = this.gradient ?? VibrantTheme.heroGradient;

    return ElevatedCard(
      onTap: onTap,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(VibrantSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: VibrantSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (trend != null && trendValue != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: trend!
                        ? colorScheme.tertiary.withValues(alpha: 0.1)
                        : colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend! ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trend!
                            ? colorScheme.tertiary
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trendValue!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: trend!
                              ? colorScheme.tertiary
                              : colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feature card - highlight card with icon and description
class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.gradient,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData? icon;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = this.gradient ?? VibrantTheme.heroGradient;

    return ElevatedCard(
      onTap: onTap,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.md),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.xs),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero card - large prominent card with background image
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.child,
    this.height = 200,
    this.gradient,
    this.backgroundImage,
    this.onTap,
  });

  final Widget child;
  final double height;
  final Gradient? gradient;
  final ImageProvider? backgroundImage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final gradient = this.gradient ?? VibrantTheme.heroGradient;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        boxShadow: VibrantShadow.lg(Theme.of(context).colorScheme),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image if provided
            if (backgroundImage != null)
              Image(image: backgroundImage!, fit: BoxFit.cover),
            // Gradient overlay
            Container(decoration: BoxDecoration(gradient: gradient)),
            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Expandable card - card that can expand to show more content
class ExpandableCard extends StatefulWidget {
  const ExpandableCard({
    super.key,
    required this.header,
    required this.expandedContent,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  final Widget header;
  final Widget expandedContent;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.normal,
    );
    _iconRotation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));

    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
      widget.onExpansionChanged?.call(_isExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpansion,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: Row(
                  children: [
                    Expanded(child: widget.header),
                    RotationTransition(
                      turns: _iconRotation,
                      child: const Icon(Icons.keyboard_arrow_down),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: VibrantDuration.normal,
            curve: VibrantCurve.smooth,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VibrantSpacing.md,
                      0,
                      VibrantSpacing.md,
                      VibrantSpacing.md,
                    ),
                    child: widget.expandedContent,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Swipeable card - card with swipe actions
class SwipeableCard extends StatelessWidget {
  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.leftActionColor,
    this.rightActionColor,
    this.leftActionIcon = Icons.delete,
    this.rightActionIcon = Icons.archive,
  });

  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final Color? leftActionColor;
  final Color? rightActionColor;
  final IconData leftActionIcon;
  final IconData rightActionIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: UniqueKey(),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart && onSwipeLeft != null) {
          onSwipeLeft!();
        } else if (direction == DismissDirection.startToEnd &&
            onSwipeRight != null) {
          onSwipeRight!();
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: VibrantSpacing.lg),
        decoration: BoxDecoration(
          color: rightActionColor ?? colorScheme.tertiary,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
        ),
        child: Icon(rightActionIcon, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: VibrantSpacing.lg),
        decoration: BoxDecoration(
          color: leftActionColor ?? colorScheme.error,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
        ),
        child: Icon(leftActionIcon, color: Colors.white),
      ),
      child: child,
    );
  }
}
