import 'package:flutter/material.dart';

import 'dholu_widget.dart';

/// Dholu peeking from the right screen edge. 6 s loop: hidden 0-25%, slides to
/// ~72% visible at 40-75%, hides by 90%. Tap opens the Drum alert.
class CornerPeek extends StatefulWidget {
  const CornerPeek({
    super.key,
    this.onTap,
    this.size = 88,
    this.animate = true,
  });
  final VoidCallback? onTap;
  final double size;
  final bool animate;

  @override
  State<CornerPeek> createState() => _CornerPeekState();
}

class _CornerPeekState extends State<CornerPeek>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  static final _slide = TweenSequence<double>([
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 25),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 0.72,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(0.72), weight: 35),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.72,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
  ]);

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.repeat();
    } else {
      _c.value = 0.55; // visible still frame
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final visible = _slide.transform(_c.value);
        return Transform.translate(
          offset: Offset(widget.size * (1 - visible), 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Semantics(
          button: true,
          label: 'Dholu',
          child: Dholu(
            pose: DholuPose.peek,
            size: widget.size,
            animate: widget.animate,
          ),
        ),
      ),
    );
  }
}
