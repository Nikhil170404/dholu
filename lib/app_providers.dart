import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';

import 'router/router.dart';
import 'ai/llm_controller.dart';
import 'ai/recommender.dart';
import 'alerts/drum_player.dart';
import 'assistant/assistant.dart';
import 'assistant/web_search.dart';
import 'core/digest.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'l10n/strings.dart';
import 'native/important_apps_file.dart';
import 'native/native_bridge.dart';
import 'notif/ingest_service.dart';
import 'notif/notification_service.dart';
import 'settings/settings.dart';
import 'work/background.dart';
import 'work/scheduler.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<Repository>(
  (ref) => Repository(
    ref.watch(databaseProvider),
    onImportantChanged: ImportantAppsFile.writeToAppDir,
  ),
);

final trProvider = Provider<Tr>(
  (ref) => Tr(ref.watch(settingsProvider.select((s) => s.lang))),
);

final notifierProvider = Provider<AppNotifier>((_) => NotificationService());
final schedulerProvider = Provider<AppScheduler>((_) => const Scheduler());
final drumPlayerProvider = Provider<DrumPlayer>(
  (ref) => AssetDrumPlayer(ref.watch(nativeBridgeProvider)),
);

/// Bumped whenever stored events change, so screens refresh.
class Tick extends Notifier<int> {
  @override
  int build() => 0;
  void bump() => state++;
}

final changeTickProvider = NotifierProvider<Tick, int>(Tick.new);

final ingestProvider = Provider<IngestService>((ref) {
  final lang = ref.watch(settingsProvider.select((s) => s.lang));
  final useAi = ref.watch(settingsProvider.select((s) => s.useAiClassifier));
  final svc = IngestService(
    bridge: ref.watch(nativeBridgeProvider),
    repo: ref.watch(repositoryProvider),
    lang: lang,
    useAi: useAi,
    localLlm: () => ref.read(llmControllerProvider.notifier).local(),
    onChanged: () => ref.read(changeTickProvider.notifier).bump(),
  );
  ref.onDispose(svc.dispose);
  return svc;
});

final appPrefsProvider = StreamProvider<List<AppPref>>(
  (ref) => ref.watch(repositoryProvider).watchApps(),
);

final digestProvider = FutureProvider.autoDispose<Digest>((ref) async {
  ref.watch(changeTickProvider);
  ref.watch(appPrefsProvider);
  final s = ref.watch(settingsProvider);
  return buildTodayDigest(ref.watch(repositoryProvider), s);
});

/// Recent events (last 24 h) for the "See all" list.
final recentEventsProvider = FutureProvider.autoDispose<List<StoredEvent>>((
  ref,
) async {
  ref.watch(changeTickProvider);
  return ref
      .watch(repositoryProvider)
      .since(DateTime.now().subtract(const Duration(hours: 24)));
});

final accessGrantedProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(nativeBridgeProvider).isAccessGranted(),
);

final deviceSpecsProvider = FutureProvider<DeviceSpecs?>(
  (ref) => ref.watch(nativeBridgeProvider).deviceSpecs(),
);

final recommendationProvider = FutureProvider<Recommendation>((ref) async {
  final specs = await ref.watch(deviceSpecsProvider.future);
  return const ModelRecommender().recommend(specs);
});

final eventProvider = FutureProvider.autoDispose.family<StoredEvent?, int>(
  (ref, id) => ref.watch(repositoryProvider).byId(id),
);

final assistantProvider = Provider<AssistantService>(
  (ref) =>
      AssistantService(lang: ref.watch(settingsProvider.select((s) => s.lang))),
);

final webSearchProvider = FutureProvider.autoDispose<WebSearch?>((ref) async {
  final s = ref.watch(settingsProvider);
  final key = await ref.watch(secretStoreProvider).read('brave_api_key');
  return buildWebSearch(s, braveKey: key);
});

final clipboardProvider = Provider<Future<void> Function(String)>(
  (_) =>
      (t) => Clipboard.setData(ClipboardData(text: t)),
);

/// Tone-aware fallback replies for when no AI model is on.
List<String> quickReplies(Tr tr) => [
  tr('qr1'),
  tr('qr2'),
  tr('qr3'),
  tr('qr4'),
];

final routerProvider = Provider<GoRouter>((_) => buildRouter());
