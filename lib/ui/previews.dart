import 'package:flutter/material.dart';
import '../mascot/corner_peek.dart';
import '../mascot/dholu_widget.dart';
import '../shutter/shutter_alert.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Standalone previews: mascot poses and the shutter alert (no app state).
class MascotPreview extends StatelessWidget {
  const MascotPreview({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Meet Dholu'), backgroundColor: DColors.ground, surfaceTintColor: Colors.transparent),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(DSpace.screen),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            for (final p in DholuPose.values)
              DCard(
                padding: const EdgeInsets.all(12),
                child: Column(children: [
                  Expanded(child: Center(child: Dholu(pose: p, size: 100))),
                  Text(p.name, style: DText.caption),
                ]),
              ),
            const DCard(
              padding: EdgeInsets.all(12),
              child: Center(child: Text('Corner peek: see Home', style: DText.caption)),
            ),
          ],
        ),
      );
}

class ShutterPreview extends StatefulWidget {
  const ShutterPreview({super.key});
  @override
  State<ShutterPreview> createState() => _ShutterPreviewState();
}

class _ShutterPreviewState extends State<ShutterPreview> {
  int _run = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Shutter alert'), backgroundColor: DColors.ground, surfaceTintColor: Colors.transparent),
        body: Stack(children: [
          Positioned(
            left: 0, right: 0, top: 0,
            child: ShutterAlert(
              key: ValueKey(_run),
              title: 'Anil Sir: report 10 baje tak bhejna',
              source: 'WhatsApp',
              onFinished: () {},
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(DSpace.screen),
              child: DButton(label: 'Dobara chalao', onPressed: () => setState(() => _run++)),
            ),
          ),
          const Positioned(right: 0, bottom: 100, child: CornerPeek()),
        ]),
      );
}
