import 'package:flutter/material.dart';

/// A subtle breathing pulse animation widget.
/// Ideal for indicating active running snooker tables or live match timers.
class PulsingBadge extends StatefulWidget {
  final Color color;
  final double size;
  final Widget? child;

  const PulsingBadge({
    super.key,
    required this.color,
    this.size = 10,
    this.child,
  });

  @override
  State<PulsingBadge> createState() => _PulsingBadgeState();
}

class _PulsingBadgeState extends State<PulsingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.35).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer breathing halo
            Container(
              width: widget.size * _pulseAnimation.value,
              height: widget.size * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withAlpha(
                  (60 / _pulseAnimation.value).round().clamp(10, 80),
                ),
              ),
            ),
            // Core solid dot or custom child
            widget.child ??
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withAlpha(180),
                        blurRadius: 6 * _pulseAnimation.value,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
          ],
        );
      },
    );
  }
}
