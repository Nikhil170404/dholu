import 'package:flutter/material.dart';
import '../mascot/dholu_widget.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';

/// Screen 12: in-app urgent alert. A dark slatted roller shutter unrolls from
/// the top edge (0.8 s), slats fade to reveal a white summary card, a yellow
/// pull handle sits on the bottom edge and Dholu slides in holding it. Holds
/// ~3 s, then rolls back up. Plays once per alert; swipe up to dismiss.
class ShutterAlert extends StatefulWidget {
  const ShutterAlert({
    super.key,
    required this.title,
    required this.source,
    this.onOpen,
    this.onFinished,
    this.autoPlay = true,
  });

  final String title;
  final String source;

  /// Card tapped.
  final VoidCallback? onOpen;

  /// Fired once the shutter has fully rolled back up.
  final VoidCallback? onFinished;
  final bool autoPlay;

  @override
  State<ShutterAlert> createState() => _ShutterAlertState();
}

class _ShutterAlertState extends State<ShutterAlert> with SingleTickerProviderStateMixin {
  static const _total = 5.0; // seconds
  static const _unroll = 0.8, _reveal = 0.4, _hold = 3.0; // roll-up = remainder (0.8)
  static const _cardHeight = 152.0;

  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 5000));

  double get _rollStart => (_unroll + _reveal + _hold) / _total;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onFinished?.call();
    });
    if (widget.autoPlay) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double start, double len) =>
      (((_c.value * _total) - start) / len).clamp(0.0, 1.0);

  void _dismiss() {
    // Only once the card is fully shown; otherwise it would pop.
    if (_c.value >= (_unroll + _reveal) / _total && _c.value < _rollStart) {
      _c.value = _rollStart;
      _c.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final down = Curves.easeInOut.transform(_seg(0, _unroll));
        final reveal = Curves.easeInOut.transform(_seg(_unroll, _reveal));
        final up = Curves.easeInOut.transform(_seg(_unroll + _reveal + _hold, _total - _unroll - _reveal - _hold));
        final open = down * (1 - up);
        final slats = (1 - reveal);
        // Dholu slides in just after the shutter lands, out with the roll-up.
        final dIn = Curves.easeOut.transform(_seg(_unroll * 0.7, 0.5));
        final dholuShift = (1 - dIn * (1 - up)) * 90;
        final h = _cardHeight * open;

        return GestureDetector(
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < -150) _dismiss();
          },
          onTap: widget.onOpen,
          child: SizedBox(
            height: _cardHeight + 40,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Card + shutter, clipped to the unrolled height.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: h,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.bottomCenter,
                      minHeight: _cardHeight,
                      maxHeight: _cardHeight,
                      child: Stack(children: [
                        Positioned.fill(child: _Card(title: widget.title, source: widget.source)),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Opacity(opacity: slats, child: const _Slats()),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
                if (open > 0.02) ...[
                  // Yellow pull handle on the bottom edge.
                  Positioned(
                    top: h - 5,
                    right: 96,
                    child: Container(
                      width: 56,
                      height: 10,
                      decoration: BoxDecoration(
                        color: DColors.drum,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: DColors.drumLight, width: 1),
                      ),
                    ),
                  ),
                  Positioned(
                    top: h - 32,
                    right: 24,
                    child: Transform.translate(
                      offset: Offset(dholuShift, 0),
                      child: const Dholu(size: 56, lookX: -3),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.source});
  final String title, source;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        padding: const EdgeInsets.fromLTRB(20, 36, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(DRadius.feature)),
          boxShadow: [BoxShadow(color: Color(0x330B1220), blurRadius: 18, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: DColors.urgentDot, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text('ZAROORI  ·  $source', style: DText.caption.copyWith(letterSpacing: 0.6, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text(title, style: DText.heading, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Tap karke dekho  ·  upar swipe karo band karne ke liye', style: DText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
}

/// Dark roller-shutter slats.
class _Slats extends StatelessWidget {
  const _Slats();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SlatPainter());
}

class _SlatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndCorners(Offset.zero & size,
        bottomLeft: const Radius.circular(DRadius.feature), bottomRight: const Radius.circular(DRadius.feature));
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(Offset.zero & size, Paint()..color = DColors.ink);
    const slat = 14.0;
    for (double y = 0; y < size.height; y += slat) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1.5), Paint()..color = const Color(0xFF26324A));
      canvas.drawRect(Rect.fromLTWH(0, y + 1.5, size.width, 3), Paint()..color = const Color(0xFF16203A));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_) => false;
}
