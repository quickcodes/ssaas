import 'package:flutter/material.dart';

/// Screen breakpoint helpers and adaptive layout utilities for CueClub OS.
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 680.0;
  static const double tabletBreakpoint = 1050.0;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Returns a responsive value depending on the screen size.
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

/// Helper to present dialogs adaptively:
/// - On compact mobile screens (< 680px), shows a modern drag-enabled bottom sheet.
/// - On tablets & desktops (>= 680px), shows a centered glassmorphic dialog.
Future<T?> showAdaptiveModal<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
}) {
  if (Responsive.isMobile(context)) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: builder(ctx),
        ),
      ),
    );
  } else {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: builder,
    );
  }
}
