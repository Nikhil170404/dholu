import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../core/digest.dart';
import '../core/types.dart';
import '../data/repository.dart';
import '../native/native_bridge.dart';

enum ActionResult { openedIntent, launchedApp, failed, needsDraft }

/// One-tap actions (brief section 8, "Redirect"). Dholu never sends, pays or deletes anything:
/// it opens the source app via the original notification's contentIntent.
class Actions {
  Actions(this._ref);
  final Ref _ref;

  NativeBridge get _bridge => _ref.read(nativeBridgeProvider);

  /// Reply opens the draft screen; Pay/Track fire the source app straight away.
  Future<ActionResult> run(
    NotifAction a, {
    required String key,
    required String pkg,
    required List<int> eventIds,
  }) async {
    if (a == NotifAction.reply) {
      return ActionResult.needsDraft;
    }
    return openSource(key, pkg, eventIds: eventIds, feedback: 'opened');
  }

  Future<ActionResult> openSource(
    String key,
    String pkg, {
    required List<int> eventIds,
    String? feedback,
  }) async {
    final r = await _bridge.fire(key, pkg);
    final repo = _ref.read(repositoryProvider);
    if (r != 'failed') {
      await repo.markHandled(eventIds);
      _ref.read(changeTickProvider.notifier).bump();
    }
    if (feedback != null) {
      for (final id in eventIds) {
        final e = await repo.byId(id);
        if (e != null) {
          await repo.recordFeedback(id, e.sender, feedback);
        }
      }
    }
    return switch (r) {
      'intent' => ActionResult.openedIntent,
      'launch' => ActionResult.launchedApp,
      _ => ActionResult.failed,
    };
  }

  Future<void> feedback(StoredEvent e, String what) =>
      _ref.read(repositoryProvider).recordFeedback(e.id, e.sender, what);

  Future<void> feedbackItem(DigestItem item, String what) async {
    final repo = _ref.read(repositoryProvider);
    for (final id in item.eventIds) {
      final e = await repo.byId(id);
      if (e != null) {
        await repo.recordFeedback(id, e.sender, what);
      }
    }
  }
}

final actionsProvider = Provider<Actions>((ref) => Actions(ref));
