import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../theme/vibrant_animations.dart';
import '../../theme/advanced_micro_interactions.dart';

/// Modern action button designs for 2025 UI standards
/// FABs, pill buttons, icon buttons with animations

/// Extended FAB with animation
class ExtendedActionButton extends StatefulWidget {
  const ExtendedActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.gradient,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;

  @override
  State<ExtendedActionButton> createState() => _ExtendedActionButtonState();
}

class _ExtendedActionButtonState extends State<ExtendedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.quick,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: VibrantCurve.snappy),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
        AdvancedHaptics.medium();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: VibrantDuration.normal,
          curve: VibrantCurve.smooth,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExtended ? VibrantSpacing.xl : VibrantSpacing.lg,
            vertical: VibrantSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: widget.gradient ?? VibrantTheme.auroraGradient,
            color: widget.gradient == null
                ? (widget.backgroundColor ?? colorScheme.primary)
                : null,
            borderRadius: BorderRadius.circular(VibrantRadius.full),
            boxShadow: [
              BoxShadow(
                color: (widget.gradient != null
                        ? Colors.black
                        : widget.backgroundColor ?? colorScheme.primary)
                    .withValues(alpha: _isPressed ? 0.2 : 0.3),
                blurRadius: _isPressed ? 12 : 20,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                color: widget.foregroundColor ?? Colors.white,
                size: 24,
              ),
              if (widget.isExtended) ...[
                const SizedBox(width: VibrantSpacing.md),
                Text(
                  widget.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: widget.foregroundColor ?? Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped button
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.variant = PillButtonVariant.primary,
    this.size = PillButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final PillButtonVariant variant;
  final PillButtonSize size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final EdgeInsets padding;
    final TextStyle? textStyle;
    final double iconSize;

    switch (size) {
      case PillButtonSize.small:
        padding = const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.md,
          vertical: VibrantSpacing.xs,
        );
        textStyle = theme.textTheme.labelSmall;
        iconSize = 16;
        break;
      case PillButtonSize.medium:
        padding = const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.lg,
          vertical: VibrantSpacing.sm,
        );
        textStyle = theme.textTheme.labelMedium;
        iconSize = 18;
        break;
      case PillButtonSize.large:
        padding = const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.xl,
          vertical: VibrantSpacing.md,
        );
        textStyle = theme.textTheme.labelLarge;
        iconSize = 20;
        break;
    }

    final Color backgroundColor;
    final Color foregroundColor;

    switch (variant) {
      case PillButtonVariant.primary:
        backgroundColor = colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        break;
      case PillButtonVariant.secondary:
        backgroundColor = colorScheme.secondaryContainer;
        foregroundColor = colorScheme.onSecondaryContainer;
        break;
      case PillButtonVariant.outlined:
        backgroundColor = Colors.transparent;
        foregroundColor = colorScheme.primary;
        break;
      case PillButtonVariant.text:
        backgroundColor = Colors.transparent;
        foregroundColor = colorScheme.primary;
        break;
    }

    return PremiumButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      padding: padding,
      borderRadius: VibrantRadius.full,
      scaleDown: 0.97,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize),
            const SizedBox(width: VibrantSpacing.xs),
          ],
          Text(
            label,
            style: textStyle?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (trailingIcon != null) ...[
            const SizedBox(width: VibrantSpacing.xs),
            Icon(trailingIcon, size: iconSize),
          ],
        ],
      ),
    );
  }
}

enum PillButtonVariant { primary, secondary, outlined, text }

enum PillButtonSize { small, medium, large }

/// Animated icon button with ripple
class AnimatedIconButton extends StatefulWidget {
  const AnimatedIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 48,
    this.iconSize = 24,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;
  final Widget? badge;

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.fast,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    AdvancedHaptics.light();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = GestureDetector(
      onTap: widget.onPressed != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor ??
                colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color: widget.foregroundColor ?? colorScheme.onSurface,
                ),
              ),
              if (widget.badge != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: widget.badge!,
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }

    return button;
  }
}

/// Toggle button with animation
class AnimatedToggleButton extends StatefulWidget {
  const AnimatedToggleButton({
    super.key,
    required this.isSelected,
    required this.onChanged,
    required this.icon,
    required this.selectedIcon,
    this.label,
    this.selectedLabel,
  });

  final bool isSelected;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final IconData selectedIcon;
  final String? label;
  final String? selectedLabel;

  @override
  State<AnimatedToggleButton> createState() => _AnimatedToggleButtonState();
}

class _AnimatedToggleButtonState extends State<AnimatedToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.normal,
      value: widget.isSelected ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(AnimatedToggleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
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
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        AdvancedHaptics.light();
        widget.onChanged(!widget.isSelected);
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value;
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.lg,
              vertical: VibrantSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Color.lerp(
                colorScheme.surfaceContainer,
                colorScheme.primaryContainer,
                progress,
              ),
              borderRadius: BorderRadius.circular(VibrantRadius.full),
              border: Border.all(
                color: Color.lerp(
                  colorScheme.outline.withValues(alpha: 0.3),
                  colorScheme.primary,
                  progress,
                )!,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isSelected ? widget.selectedIcon : widget.icon,
                  color: Color.lerp(
                    colorScheme.onSurfaceVariant,
                    colorScheme.primary,
                    progress,
                  ),
                ),
                if (widget.label != null) ...[
                  const SizedBox(width: VibrantSpacing.sm),
                  Text(
                    widget.isSelected
                        ? (widget.selectedLabel ?? widget.label!)
                        : widget.label!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Color.lerp(
                        colorScheme.onSurfaceVariant,
                        colorScheme.primary,
                        progress,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Segmented button with smooth animations
class AnimatedSegmentedButton<T> extends StatelessWidget {
  const AnimatedSegmentedButton({
    super.key,
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
  });

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(VibrantRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final segment in segments)
            Expanded(
              child: GestureDetector(
                onTap: () {
                  AdvancedHaptics.light();
                  onSelectionChanged(segment.value);
                },
                child: AnimatedContainer(
                  duration: VibrantDuration.normal,
                  curve: VibrantCurve.smooth,
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.lg,
                    vertical: VibrantSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: selected == segment.value
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(VibrantRadius.full),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (segment.icon != null) ...[
                        Icon(
                          segment.icon,
                          size: 18,
                          color: selected == segment.value
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: VibrantSpacing.xs),
                      ],
                      Text(
                        segment.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selected == segment.value
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: selected == segment.value
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ButtonSegment<T> {
  const ButtonSegment({
    required this.value,
    required this.label,
    this.icon,
  });

  final T value;
  final String label;
  final IconData? icon;
}
