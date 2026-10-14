import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_providers.dart';
import '../native/native_bridge.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';
import 'widgets.dart';

/// Installed launchable apps, synced into the DB (user choices are kept).
final installedAppsSyncProvider = FutureProvider<void>((ref) async {
  final apps = await ref.watch(nativeBridgeProvider).installedApps();
  await ref.watch(repositoryProvider).syncApps(apps);
});

/// Screen 7: Choose important apps.
class ChooseAppsScreen extends ConsumerStatefulWidget {
  const ChooseAppsScreen({super.key, this.first = false});
  final bool first;
  @override
  ConsumerState<ChooseAppsScreen> createState() => _ChooseAppsScreenState();
}

class _ChooseAppsScreenState extends ConsumerState<ChooseAppsScreen> {
  String _q = '';

  void _finish() {
    if (widget.first || !context.canPop()) {
      context.go('/home');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    ref.watch(installedAppsSyncProvider);
    final apps = ref.watch(appPrefsProvider).asData?.value ?? const [];
    final shown = apps
        .where((a) => a.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    final selected = apps.where((a) => a.important).length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DColors.ground,
        surfaceTintColor: Colors.transparent,
        leading: widget.first ? null : BackButton(onPressed: _finish),
        automaticallyImplyLeading: !widget.first,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: DSpace.screen),
              children: [
                Text(tr('apps_title'), style: DText.title),
                const SizedBox(height: 6),
                Text(
                  tr('apps_selected', {'n': selected}),
                  style: DText.caption,
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) => setState(() => _q = v),
                  decoration: InputDecoration(
                    hintText: tr('search_apps'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: DColors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DRadius.button),
                      borderSide: const BorderSide(color: DColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DRadius.button),
                      borderSide: const BorderSide(color: DColors.border),
                    ),
                  ),
                ),
                const SizedBox(height: DSpace.section),
                if (shown.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(tr('no_apps'), style: DText.caption),
                    ),
                  )
                else
                  DCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < shown.length; i++) ...[
                          if (i > 0) const Divider(indent: 66),
                          MergeSemantics(
                            child: InkWell(
                              onTap: () => ref
                                  .read(repositoryProvider)
                                  .setImportant(
                                    shown[i].pkg,
                                    !shown[i].important,
                                  ),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 60,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      AppIcon(
                                        pkg: shown[i].pkg,
                                        name: shown[i].name,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          shown[i].name,
                                          style: DText.bodyStrong,
                                        ),
                                      ),
                                      Switch(
                                        value: shown[i].important,
                                        onChanged: (v) => ref
                                            .read(repositoryProvider)
                                            .setImportant(shown[i].pkg, v),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: DSpace.section),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DSpace.screen,
                8,
                DSpace.screen,
                12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr('apps_footer'), style: DText.caption),
                  const SizedBox(height: 10),
                  DButton(label: tr('done'), onPressed: _finish),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
