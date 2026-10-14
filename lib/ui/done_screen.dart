import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_providers.dart';
import '../mascot/dholu_widget.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Screen 11: "Sahi chuna!" Happy Dholu with confetti.
class DoneScreen extends ConsumerStatefulWidget {
  const DoneScreen({super.key, this.next, this.animate = true});

  /// Route for the "Draft dekho" button, or null.
  final String? next;
  final bool animate;
  @override
  ConsumerState<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends ConsumerState<DoneScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) => CustomPaint(painter: _Confetti(_c.value)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(DSpace.screen),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Dholu(
                    pose: DholuPose.happy,
                    size: 160,
                    animate: widget.animate,
                  ),
                  const SizedBox(height: 24),
                  Text(tr('right_choice'), style: DText.title),
                  const Spacer(flex: 3),
                  if (widget.next != null) ...[
                    DButton(
                      label: tr('see_draft'),
                      onPressed: () => context.go(widget.next!),
                    ),
                    const SizedBox(height: 10),
                  ],
                  DButton(
                    label: tr('go_home'),
                    tint: widget.next != null,
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Confetti extends CustomPainter {
  _Confetti(this.t);
  final double t;
  static const _colors = [
    DColors.accent,
    DColors.drum,
    DColors.success,
    DColors.cheek,
    DColors.urgentDot,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    for (var i = 0; i < 36; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = 0.6 + rnd.nextDouble() * 0.8;
      final phase = rnd.nextDouble();
      final y = ((t * speed + phase) % 1.0) * (size.height + 40) - 20;
      final sway = math.sin((t * 2 * math.pi) + i) * 14;
      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(t * 2 * math.pi * speed + i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-4, -2, 8, 4),
          const Radius.circular(1.5),
        ),
        Paint()..color = _colors[i % _colors.length],
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Confetti o) => o.t != t;
}
