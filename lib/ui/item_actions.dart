import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../actions/actions.dart';
import '../app_providers.dart';
import '../core/digest.dart';
import '../core/types.dart';
import '../l10n/strings.dart';

String actionLabel(Tr tr, NotifAction a) => switch (a) {
  NotifAction.reply => tr('a_reply'),
  NotifAction.pay => tr('a_pay'),
  NotifAction.track => tr('a_track'),
  NotifAction.none => tr('a_open'),
};

IconData actionIcon(NotifAction a) => switch (a) {
  NotifAction.reply => Icons.chat_bubble_outline_rounded,
  NotifAction.pay => Icons.receipt_long_outlined,
  NotifAction.track => Icons.local_shipping_outlined,
  NotifAction.none => Icons.notifications_none_rounded,
};

/// Tap on a digest row button. Reply -> draft screen; Pay/Track/Open -> source app via contentIntent.
Future<void> runItemAction(
  BuildContext context,
  WidgetRef ref,
  DigestItem item,
) async {
  final tr = ref.read(trProvider);
  final messenger = ScaffoldMessenger.of(context);
  if (item.action == NotifAction.reply) {
    context.push('/draft/${item.eventIds.first}');
    return;
  }
  final r = await ref
      .read(actionsProvider)
      .openSource(
        item.latestKey,
        item.pkg,
        eventIds: item.eventIds,
        feedback: 'opened',
      );
  if (r == ActionResult.failed) {
    messenger.showSnackBar(SnackBar(content: Text(tr('error_generic'))));
  }
}
