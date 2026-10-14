import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dholu/ai/model_catalog.dart';
import 'package:dholu/ai/model_manager.dart';
import 'package:dholu/settings/settings.dart';

class FakeDownloader implements ModelDownloader {
  FakeDownloader(this.dir);
  final Directory dir;
  final _c = StreamController<DlUpdate>.broadcast();
  int? size = 900 * 1024 * 1024;
  bool? lastWifi;
  List<int> content = [0x47, 0x47, 0x55, 0x46, 1, 2, 3]; // "GGUF"...
  @override
  Stream<DlUpdate> get updates => _c.stream;
  @override
  Future<Directory> modelsDir() async => dir;
  @override
  Future<void> start(
    String taskId,
    String url,
    String fileName, {
    required bool wifiOnly,
  }) async {
    lastWifi = wifiOnly;
    File(p.join(dir.path, '$fileName.part')).writeAsBytesSync(content);
  }

  void emit(DlUpdate u) => _c.add(u);
  @override
  Future<void> pause(String taskId) async {}
  @override
  Future<void> resume(String taskId) async {}
  @override
  Future<void> cancel(String taskId) async {}
  @override
  Future<int?> remoteSize(String url) async => size;
}

void main() {
  late Directory dir;
  late FakeDownloader dl;
  late ProviderContainer c;
  const spec = ModelCatalog.small;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('models');
    dl = FakeDownloader(dir);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    c = ProviderContainer(
      overrides: [
        modelDownloaderProvider.overrideWithValue(dl),
        prefsProvider.overrideWithValue(prefs),
      ],
    );
    c.read(modelManagerProvider);
  });
  tearDown(() {
    c.dispose();
    dir.deleteSync(recursive: true);
  });

  ModelInstall st() =>
      c.read(modelManagerProvider)[spec.id] ?? const ModelInstall();
  ModelManager mgr() => c.read(modelManagerProvider.notifier);

  test(
    'happy path: download -> verifying -> ready, Wi-Fi only by default',
    () async {
      dl.size = 900 * 1024 * 1024;
      await mgr().download(spec, freeStorageMb: 20000);
      expect(st().status, InstallStatus.downloading);
      expect(dl.lastWifi, isTrue);
      dl.emit(DlUpdate(spec.id, DlState.running, progress: 0.5));
      await Future<void>.delayed(Duration.zero);
      expect(st().progress, 0.5);
      // Remote said 900 MB but our fake wrote 7 bytes -> must be rejected as damaged.
      dl.emit(DlUpdate(spec.id, DlState.complete));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(st().status, InstallStatus.failed);
      expect(File(p.join(dir.path, spec.fileName)).existsSync(), isFalse);
    },
  );

  test('ready when file is a valid GGUF of expected size', () async {
    dl.size = 60 * 1024 * 1024; // pretend remote size
    dl.content = [
      0x47,
      0x47,
      0x55,
      0x46,
      ...List.filled(60 * 1024 * 1024 - 4, 0),
    ];
    await mgr().download(spec, freeStorageMb: 20000);
    dl.emit(DlUpdate(spec.id, DlState.complete));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(st().status, InstallStatus.ready);
    expect(await mgr().installedPath(spec), isNotNull);
  });

  test('rejects non-GGUF files', () async {
    dl.size = 60 * 1024 * 1024;
    dl.content = List.filled(60 * 1024 * 1024, 7);
    await mgr().download(spec, freeStorageMb: 20000);
    dl.emit(DlUpdate(spec.id, DlState.complete));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(st().status, InstallStatus.failed);
  });

  test('refuses when storage is too low', () async {
    await mgr().download(spec, freeStorageMb: 500);
    expect(st().status, InstallStatus.failed);
    expect(st().error, contains('storage'));
  });

  test('unreachable server and tiny/moved file give clear errors', () async {
    dl.size = null;
    await mgr().download(spec, freeStorageMb: 20000);
    expect(st().error, contains('reach'));
    dl.size = 1000;
    await mgr().download(spec, freeStorageMb: 20000);
    expect(st().error, contains('too small'));
  });

  test('refresh detects an existing model; delete removes it', () async {
    File(p.join(dir.path, spec.fileName))
        .writeAsBytesSync([0x47, 0x47, 0x55, 0x46, 0]);
    await mgr().refresh();
    expect(st().status, InstallStatus.ready);
    await mgr().delete(spec);
    expect(st().status, InstallStatus.none);
    expect(File(p.join(dir.path, spec.fileName)).existsSync(), isFalse);
  });

  test('failure update surfaces message; Wi-Fi setting is honoured', () async {
    await c
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(wifiOnlyDownloads: false));
    await mgr().download(spec, freeStorageMb: 20000);
    expect(dl.lastWifi, isFalse);
    dl.emit(DlUpdate(spec.id, DlState.failed, error: 'network'));
    await Future<void>.delayed(Duration.zero);
    expect(st().status, InstallStatus.failed);
    expect(st().error, 'network');
  });
}
