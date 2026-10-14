import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_providers.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';
import 'item_actions.dart';
import 'widgets.dart';

/// Screen 4: Summary opened. White bottom sheet over a scrim (opened from the summary notification).
class SummarySheet extends ConsumerWidget {
  const SummarySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final digest = ref.watch(digestProvider).asData?.value;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: DColors.card,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DRadius.sheet),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DSpace.screen,
                    16,
                    DSpace.screen,
                    8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(tr('home_title'), style: DText.heading),
                  ),
                ),
                Flexible(
                  child: digest == null
                      ? const Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: DColors.accent,
                          ),
                        )
                      : ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DSpace.screen,
                          ),
                          children: [
                            if (digest.items.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    tr('empty_title'),
                                    style: DText.caption,
                                  ),
                                ),
                              ),
                            for (final item in digest.items) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    AppIcon(pkg: item.pkg, name: item.appName),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              if (item.urgent) ...[
                                                const UrgentDot(),
                                                const SizedBox(width: 6),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: DText.bodyStrong,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tr('opens_in', {
                                              'app': item.appName,
                                            }),
                                            style: DText.caption,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    DButton(
                                      label: actionLabel(tr, item.action),
                                      tint: true,
                                      expand: false,
                                      onPressed: () {
                                        context.pop();
                                        runItemAction(context, ref, item);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(),
                            ],
                          ],
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DSpace.screen,
                    8,
                    DSpace.screen,
                    12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DButton(
                          label:
                              '${tr('see_all')} (${digest?.hiddenCount ?? 0})',
                          tint: true,
                          onPressed: () {
                            context.pop();
                            context.push('/all');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      DButton(
                        label: tr('choose_apps'),
                        expand: false,
                        tint: true,
                        onPressed: () {
                          context.pop();
                          context.push('/apps');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
