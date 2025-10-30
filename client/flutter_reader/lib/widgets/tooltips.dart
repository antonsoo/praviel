import 'package:flutter/material.dart';
import '../theme/vibrant_theme.dart';
import '../theme/vibrant_animations.dart';

/// Modern tooltip system for better user guidance
/// Provides contextual help and information

/// Enhanced tooltip with custom styling
class EnhancedTooltip extends StatelessWidget {
  const EnhancedTooltip({
    super.key,
    required this.message,
    required this.child,
    this.gradient,
    this.icon,
    this.richMessage,
  });

  final String message;
  final Widget child;
  final Gradient? gradient;
  final IconData? icon;
  final InlineSpan? richMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Tooltip(
      message: message,
      richMessage: richMessage,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? colorScheme.inverseSurface : null,
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
        boxShadow: VibrantShadow.md(colorScheme),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.sm,
      ),
      margin: const EdgeInsets.all(VibrantSpacing.sm),
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: colorScheme.onInverseSurface,
      ),
      preferBelow: false,
      verticalOffset: 20,
      child: child,
    );
  }
}

/// Tutorial tooltip - for onboarding flows
class TutorialTooltip extends StatefulWidget {
  const TutorialTooltip({
    super.key,
    required this.message,
    required this.child,
    this.title,
    this.gradient,
    this.onDismiss,
    this.showArrow = true,
    this.position = TooltipPosition.bottom,
  });

  final String message;
  final Widget child;
  final String? title;
  final Gradient? gradient;
  final VoidCallback? onDismiss;
  final bool showArrow;
  final TooltipPosition position;

  @override
  State<TutorialTooltip> createState() => _TutorialTooltipState();
}

class _TutorialTooltipState extends State<TutorialTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  OverlayEntry? _overlayEntry;
  final GlobalKey _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: VibrantDuration.normal,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: VibrantCurve.smooth));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTooltip();
    });
  }

  @override
  void dispose() {
    _removeTooltip();
    _controller.dispose();
    super.dispose();
  }

  void _showTooltip() {
    final RenderBox? renderBox =
        _childKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => _TooltipOverlay(
        position: position,
        size: size,
        title: widget.title,
        message: widget.message,
        gradient: widget.gradient,
        fadeAnimation: _fadeAnimation,
        slideAnimation: _slideAnimation,
        onDismiss: _dismissTooltip,
        showArrow: widget.showArrow,
        tooltipPosition: widget.position,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _dismissTooltip() {
    _controller.reverse().then((_) {
      _removeTooltip();
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(key: _childKey, child: widget.child);
  }
}

class _TooltipOverlay extends StatelessWidget {
  const _TooltipOverlay({
    required this.position,
    required this.size,
    required this.title,
    required this.message,
    required this.gradient,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.onDismiss,
    required this.showArrow,
    required this.tooltipPosition,
  });

  final Offset position;
  final Size size;
  final String? title;
  final String message;
  final Gradient? gradient;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final VoidCallback onDismiss;
  final bool showArrow;
  final TooltipPosition tooltipPosition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradient = this.gradient ?? VibrantTheme.heroGradient;

    // Calculate tooltip position
    final screenSize = MediaQuery.of(context).size;
    double left = position.dx;
    double top = tooltipPosition == TooltipPosition.bottom
        ? position.dy + size.height + 12
        : position.dy - 100;

    // Ensure tooltip stays on screen
    if (left + 300 > screenSize.width) {
      left = screenSize.width - 320;
    }
    if (left < 20) {
      left = 20;
    }

    return Stack(
      children: [
        // Backdrop
        GestureDetector(
          onTap: onDismiss,
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),
        // Tooltip
        Positioned(
          left: left,
          top: top,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: SlideTransition(
              position: slideAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                    boxShadow: VibrantShadow.lg(colorScheme),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          if (title != null)
                            Expanded(
                              child: Text(
                                title!,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: onDismiss,
                            iconSize: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      if (title != null)
                        const SizedBox(height: VibrantSpacing.xs),
                      Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

enum TooltipPosition { top, bottom, left, right }

/// Info button with tooltip
class InfoButton extends StatelessWidget {
  const InfoButton({
    super.key,
    required this.message,
    this.size = 20,
    this.color,
  });

  final String message;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return EnhancedTooltip(
      message: message,
      child: Icon(
        Icons.info_outline,
        size: size,
        color: color ?? colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// Help text with expandable tooltip
class HelpText extends StatefulWidget {
  const HelpText({super.key, required this.text, required this.helpMessage});

  final String text;
  final String helpMessage;

  @override
  State<HelpText> createState() => _HelpTextState();
}

class _HelpTextState extends State<HelpText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(widget.text, style: theme.textTheme.bodyMedium),
            ),
            IconButton(
              icon: Icon(
                _isExpanded ? Icons.help : Icons.help_outline,
                size: 20,
              ),
              color: colorScheme.primary,
              onPressed: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        AnimatedSize(
          duration: VibrantDuration.normal,
          curve: VibrantCurve.smooth,
          child: _isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: VibrantSpacing.xs),
                  child: Container(
                    padding: const EdgeInsets.all(VibrantSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    ),
                    child: Text(
                      widget.helpMessage,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Tooltip showcase - displays multiple tooltips in sequence
class TooltipShowcase extends StatefulWidget {
  const TooltipShowcase({
    super.key,
    required this.items,
    required this.child,
    this.onComplete,
  });

  final List<ShowcaseItem> items;
  final Widget child;
  final VoidCallback? onComplete;

  @override
  State<TooltipShowcase> createState() => _TooltipShowcaseState();
}

class _TooltipShowcaseState extends State<TooltipShowcase> {
  // Future enhancements could add next/previous functionality
  // int _currentIndex = 0;
  // void _next() {
  //   if (_currentIndex < widget.items.length - 1) {
  //     setState(() => _currentIndex++);
  //   } else {
  //     widget.onComplete?.call();
  //   }
  // }

  // void _previous() {
  //   if (_currentIndex > 0) {
  //     setState(() => _currentIndex--);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class ShowcaseItem {
  final GlobalKey key;
  final String title;
  final String message;

  ShowcaseItem({required this.key, required this.title, required this.message});
}

/// Badge tooltip - small badge with count and tooltip
class BadgeTooltip extends StatelessWidget {
  const BadgeTooltip({
    super.key,
    required this.child,
    required this.count,
    required this.message,
    this.color,
  });

  final Widget child;
  final int count;
  final String message;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            top: -8,
            right: -8,
            child: EnhancedTooltip(
              message: message,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color ?? colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: VibrantShadow.sm(colorScheme),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
