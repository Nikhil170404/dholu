import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dholu/ai/llm.dart';
import 'package:dholu/ai/llm_controller.dart';
import 'package:dholu/ai/model_manager.dart';
import 'package:dholu/alerts/drum_player.dart';
import 'package:dholu/app_providers.dart';
import 'package:dholu/core/digest.dart';
import 'package:dholu/core/types.dart';
import 'package:dholu/data/database.dart';
import 'package:dholu/data/repository.dart';
import 'package:dholu/l10n/strings.dart';
import 'package:dholu/native/native_bridge.dart';
import 'package:dholu/notif/notification_service.dart';
import 'package:dholu/router/router.dart';
import 'package:dholu/settings/settings.dart';
import 'package:dholu/shell.dart';
import 'package:dholu/theme/theme.dart';
import 'package:dholu/work/scheduler.dart';

class RecordingNotifier implements AppNotifier {
  final urgent = <StoredEvent>[];
  final digests = <Digest>[];
  final reminders = <StoredEvent>[];
  bool permissionAsked = false;
  @override
  Future<void> init(Tr tr, {NotifTapHandler? onTap}) async {}
  @override
  Future<bool> requestPermission() async => permissionAsked = true;
  @override
  Future<String?> launchPayload() async => null;
  @override
  Future<void> showDigest(Digest d, Tr tr, {required bool detail}) async =>
      digests.add(d);
  @override
  Future<void> showUrgent(
    StoredEvent e,
    Tr tr, {
    required bool detail,
    required bool sound,
  }) async => urgent.add(e);
  @override
  Future<void> showReminder(StoredEvent e, Tr tr) async => reminders.add(e);
  @override
  Future<void> cancelFor(int eventId) async {}
}

class FakeScheduler implements AppScheduler {
  final reminded = <int>[];
  int morningScheduled = 0;
  int morningCancelled = 0;
  @override
  Future<void> scheduleMorning(int hour, int minute, {DateTime? now}) async =>
      morningScheduled++;
  @override
  Future<void> cancelMorning() async => morningCancelled++;
  @override
  Future<void> remindIn(int eventId, {int minutes = 10}) async =>
      reminded.add(eventId);
}

class FakeLlm extends LlmBackend {
  FakeLlm({this.reply = 'Theek hai, dekhta hoon', this.local = true});
  final String reply;
  final bool local;
  @override
  String get label => 'Fake';
  @override
  bool get isLocal => local;
  @override
  Stream<String> chat(
    List<ChatTurn> turns, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) => Stream.fromIterable(reply.split(' ').map((w) => '$w '));
  @override
  Future<Map<String, dynamic>?> json(
    List<ChatTurn> turns,
    Map<String, dynamic> schema, {
    int maxTokens = 160,
  }) async => {
    'subject': 'Report update',
    'body': 'Hi Sir,\nReport kal tak bhej dunga.\nRegards',
  };
  @override
  Future<void> dispose() async {}
}

class FakeLlmController extends LlmController {
  FakeLlmController(this.backend);
  final LlmBackend? backend;
  @override
  Future<LlmBackend?> forChat() async => backend;
  @override
  Future<LlmBackend?> local() async => backend;
}

class NullDownloader implements ModelDownloader {
  final started = <String>[];
  bool? wifi;
  @override
  Stream<DlUpdate> get updates => const Stream.empty();
  @override
  Future<Directory> modelsDir() async => Directory.systemTemp.createTemp('m');
  @override
  Future<void> start(
    String taskId,
    String url,
    String fileName, {
    required bool wifiOnly,
  }) async {
    started.add(taskId);
    wifi = wifiOnly;
  }

  @override
  Future<void> pause(String taskId) async {}
  @override
  Future<void> resume(String taskId) async {}
  @override
  Future<void> cancel(String taskId) async {}
  @override
  Future<int?> remoteSize(String url) async => 800 * 1024 * 1024;
}

