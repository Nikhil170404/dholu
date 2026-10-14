import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_providers.dart';
import '../native/native_bridge.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Screen 2: Quick tips + permission explainer (explain first, then deep-link to system settings).
class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});
  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen>
    with WidgetsBindingObserver {
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waiting) {
      _check();
    }
  }

  Future<void> _check() async {
    final granted = await ref.read(nativeBridgeProvider).isAccessGranted();
    if (granted && mounted) {
      await ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(onboarded: true));
      if (mounted) {
        context.go('/apps?first=1');
      }
    }
  }

  Future<void> _grant() async {
    await ref.read(notifierProvider).requestPermission();
    _waiting = true;
    await ref.read(nativeBridgeProvider).openAccessSettings();
  }

  Future<void> _skip() async {
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(onboarded: true));
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final tips = [
      (Icons.apps_rounded, tr('tip1_t'), tr('tip1_d')),
      (Icons.lock_clock_rounded, tr('tip2_t'), tr('tip2_d')),
      (Icons.touch_app_rounded, tr('tip3_t'), tr('tip3_d')),
    ];
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DSpace.screen),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(tr('tips_title'), style: DText.title),
                const SizedBox(height: 24),
                DCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < tips.length; i++) ...[
                        if (i > 0) const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconTile(
                                tips[i].$1,
                                color: DColors.accentTint,
                                iconColor: DColors.accentDark,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tips[i].$2, style: DText.bodyStrong),
                                    const SizedBox(height: 2),
                                    Text(tips[i].$3, style: DText.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: DColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(tr('privacy_line'), style: DText.caption),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(tr('access_why'), style: DText.caption),
                const SizedBox(height: 32),
                DButton(label: tr('btn_access'), onPressed: _grant),
                const SizedBox(height: 4),
                Center(child: DTextButton(tr('later'), onPressed: _skip)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
