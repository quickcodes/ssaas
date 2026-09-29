import 'package:flutter/material.dart';
import '../../core/utils/interactive_feedback.dart';

/// A tactile wrapper widget that shrinks slightly (`0.97`) on tap down
/// and springs back with an elastic feel on release, accompanied by haptic feedback.
/// Automatically debounces rapid double-taps to ensure application-wide stability.
class BouncingTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleFactor;
  final Duration duration;
  final bool enableHaptics;
  final Duration debounceDuration;

  const BouncingTap({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleFactor = 0.97,
    this.duration = const Duration(milliseconds: 110),
    this.enableHaptics = true,
    this.debounceDuration = const Duration(milliseconds: 500),
  });

  @override
  State<BouncingTap> createState() => _BouncingTapState();
}

class _BouncingTapState extends State<BouncingTap> {
  bool _isPressed = false;
  DateTime? _lastTapTime;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    setState(() => _isPressed = true);
    if (widget.enableHaptics) {
      AppHaptics.light();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < widget.debounceDuration) {
      // Ignore rapid double tap to protect against duplicate requests
      return;
    }
    _lastTapTime = now;
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap != null ? _handleTap : null,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _isPressed ? widget.scaleFactor : 1.0,
        duration: widget.duration,
        curve: Curves.easeInOutCubic,
        child: widget.child,
      ),
    );
  }
}
