import 'dart:async';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dholu/ai/llm_controller.dart';
import 'package:dholu/ai/model_catalog.dart';
import 'package:dholu/ai/model_manager.dart';
import 'package:dholu/core/types.dart';
import 'package:dholu/data/database.dart';
import 'package:dholu/data/repository.dart';
import 'package:dholu/native/native_bridge.dart';
import 'package:dholu/notif/ingest_service.dart';
import 'package:dholu/settings/settings.dart';
import 'helpers.dart' show FakeLlm, NullDownloader;

class _Dl extends NullDownloader {
  _Dl(this.dir);
  final Directory dir;
  @override
  Future<Directory> modelsDir() async => dir;
}

void main() {
  group('urgent alert cooldown', () {
    test('same sender re-posting does not re-alert; a different sender or later time does', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = Repository(db);
      await repo.syncApps(const [AppRef('com.whatsapp', 'WhatsApp')]);
      await repo.setImportant('com.whatsapp', true);
      var now = DateTime(2026, 10, 14, 9);
      final svc = IngestService(bridge: FakeNativeBridge(), repo: repo, lang: Lang.hinglish, clock: () => now);
      final alerts = <String>[];
      svc.urgent.listen((e) => alerts.add(e.sender));

      RawNotification n(String key, String title, int sec) => RawNotification(
          key: key, pkg: 'com.whatsapp', appName: 'WhatsApp', title: title, text: 'urgent asap deadline', postedAt: DateTime(2026, 10, 14, 9, 0, sec), isMessaging: true);

      await svc.handle(n('a1', 'Anil Sir', 1));
      await svc.handle(n('a2', 'Anil Sir', 2)); // chat app re-post
      await svc.handle(n('b1', 'Boss', 3));
      await Future<void>.delayed(Duration.zero);
      expect(alerts, ['Anil Sir', 'Boss']);
      expect((await repo.since(DateTime(2020))).length, 3); // all three still stored

      now = now.add(const Duration(minutes: 3));
      await svc.handle(n('a3', 'Anil Sir', 4));
      await Future<void>.delayed(Duration.zero);
      expect(alerts, ['Anil Sir', 'Boss', 'Anil Sir']);
      await svc.dispose();
    });
  });

  group('model lifecycle', () {
    late Directory dir;
    late ProviderContainer c;
    var loads = 0;
    setUp(() async {
      dir = Directory.systemTemp.createTempSync('rb');
      File(p.join(dir.path, ModelCatalog.small.fileName)).writeAsBytesSync([0x47, 0x47, 0x55, 0x46, 0]);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      loads = 0;
      c = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(prefs),
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
        modelDownloaderProvider.overrideWithValue(_Dl(dir)),
        nativeBridgeProvider.overrideWithValue(FakeNativeBridge()),
        localLoaderProvider.overrideWithValue((path, spec, d) async {
          loads++;
          return FakeLlm();
        }),
      ]);
      await c.read(modelManagerProvider.notifier).refresh();
      await c.read(settingsProvider.notifier).update((s) => s.copyWith(modelId: 'gemma3-1b'));
    });
    tearDown(() {
      c.dispose();
      dir.deleteSync(recursive: true);
    });

    test('loadedOrNull never triggers a load (background safety)', () async {
      final ctl = c.read(llmControllerProvider.notifier);
      expect(ctl.loadedOrNull, isNull);
      expect(loads, 0);
      await ctl.local();
      expect(ctl.loadedOrNull, isNotNull);
      expect(loads, 1);
    });
  });

  group('download adopted after an app restart', () {
    test('a running task with no in-memory state shows progress, then verifies and becomes ready', () async {
      final dir = Directory.systemTemp.createTempSync('rs');
      addTearDown(() => dir.deleteSync(recursive: true));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dl = _FakeUpdates(dir);
      final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs), modelDownloaderProvider.overrideWithValue(dl)]);
      addTearDown(c.dispose);
      c.read(modelManagerProvider); // fresh process: empty state
      const spec = ModelCatalog.small;
      dl.emit(DlUpdate(spec.id, DlState.running, progress: 0.4));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(modelManagerProvider)[spec.id]!.status, InstallStatus.downloading);
      expect(c.read(modelManagerProvider)[spec.id]!.progress, 0.4);

      File(p.join(dir.path, '${spec.fileName}.part')).writeAsBytesSync([0x47, 0x47, 0x55, 0x46, 1, 2]);
      dl.emit(DlUpdate(spec.id, DlState.complete));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(c.read(modelManagerProvider)[spec.id]!.status, InstallStatus.ready);
      expect(File(p.join(dir.path, spec.fileName)).existsSync(), isTrue);
    });

    test('unknown task ids are ignored', () async {
      final dir = Directory.systemTemp.createTempSync('ru');
      addTearDown(() => dir.deleteSync(recursive: true));
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final dl = _FakeUpdates(dir);
      final c = ProviderContainer(overrides: [prefsProvider.overrideWithValue(prefs), modelDownloaderProvider.overrideWithValue(dl)]);
      addTearDown(c.dispose);
      c.read(modelManagerProvider);
      dl.emit(const DlUpdate('something-else', DlState.complete));
      await Future<void>.delayed(Duration.zero);
      expect(c.read(modelManagerProvider), isEmpty);
    });
  });
}

class _FakeUpdates extends _Dl {
  _FakeUpdates(super.dir);
  final _c = StreamController<DlUpdate>.broadcast();
  @override
  Stream<DlUpdate> get updates => _c.stream;
  void emit(DlUpdate u) => _c.add(u);
}
