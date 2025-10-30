/// Premium page transitions for 2025 modern feel
library;

import 'package:flutter/material.dart';

/// Smooth slide-up transition
class SlideUpPageRoute<T> extends PageRoute<T> {
  SlideUpPageRoute({
    required this.builder,
    super.settings,
    this.duration = const Duration(milliseconds: 400),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, 1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    final tween = Tween(begin: begin, end: end)
        .chain(CurveTween(curve: curve));

    final offsetAnimation = animation.drive(tween);

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeIn,
    );

    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}

/// Smooth fade-in transition
class FadePageRoute<T> extends PageRoute<T> {
  FadePageRoute({
    required this.builder,
    super.settings,
    this.duration = const Duration(milliseconds: 300),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: child,
    );
  }
}

/// Smooth scale-fade transition
class ScaleFadePageRoute<T> extends PageRoute<T> {
  ScaleFadePageRoute({
    required this.builder,
    super.settings,
    this.duration = const Duration(milliseconds: 350),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = 0.92;
    const end = 1.0;

    final scaleAnimation = Tween<double>(
      begin: begin,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ),
    );

    final fadeAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeIn,
    );

    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(
        opacity: fadeAnimation,
        child: child,
      ),
    );
  }
}

/// Shared axis X transition (Material 3 style)
class SharedAxisXPageRoute<T> extends PageRoute<T> {
  SharedAxisXPageRoute({
    required this.builder,
    super.settings,
    this.duration = const Duration(milliseconds: 300),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const enterOffset = Offset(0.05, 0.0);
    const exitOffset = Offset(-0.05, 0.0);

    final enterTween = Tween(begin: enterOffset, end: Offset.zero)
        .chain(CurveTween(curve: Curves.easeOutCubic));

    final exitTween = Tween(begin: Offset.zero, end: exitOffset)
        .chain(CurveTween(curve: Curves.easeInCubic));

    final enterAnimation = animation.drive(enterTween);
    final exitAnimation = secondaryAnimation.drive(exitTween);

    final enterFade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    );

    final exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    return SlideTransition(
      position: enterAnimation,
      child: FadeTransition(
        opacity: enterFade,
        child: SlideTransition(
          position: exitAnimation,
          child: FadeTransition(
            opacity: exitFade,
            child: child,
          ),
        ),
      ),
    );
  }
}