class Env {
  static final bool _quiet = (() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    return true;
  })();

  Env({
    this.llm,
    DeviceSpecs? specs,
    Map<String, Object> prefs = const {},
    this.apps = const [],
  }) {
    assert(_quiet);
    SharedPreferences.setMockInitialValues({'onboarded': true, ...prefs});
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repo = Repository(db);
    bridge = FakeNativeBridge(
      specs:
          specs ??
          const DeviceSpecs(
            totalRamMb: 8192,
            availRamMb: 4000,
            freeStorageMb: 30000,
            cores: 8,
            abis: ['arm64-v8a'],
            sdk: 34,
            lowRam: false,
            soc: 'Test SoC',
            model: 'Test Phone',
          ),
      apps: apps,
    );
  }
  final LlmBackend? llm;
  final List<AppRef> apps;
  late final AppDatabase db;
  late final Repository repo;
  late final FakeNativeBridge bridge;
  final notifier = RecordingNotifier();
  final scheduler = FakeScheduler();
  final player = NoopDrumPlayer();
  final downloader = NullDownloader();
  final secrets = MemorySecretStore();
  late SharedPreferences prefs;

  Future<void> init() async => prefs = await SharedPreferences.getInstance();

  List<Override> get overrides => [
    prefsProvider.overrideWithValue(prefs),
    databaseProvider.overrideWithValue(db),
    nativeBridgeProvider.overrideWithValue(bridge),
    notifierProvider.overrideWithValue(notifier),
    schedulerProvider.overrideWithValue(scheduler),
    drumPlayerProvider.overrideWithValue(player),
    secretStoreProvider.overrideWithValue(secrets),
    modelDownloaderProvider.overrideWithValue(downloader),
    llmControllerProvider.overrideWith(() => FakeLlmController(llm)),
    clipboardProvider.overrideWithValue((t) async => copied.add(t)),
  ];
  final copied = <String>[];

  /// Full app (router + shell) starting at [location].
  late GoRouter router;
  String get path =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  Widget app({String location = '/home'}) {
    router = buildRouter(initialLocation: location);
    return ProviderScope(
      overrides: [...overrides, routerProvider.overrideWithValue(router)],
      child: Consumer(
        builder: (context, ref, _) => MaterialApp.router(
          theme: buildTheme(),
          routerConfig: router,
          builder: (c, child) => AppShell(child: child!),
        ),
      ),
    );
  }

  RawNotification raw(
    String key,
    String title,
    String text, {
    String pkg = 'com.whatsapp',
    String app = 'WhatsApp',
    int min = 0,
  }) => RawNotification(
    key: key,
    pkg: pkg,
    appName: app,
    title: title,
    text: text,
    postedAt: DateTime.now().subtract(Duration(minutes: min)),
    isMessaging: true,
  );

  /// Marks WhatsApp important and stores two urgent/important messages and one muted promo.
  Future<void> seed() async {
    await repo.syncApps(const [
      AppRef('com.whatsapp', 'WhatsApp'),
      AppRef('com.myntra', 'Myntra'),
      AppRef('net.one97.paytm', 'Paytm'),
    ]);
    await repo.setImportant('com.whatsapp', true);
    await repo.setImportant('net.one97.paytm', true);
    final important = await repo.importantPkgs();
    Future<void> add(RawNotification n, Classification c) =>
        repo.ingest(n, c, importantApps: important);
    await add(
      raw('a', 'Anil Sir', 'report 10 baje tak bhejna urgent', min: 3),
      const Classification(
        priority: Priority.urgent,
        category: Category.work,
        action: NotifAction.reply,
        summary: 'Report 10 baje tak',
      ),
    );
    await add(
      raw(
        'b',
        'Paytm',
        'Bijli bill Rs 1840 due kal',
        pkg: 'net.one97.paytm',
        app: 'Paytm',
        min: 5,
      ),
      const Classification(
        priority: Priority.important,
        category: Category.bill,
        action: NotifAction.pay,
        summary: 'Bijli bill kal due',
      ),
    );
    await add(
      raw(
        'c',
        'Myntra',
        'sale 50% off',
        pkg: 'com.myntra',
        app: 'Myntra',
        min: 6,
      ),
      const Classification(
        priority: Priority.junk,
        category: Category.promo,
        action: NotifAction.none,
        summary: 'Sale offer',
      ),
    );
  }

  Future<void> dispose() => db.close();
}
