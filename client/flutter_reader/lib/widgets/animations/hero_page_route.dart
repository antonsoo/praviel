import 'package:flutter/material.dart';

/// Smooth hero-style page transitions for premium feel
class HeroPageRoute<T> extends PageRouteBuilder<T> {
  HeroPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 400),
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         reverseTransitionDuration: transitionDuration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Curved animation for smooth feel
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );

           // Fade + Scale transition
           return FadeTransition(
             opacity: curvedAnimation,
             child: ScaleTransition(
               scale: Tween<double>(
                 begin: 0.92,
                 end: 1.0,
               ).animate(curvedAnimation),
               child: child,
             ),
           );
         },
       );
}

/// Slide up page transition (like bottom sheet becoming full screen)
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  SlideUpPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          );
        },
      );
}

/// Shared element transition (like Material's hero but more controlled)
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  SharedAxisPageRoute({
    required WidgetBuilder builder,
    super.settings,
    SharedAxisTransitionType transitionType =
        SharedAxisTransitionType.horizontal,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionDuration: const Duration(milliseconds: 350),
         reverseTransitionDuration: const Duration(milliseconds: 300),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final curvedAnimation = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );

           Offset getBeginOffset() {
             switch (transitionType) {
               case SharedAxisTransitionType.horizontal:
                 return const Offset(1, 0);
               case SharedAxisTransitionType.vertical:
                 return const Offset(0, 1);
               case SharedAxisTransitionType.scaled:
                 return Offset.zero;
             }
           }

           if (transitionType == SharedAxisTransitionType.scaled) {
             // For scaled transition, use fade + scale
             return FadeTransition(
               opacity: curvedAnimation,
               child: ScaleTransition(
                 scale: Tween<double>(
                   begin: 0.9,
                   end: 1.0,
                 ).animate(curvedAnimation),
                 child: child,
               ),
             );
           }

           // Slide transition
           return SlideTransition(
             position: Tween<Offset>(
               begin: getBeginOffset(),
               end: Offset.zero,
             ).animate(curvedAnimation),
             child: FadeTransition(
               opacity: Tween<double>(
                 begin: 0.0,
                 end: 1.0,
               ).animate(curvedAnimation),
               child: child,
             ),
           );
         },
       );
}

enum SharedAxisTransitionType { horizontal, vertical, scaled }

/// Fade through page transition
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  FadeThroughPageRoute({required WidgetBuilder builder, super.settings})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Split the animation into two phases
          final fadeInAnimation = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
          );

          return FadeTransition(opacity: fadeInAnimation, child: child);
        },
      );
}
