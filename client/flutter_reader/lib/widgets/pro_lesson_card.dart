import 'package:flutter/material.dart';
import '../theme/professional_theme.dart';

/// PROFESSIONAL lesson card inspired by Linear, Notion, and Apple
/// No childish gradients - just sophisticated depth and motion
class ProLessonCard extends StatefulWidget {
  const ProLessonCard({
    super.key,
    required this.title,
    required this.description,
    required this.onTap,
    this.icon,
    this.progress,
    this.isLoading = false,
    this.badge,
  });

  final String title;
  final String description;
  final VoidCallback onTap;
  final IconData? icon;
  final double? progress;
  final bool isLoading;
  final String? badge;

  @override
  State<ProLessonCard> createState() => _ProLessonCardState();
}

class _ProLessonCardState extends State<ProLessonCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoverChange(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return MouseRegion(
      onEnter: (_) => _onHoverChange(true),
      onExit: (_) => _onHoverChange(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _isPressed ? 0.98 : _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(ProRadius.lg),
                  border: Border.all(
                    color: _isHovered
                        ? colorScheme.primary.withValues(alpha: 0.2)
                        : colorScheme.outline,
                    width: 1,
                  ),
                  boxShadow: _isHovered
                      ? ProElevation.lg(colorScheme.shadow)
                      : ProElevation.sm(colorScheme.shadow),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ProRadius.lg),
                  child: Stack(
                    children: [
                      // Subtle hover gradient
                      if (_isHovered)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary.withValues(alpha: 0.02),
                                  colorScheme.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Content
                      Padding(
                        padding: const EdgeInsets.all(ProSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header row
                            Row(
                              children: [
                                if (widget.icon != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(ProSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius:
                                          BorderRadius.circular(ProRadius.sm),
                                    ),
                                    child: Icon(
                                      widget.icon,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: ProSpacing.md),
                                ],
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ),
                                if (widget.badge != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: ProSpacing.md,
                                      vertical: ProSpacing.xs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.tertiaryContainer,
                                      borderRadius:
                                          BorderRadius.circular(ProRadius.sm),
                                    ),
                                    child: Text(
                                      widget.badge!,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onTertiaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (widget.isLoading)
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        colorScheme.primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: ProSpacing.md),

                            // Description
                            Text(
                              widget.description,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),

                            // Progress bar
                            if (widget.progress != null) ...[
                              const SizedBox(height: ProSpacing.lg),
                              _buildProgressBar(
                                widget.progress!,
                                colorScheme,
                              ),
                            ],

                            const SizedBox(height: ProSpacing.lg),

                            // Action indicator
                            Row(
                              children: [
                                Text(
                                  'Continue',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: ProSpacing.xs),
                                AnimatedSlide(
                                  duration: const Duration(milliseconds: 150),
                                  offset: Offset(_isHovered ? 0.2 : 0, 0),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 16,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Loading overlay
                      if (widget.isLoading)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(ProRadius.lg),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressBar(double progress, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: ProSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(ProRadius.sm),
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact stat card for dashboard metrics
class ProStatCard extends StatelessWidget {
  const ProStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
    this.trendDirection,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  final TrendDirection? trendDirection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color? trendColor;
    if (trendDirection != null) {
      trendColor = trendDirection == TrendDirection.up
          ? colorScheme.tertiary
          : colorScheme.error;
    }

    return Container(
      padding: const EdgeInsets.all(ProSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(ProRadius.lg),
        border: Border.all(color: colorScheme.outline, width: 1),
        boxShadow: ProElevation.sm(colorScheme.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: ProSpacing.sm),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: ProSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineMedium,
          ),
          if (trend != null) ...[
            const SizedBox(height: ProSpacing.sm),
            Row(
              children: [
                if (trendDirection != null)
                  Icon(
                    trendDirection == TrendDirection.up
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 14,
                    color: trendColor,
                  ),
                if (trendDirection != null)
                  const SizedBox(width: ProSpacing.xs),
                Text(
                  trend!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: trendColor ?? colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

enum TrendDirection { up, down }
