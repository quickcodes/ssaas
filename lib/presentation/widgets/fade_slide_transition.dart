import 'package:flutter/material.dart';

/// Staggered fade and slide entrance animation for list/grid items.
class FadeSlideTransitionWidget extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  const FadeSlideTransitionWidget({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 35),
    this.duration = const Duration(milliseconds: 320),
    this.offset = const Offset(0.0, 0.08),
  });

  @override
  State<FadeSlideTransitionWidget> createState() =>
      _FadeSlideTransitionWidgetState();
}

class _FadeSlideTransitionWidgetState extends State<FadeSlideTransitionWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final totalDelay = widget.delay * widget.index.clamp(0, 10);
    Future.delayed(totalDelay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
