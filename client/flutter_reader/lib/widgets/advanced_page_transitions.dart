import 'package:flutter/material.dart';

/// Custom page route with advanced transitions (2025 UX trend)
class AdvancedPageRoute<T> extends PageRouteBuilder<T> {
  AdvancedPageRoute({
    required Widget page,
    super.settings,
    TransitionType transitionType = TransitionType.slideFromRight,
    super.transitionDuration = const Duration(milliseconds: 350),
    super.reverseTransitionDuration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildTransition(
              transitionType,
              animation,
              secondaryAnimation,
              child,
            );
          },
        );

  static Widget _buildTransition(
    TransitionType type,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (type) {
      case TransitionType.fade:
        return FadeTransition(opacity: animation, child: child);

      case TransitionType.scale:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );

      case TransitionType.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );

      case TransitionType.slideFromBottom:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );

      case TransitionType.slideFromLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );

      case TransitionType.rotation:
        return RotationTransition(
          turns: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
            child: child,
          ),
        );

      case TransitionType.fadeScale:
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );

      case TransitionType.sharedAxis:
        const double transitionOffset = 30.0;
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(transitionOffset / 100, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset.zero,
                end: const Offset(-transitionOffset / 100, 0),
              ).animate(
                CurvedAnimation(
                  parent: secondaryAnimation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              child: child,
            ),
          ),
        );
    }
  }
}

/// Enum for transition types
enum TransitionType {
  fade,
  scale,
  slideFromRight,
  slideFromBottom,
  slideFromLeft,
  rotation,
  fadeScale,
  sharedAxis,
}

/// Modal bottom sheet with custom transition
class AdvancedModalBottomSheet extends StatelessWidget {
  const AdvancedModalBottomSheet({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius = 28.0,
  });

  final Widget child;
  final Color? backgroundColor;
  final double borderRadius;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
    double borderRadius = 28.0,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: isDismissible,
      builder: (context) => AdvancedModalBottomSheet(
        backgroundColor: backgroundColor,
        borderRadius: borderRadius,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}

/// Slide-up dialog with backdrop blur
class AdvancedDialog extends StatelessWidget {
  const AdvancedDialog({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderRadius = 28.0,
  });

  final Widget child;
  final Color? backgroundColor;
  final double borderRadius;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
    double borderRadius = 28.0,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AdvancedDialog(
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          child: child,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Material(
          color: backgroundColor ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(borderRadius),
          elevation: 24,
          child: child,
        ),
      ),
    );
  }
}

/// Hero animation wrapper with custom flight
class AdvancedHero extends StatelessWidget {
  const AdvancedHero({
    super.key,
    required this.tag,
    required this.child,
    this.flightDuration = const Duration(milliseconds: 400),
  });

  final Object tag;
  final Widget child;
  final Duration flightDuration;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.05).animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: toHeroContext.widget,
          ),
        );
      },
      child: child,
    );
  }
}
