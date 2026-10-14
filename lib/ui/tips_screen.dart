import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Screen 2: Quick tips.
class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  static const _tips = [
    (Icons.apps_rounded, 'Zaroori apps chuno', 'Sirf wahi apps upar dikhenge jo aap chunoge.'),
    (Icons.lock_clock_rounded, 'Lock screen par summary', 'Subah ek chhota summary, bina phone khole.'),
    (Icons.touch_app_rounded, 'Tap karo, kaam karo', 'Reply, Pay, Track: ek tap mein sahi app khulega.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(DSpace.screen),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            const Text('3 tips, phir shuru', style: DText.title),
            const SizedBox(height: 24),
            DCard(
              child: Column(children: [
                for (var i = 0; i < _tips.length; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      IconTile(_tips[i].$1, color: DColors.accentTint, iconColor: DColors.accentDark),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_tips[i].$2, style: DText.bodyStrong),
                          const SizedBox(height: 2),
                          Text(_tips[i].$3, style: DText.caption),
                        ]),
                      ),
                    ]),
                  ),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            const Row(children: [
              Icon(Icons.shield_outlined, size: 18, color: DColors.textSecondary),
              SizedBox(width: 8),
              Expanded(child: Text('Sab kuch aapke phone par rehta hai. Kuch bhi upload nahi hota.', style: DText.caption)),
            ]),
            const Spacer(),
            // M2 wires this to the real notification-access settings page.
            DButton(label: 'Notification access do', onPressed: () => context.go('/home')),
            const SizedBox(height: 4),
            Center(child: DTextButton('Baad mein', onPressed: () => context.go('/home'))),
          ]),
        ),
      ),
    );
  }
}
