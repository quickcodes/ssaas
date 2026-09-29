import 'package:flutter/services.dart';

/// Centralized tactile haptic feedback utility.
/// Provides subtle physical vibration on interactive triggers for iOS & Android.
class AppHaptics {
  AppHaptics._();

  /// Subtle click for tabs, filters, and small toggles.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Gentle tap feedback for button presses, cards, and list item taps.
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium tap feedback for impactful actions (starting match, timer pause/resume).
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Celebratory or completed action feedback (successful settlement, checkout).
  static void success() {
    HapticFeedback.heavyImpact();
  }

  /// Alert feedback on invalid inputs or denied actions.
  static void error() {
    HapticFeedback.vibrate();
  }
}
