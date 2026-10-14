import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/fake_data.dart';
import '../mascot/corner_peek.dart';
import '../shutter/shutter_alert.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Screen 6: Home. Fake data in M1.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.animate = true});
  final bool animate;
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _alertRun = 0;
  bool _alert = false;

  IconData _iconFor(ItemAction a) => switch (a) {
        ItemAction.reply => Icons.chat_bubble_outline_rounded,
        ItemAction.pay => Icons.receipt_long_outlined,
        ItemAction.track => Icons.local_shipping_outlined,
      };

  @override
  Widget build(BuildContext context) {
    const total = 1 + 3;
    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(DSpace.screen, 16, DSpace.screen, 120),
            children: [
              Row(children: [
                const Expanded(child: Text('Aaj ke zaroori updates', style: DText.title)),
                IconButton(
                  tooltip: 'Apps badlo',
                  constraints: const BoxConstraints(minWidth: DSpace.minTouch, minHeight: DSpace.minTouch),
                  onPressed: () => context.push('/apps'),
                  icon: const Icon(Icons.tune_rounded, color: DColors.ink),
                ),
              ]),
              const SizedBox(height: 6),
              Text('$total zaroori, $fakeHiddenCount chhupe', style: DText.caption),
              const SizedBox(height: DSpace.section),
              _UrgentCard(item: fakeUrgent, onAction: () => setState(() { _alert = true; _alertRun++; })),
              const SizedBox(height: 16),
              DCard(
                child: Column(children: [
                  for (var i = 0; i < fakeUpdates.length; i++) ...[
                    if (i > 0) const Divider(indent: 66),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(children: [
                        IconTile(_iconFor(fakeUpdates[i].action)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(fakeUpdates[i].title, style: DText.bodyStrong),
                            const SizedBox(height: 2),
                            Text('${fakeUpdates[i].source} mein khulega', style: DText.caption),
                          ]),
                        ),
                        const SizedBox(width: 8),
                        DButton(label: fakeUpdates[i].action.label, tint: true, expand: false, onPressed: () {}),
                      ]),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: DSpace.section),
              Center(
                child: Column(children: [
                  Text('Baaki $fakeHiddenCount chhupe hain', style: DText.bodyStrong),
                  const SizedBox(height: 2),
                  const Text('Kuch miss nahi hoga.', style: DText.caption),
                ]),
              ),
            ],
          ),
          // Dholu peeks in from the right edge; tap shows the in-app alert.
          Positioned(
            right: 0,
            bottom: 96,
            child: CornerPeek(
              animate: widget.animate,
              onTap: () => setState(() { _alert = true; _alertRun++; }),
            ),
          ),
          if (_alert)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ShutterAlert(
                key: ValueKey(_alertRun),
                title: fakeUrgent.title,
                source: fakeUrgent.source,
                onFinished: () => setState(() => _alert = false),
              ),
            ),
        ]),
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.item, required this.onAction});
  final UpdateItem item;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: DColors.ink, borderRadius: BorderRadius.circular(DRadius.feature)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const UrgentDot(),
            const SizedBox(width: 8),
            Text('ZAROORI  ·  ${item.source}',
                style: DText.caption.copyWith(color: Colors.white70, letterSpacing: 0.6, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          Text(item.title, style: DText.heading.copyWith(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 16),
          DButton(label: item.action.label, dark: true, onPressed: onAction),
        ]),
      );
}
