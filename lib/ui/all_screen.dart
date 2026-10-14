import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../core/types.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'app_icon.dart';
import 'widgets.dart';

/// "Sab dekho": everything from the last 24 hours, including hidden items (summaries only).
class AllScreen extends ConsumerWidget {
  const AllScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final events = ref.watch(recentEventsProvider).asData?.value ?? const [];
    final important =
        ref
            .watch(appPrefsProvider)
            .asData
            ?.value
            .where((a) => a.important)
            .map((a) => a.pkg)
            .toSet() ??
        <String>{};
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('see_all')),
        backgroundColor: DColors.ground,
        surfaceTintColor: Colors.transparent,
      ),
      body: events.isEmpty
          ? Center(child: Text(tr('no_data'), style: DText.caption))
          : ListView(
              padding: const EdgeInsets.all(DSpace.screen),
              children: [
                DCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < events.length; i++) ...[
                        if (i > 0) const Divider(indent: 66),
                        ListTile(
                          minTileHeight: 60,
                          leading: AppIcon(
                            pkg: events[i].pkg,
                            name: events[i].appName,
                          ),
                          title: Text(
                            events[i].classification.category == Category.otp ||
                                    events[i].classification.category ==
                                        Category.bank
                                ? events[i].classification.summary
                                : '${events[i].sender}: ${events[i].classification.summary}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: DText.bodyStrong,
                          ),
                          subtitle: Text(
                            '${events[i].appName}${important.contains(events[i].pkg) ? '' : ' · ${tr('muted_label')}'}',
                            style: DText.caption,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
