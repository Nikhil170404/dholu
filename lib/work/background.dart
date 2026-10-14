import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../core/digest.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../l10n/strings.dart';
import '../native/native_bridge.dart';
import '../notif/ingest_service.dart';
import '../notif/notification_service.dart';
import '../settings/settings.dart';
import 'scheduler.dart';

/// Builds today's digest from the last 24 h of stored events.
Future<Digest> buildTodayDigest(
  Repository repo,
  Settings s, {
  DateTime? now,
}) async {
  final t = now ?? DateTime.now();
  final events = await repo.since(t.subtract(const Duration(hours: 24)));
  final important = await repo.importantPkgs();
  return DigestBuilder(lang: s.lang).build(events, important);
}

/// Entry point WorkManager calls in a background isolate (app may be closed).
/// Rules only: the model is never loaded here, to protect RAM and battery.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, input) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    final prefs = await SharedPreferences.getInstance();
    final settings = Settings.load(prefs);
    final tr = Tr(settings.lang);
    final db = AppDatabase();
    final repo = Repository(db);
    final notifs = NotificationService();
    try {
      await notifs.init(tr);
      switch (task) {
        case taskMorning:
          if (!settings.summaryEnabled) {
            return true;
          }
          final ingest = IngestService(
            bridge: AndroidNativeBridge(),
            repo: repo,
            lang: settings.lang,
          );
          await ingest.drainQueue();
          await repo.purge();
          final digest = await buildTodayDigest(repo, settings);
          await notifs.showDigest(
            digest,
            tr,
            detail: settings.lockScreenDetail,
          );
          // Re-arm for tomorrow.
          await const Scheduler().scheduleMorning(
            settings.summaryHour,
            settings.summaryMinute,
          );
          return true;
        case taskReminder:
          final id = (input?['eventId'] as num?)?.toInt();
          final e = id == null ? null : await repo.byId(id);
          if (e != null) {
            await notifs.showReminder(e, tr);
          }
          return true;
      }
      return true;
    } finally {
      await db.close();
    }
  });
}
