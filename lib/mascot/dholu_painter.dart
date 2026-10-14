import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

enum DholuPose { idle, drumRoll, peek, happy, muted }

/// Paints Dholu in the 120x120 viewBox from PROJECT_BRIEF.md section 7.
/// The drum pose extends below the box (to y=126), so the painter maps a
/// 120x[120 or 130] box onto the canvas.
class DholuPainter extends CustomPainter {
  DholuPainter({
    this.pose = DholuPose.idle,
    this.blink = 0,
    this.leftStick = 0,
    this.rightStick = 0,
    this.dotPulse = 1,
    this.lookX = 0,
    this.zFloat = 0,
  });

  final DholuPose pose;

  /// 0 = eyes open, 1 = closed.
  final double blink;

  /// Stick angles in radians (drum pose).
  final double leftStick;
  final double rightStick;

  /// Antenna dot scale, 1 = normal.
  final double dotPulse;

  /// Eye shift in viewBox units (negative = look left).
  final double lookX;

  /// 0..1 progress of the floating "z" (muted pose).
  final double zFloat;

  static double heightFor(DholuPose p) => p == DholuPose.drumRoll ? 130 : 120;
  static double aspectFor(DholuPose p) => 120 / heightFor(p);

  static final _ink = Paint()..color = DColors.ink;
  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final h = heightFor(pose);
    final s = math.min(size.width / 120, size.height / h);
    canvas.save();
    canvas.translate((size.width - 120 * s) / 2, (size.height - h * s) / 2);
    canvas.scale(s);

    final dotColor = switch (pose) {
      DholuPose.happy => DColors.success,
      DholuPose.muted => DColors.muted,
      _ => DColors.urgentDot,
    };

    // Antenna + dot.
    canvas.drawLine(
      const Offset(60, 22),
      const Offset(60, 11),
      _stroke(DColors.ink, 3),
    );
    canvas.drawCircle(const Offset(60, 8), 5 * dotPulse, _fill(dotColor));

    // Feet.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(42, 104), width: 24, height: 12),
      _fill(DColors.accentDark),
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(78, 104), width: 24, height: 12),
      _fill(DColors.accentDark),
    );

    if (pose == DholuPose.drumRoll) _drum(canvas);

    // Body + face plate.
    canvas.drawRRect(
      RRect.fromRectXY(const Rect.fromLTWH(16, 20, 88, 82), 40, 40),
      _fill(DColors.accent),
    );
    canvas.drawRRect(
      RRect.fromRectXY(const Rect.fromLTWH(27, 36, 66, 52), 26, 26),
      _fill(DColors.facePlate),
    );

    _face(canvas);

    // Hands (drum pose draws them with the sticks).
    if (pose != DholuPose.drumRoll) {
      canvas.drawCircle(const Offset(14, 72), 7, _fill(DColors.accentDark));
      canvas.drawCircle(const Offset(106, 72), 7, _fill(DColors.accentDark));
    }

    if (pose == DholuPose.muted) _z(canvas);
    canvas.restore();
  }

  void _face(Canvas canvas) {
    final alert = pose == DholuPose.drumRoll;
    final eyeR = alert ? 9.0 : 8.0;
    final dx = pose == DholuPose.peek
        ? lookX - 3
        : lookX; // peek looks toward the screen (left)
    final lx = 46 + dx, rx = 74 + dx;

    // Cheeks.
    canvas.drawCircle(const Offset(37, 73), 4, _fill(DColors.cheek));
    canvas.drawCircle(const Offset(83, 73), 4, _fill(DColors.cheek));

    switch (pose) {
      case DholuPose.happy:
        // Eyes as arcs.
        for (final x in [46.0, 74.0]) {
          final p = Path()
            ..moveTo(x - 8, 60)
            ..quadraticBezierTo(x, 48, x + 8, 60);
          canvas.drawPath(p, _stroke(DColors.ink, 3.5));
        }
        // Open smile with tongue.
        final mouth = Path()
          ..moveTo(50, 70)
          ..quadraticBezierTo(60, 90, 70, 70)
          ..close();
        canvas.drawPath(mouth, _fill(DColors.ink));
        canvas.save();
        canvas.clipPath(mouth);
        canvas.drawOval(
          Rect.fromCenter(center: const Offset(60, 80), width: 12, height: 9),
          _fill(DColors.cheek),
        );
        canvas.restore();
      case DholuPose.muted:
        for (final x in [46.0, 74.0]) {
          canvas.drawLine(
            Offset(x - 7, 58),
            Offset(x + 7, 58),
            _stroke(DColors.ink, 3),
          );
        }
        canvas.drawLine(
          const Offset(53, 76),
          const Offset(67, 76),
          _stroke(DColors.ink, 3),
        );
      default:
        final open = 1 - blink;
        for (final x in [lx, rx]) {
          canvas.save();
          canvas.translate(x, 58);
          canvas.scale(1, math.max(open, 0.08));
          canvas.drawCircle(Offset.zero, eyeR, _ink);
          canvas.restore();
        }
        if (open > 0.5) {
          final glint = Paint()..color = Colors.white;
          canvas.drawCircle(Offset(lx + 2.5, 55.5), 2.5, glint);
          canvas.drawCircle(Offset(rx + 2.5, 55.5), 2.5, glint);
        }
        if (alert) {
          canvas.drawOval(
            Rect.fromCenter(
              center: const Offset(60, 76),
              width: 10,
              height: 12,
            ),
            _ink,
          );
        } else {
          final smile = Path()
            ..moveTo(52, 72)
            ..quadraticBezierTo(60, 80, 68, 72);
          canvas.drawPath(smile, _stroke(DColors.ink, 3));
        }
    }
  }

  void _drum(Canvas canvas) {
    // Drum below the body.
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(28, 96, 64, 30),
      const Radius.circular(6),
    );
    canvas.drawRRect(body, _fill(DColors.drum));
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(60, 96), width: 64, height: 12),
      _fill(DColors.drumLight),
    );
    // Two sticks, rotated about the hand points; hands drawn on top.
    _stick(canvas, const Offset(14, 72), leftStick, flip: false);
    _stick(canvas, const Offset(106, 72), rightStick, flip: true);
  }

  void _stick(Canvas canvas, Offset hand, double angle, {required bool flip}) {
    canvas.save();
    canvas.translate(hand.dx, hand.dy);
    canvas.rotate(angle);
    final end = Offset(flip ? -18 : 18, 22);
    canvas.drawLine(Offset.zero, end, _stroke(DColors.ink, 3.5));
    canvas.drawCircle(end, 3, _fill(DColors.ink));
    canvas.restore();
    canvas.drawCircle(hand, 7, _fill(DColors.accentDark));
  }

  void _z(Canvas canvas) {
    final t = zFloat;
    final tp = TextPainter(
      text: TextSpan(
        text: 'z',
        style: TextStyle(
          fontFamily: 'PlusJakartaSans',
          fontSize: 14 + 4 * t,
          fontWeight: FontWeight.w700,
          color: DColors.muted.withValues(alpha: 1 - t),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(96 + 6 * t, 18 - 14 * t));
  }

  @override
  bool shouldRepaint(DholuPainter o) =>
      o.pose != pose ||
      o.blink != blink ||
      o.leftStick != leftStick ||
      o.rightStick != rightStick ||
      o.dotPulse != dotPulse ||
      o.lookX != lookX ||
      o.zFloat != zFloat;
}
