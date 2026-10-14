import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_providers.dart';
import '../core/digest.dart';
import '../l10n/strings.dart';
import '../mascot/corner_peek.dart';
import '../mascot/dholu_widget.dart';
import '../native/native_bridge.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';
import 'item_actions.dart';
import 'main_nav.dart';
import 'widgets.dart';

/// Screen 6: Home.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.animate = true});
  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final digest = ref.watch(digestProvider);
    final access = ref.watch(accessGrantedProvider).asData?.value ?? true;

    return Scaffold(
      bottomNavigationBar: const MainNav(index: 0),
      body: SafeArea(
        child: digest.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: DColors.accent),
          ),
          error: (e, _) =>
              Center(child: Text(tr('error_generic'), style: DText.caption)),
          data: (d) {
            final urgent = d.urgent.isEmpty ? null : d.urgent.first;
            final rest = [
              for (final i in d.items)
                if (i != urgent) i,
            ];
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    DSpace.screen,
                    16,
                    DSpace.screen,
                    120,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(tr('home_title'), style: DText.title),
                        ),
                        IconButton(
                          tooltip: tr('choose_apps'),
                          constraints: const BoxConstraints(
                            minWidth: DSpace.minTouch,
                            minHeight: DSpace.minTouch,
                          ),
                          onPressed: () => context.push('/apps'),
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: DColors.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('home_count', {
                        'n': d.importantCount,
                        'm': d.hiddenCount,
                      }),
                      style: DText.caption,
                    ),
                    const SizedBox(height: DSpace.section),
                    if (!access)
                      _AccessBanner(
                        tr: tr,
                        onTap: () =>
                            ref.read(nativeBridgeProvider).openAccessSettings(),
                      ),
                    if (d.items.isEmpty)
                      _Empty(tr: tr, animate: animate)
                    else ...[
                      if (urgent != null) ...[
                        _UrgentCard(
                          item: urgent,
                          tr: tr,
                          onAction: () => runItemAction(context, ref, urgent),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (rest.isNotEmpty)
                        DCard(
                          child: Column(
                            children: [
                              for (var i = 0; i < rest.length; i++) ...[
                                if (i > 0) const Divider(indent: 66),
                                _Row(
                                  item: rest[i],
                                  tr: tr,
                                  onAction: () =>
                                      runItemAction(context, ref, rest[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: DSpace.section),
                    if (d.hiddenCount > 0)
                      InkWell(
                        onTap: () => context.push('/all'),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Center(
                            child: Column(
                              children: [
                                Text(
                                  tr('hidden_title', {'n': d.hiddenCount}),
                                  style: DText.bodyStrong,
                                ),
                                const SizedBox(height: 2),
                                Text(tr('hidden_sub'), style: DText.caption),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (urgent != null)
                  Positioned(
                    right: 0,
                    bottom: 24,
                    child: CornerPeek(
                      animate: animate,
                      onTap: () =>
                          context.push('/alert/${urgent.eventIds.first}'),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AccessBanner extends StatelessWidget {
  const _AccessBanner({required this.tr, required this.onTap});
  final Tr tr;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: DColors.accentTint,
      borderRadius: BorderRadius.circular(DRadius.card),
    ),
    child: Row(
      children: [
        const Icon(Icons.notifications_off_outlined, color: DColors.accentDark),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tr('access_banner'),
            style: DText.caption.copyWith(color: DColors.accentDark),
          ),
        ),
        const SizedBox(width: 8),
        DButton(label: tr('turn_on'), expand: false, onPressed: onTap),
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.tr, required this.animate});
  final Tr tr;
  final bool animate;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        Dholu(pose: DholuPose.muted, size: 120, animate: animate),
        const SizedBox(height: 16),
        Text(tr('empty_title'), style: DText.heading),
        const SizedBox(height: 6),
        Text(
          tr('empty_sub'),
          style: DText.caption,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.tr, required this.onAction});
  final DigestItem item;
  final Tr tr;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        AppIcon(pkg: item.pkg, name: item.appName),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: DText.bodyStrong,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(tr('opens_in', {'app': item.appName}), style: DText.caption),
            ],
          ),
        ),
        const SizedBox(width: 8),
        DButton(
          label: actionLabel(tr, item.action),
          tint: true,
          expand: false,
          onPressed: onAction,
        ),
      ],
    ),
  );
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({
    required this.item,
    required this.tr,
    required this.onAction,
  });
  final DigestItem item;
  final Tr tr;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: DColors.ink,
      borderRadius: BorderRadius.circular(DRadius.feature),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const UrgentDot(),
            const SizedBox(width: 8),
            Text(
              '${tr('urgent_tag')}  ·  ${item.appName}',
              style: DText.caption.copyWith(
                color: Colors.white70,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          item.title,
          style: DText.heading.copyWith(color: Colors.white, fontSize: 20),
        ),
        const SizedBox(height: 16),
        DButton(
          label: actionLabel(tr, item.action),
          dark: true,
          onPressed: onAction,
        ),
      ],
    ),
  );
}
