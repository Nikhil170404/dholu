import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/fake_data.dart';
import '../data/providers.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Screen 7: Choose important apps.
class ChooseAppsScreen extends ConsumerWidget {
  const ChooseAppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(importantAppsProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DColors.ground,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: DSpace.screen),
            children: [
              const Text('Kaun se apps zaroori hain?', style: DText.title),
              const SizedBox(height: 6),
              Text('${on.length} apps chune gaye', style: DText.caption),
              const SizedBox(height: DSpace.section),
              DCard(
                child: Column(children: [
                  for (var i = 0; i < fakeApps.length; i++) ...[
                    if (i > 0) const Divider(indent: 66),
                    MergeSemantics(
                      child: InkWell(
                        onTap: () => ref.read(importantAppsProvider.notifier).toggle(fakeApps[i].pkg, !on.contains(fakeApps[i].pkg)),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 60),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(children: [
                              IconTile(fakeApps[i].icon),
                              const SizedBox(width: 12),
                              Expanded(child: Text(fakeApps[i].name, style: DText.bodyStrong)),
                              Switch(
                                value: on.contains(fakeApps[i].pkg),
                                onChanged: (v) => ref.read(importantAppsProvider.notifier).toggle(fakeApps[i].pkg, v),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: DSpace.section),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(DSpace.screen, 8, DSpace.screen, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Baaki apps chhupe rahenge', style: DText.caption),
              const SizedBox(height: 10),
              DButton(label: 'Ho gaya', onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
            ]),
          ),
        ),
      ]),
    );
  }
}
