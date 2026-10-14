import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dholu_painter.dart';

export 'dholu_painter.dart' show DholuPose;

/// Reusable animated Dholu. [animate] false renders a still frame (tests, goldens).
class Dholu extends StatefulWidget {
  const Dholu({
    super.key,
    this.pose = DholuPose.idle,
    this.size = 120,
    this.animate = true,
    this.lookX = 0,
  });

  final DholuPose pose;

  /// Width in logical pixels; height follows the pose aspect ratio.
  final double size;
  final bool animate;
  final double lookX;

  @override
  State<Dholu> createState() => _DholuState();
}

class _DholuState extends State<Dholu> with TickerProviderStateMixin {
  // Master clock: 12 s so 4 s blink, 2 s bounce, 0.56 s drum bounce, 0.9 s jump
  // are all derived from elapsed time.
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _clock.repeat();
  }

  @override
  void didUpdateWidget(Dholu old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_clock.isAnimating) _clock.repeat();
    if (!widget.animate && _clock.isAnimating) _clock.stop();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  static double _tri(double t) => 1 - (2 * (t % 1) - 1).abs(); // 0..1..0

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    final h = w / DholuPainter.aspectFor(widget.pose);
    return Semantics(
      label: 'Dholu',
      child: RepaintBoundary(
        child: SizedBox(
          width: w,
          height: h,
          child: AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final sec = widget.animate ? _clock.value * 12 : 0.0;
              final scale = w / 120;
              double dy = 0, blink = 0, left = 0, right = 0, pulse = 1, z = 0;

              // Blink: closes for ~0.15 s once every 4 s.
              final b = sec % 4;
              if (b > 3.85) blink = 1 - (b - 3.925).abs() / 0.075;
              blink = blink.clamp(0.0, 1.0);

              switch (widget.pose) {
                case DholuPose.idle:
                case DholuPose.muted:
                  dy = -3 * _tri(sec / 2) * scale; // 3px bounce over 2 s
                case DholuPose.drumRoll:
                  dy = -3 * _tri(sec / 0.56) * scale; // 3px over 0.56 s
                  final e = Curves.easeInOut;
                  // left -16..+8 deg, right +16..-8 deg, 0.28 s alternate, right offset 0.14 s
                  final l = e.transform(_tri(sec / 0.56));
                  final r = e.transform(_tri((sec + 0.14) / 0.56));
                  left = _rad(-16 + 24 * l);
                  right = _rad(16 - 24 * r);
                  pulse = 1 + 0.25 * _tri(sec / 0.56);
                case DholuPose.peek:
                  pulse = 1 + 0.35 * _tri(sec / 1.0);
                case DholuPose.happy:
                  dy =
                      -14 *
                      Curves.easeOut.transform(_tri(sec / 0.9)) *
                      scale; // 14px jump
              }
              if (widget.pose == DholuPose.muted) z = (sec / 3) % 1;

              return Transform.translate(
                offset: Offset(0, dy),
                child: CustomPaint(
                  painter: DholuPainter(
                    pose: widget.pose,
                    blink: blink,
                    leftStick: left,
                    rightStick: right,
                    dotPulse: pulse,
                    lookX: widget.lookX,
                    zFloat: z,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static double _rad(double deg) => deg * math.pi / 180;
}
