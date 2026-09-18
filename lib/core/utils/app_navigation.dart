import 'package:flutter/material.dart';

/// Navigation utilities providing smooth transitions for screen pushes.
class AppNavigation {
  AppNavigation._();

  /// Pushes a screen with a smooth ease-out slide and fade transition.
  /// Fully typed, returns `Future<T?>` matching Navigator.push semantics.
  static Future<T?> pushSmooth<T>(
    BuildContext context,
    Widget screen, {
    Duration duration = const Duration(milliseconds: 280),
    Duration reverseDuration = const Duration(milliseconds: 220),
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.06);
          const end = Offset.zero;
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: end).animate(curvedAnimation),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
              child: child,
            ),
          );
        },
        transitionDuration: duration,
        reverseTransitionDuration: reverseDuration,
      ),
    );
  }
}
