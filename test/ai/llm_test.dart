import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dholu/ai/cloud_llm.dart';
import 'package:dholu/ai/llm.dart';
import 'package:dholu/ai/llm_controller.dart';
import 'package:dholu/ai/model_catalog.dart';
import 'package:dholu/ai/model_manager.dart';
import 'package:dholu/ai/prompts.dart';
import 'package:dholu/ai/refiner.dart';
import 'package:dholu/core/types.dart';
import 'package:dholu/native/native_bridge.dart';
import 'package:dholu/settings/settings.dart';

class FakeLlm extends LlmBackend {
  FakeLlm({this.local = true, this.reply = '', this.jsonReply});
  final bool local;
  final String reply;
  final Map<String, dynamic>? jsonReply;
  int jsonCalls = 0;
  bool disposed = false;
  @override
  String get label => 'fake';
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
  }) async {
    jsonCalls++;
    return jsonReply;
  }

  @override
  Future<void> dispose() async => disposed = true;
}

RawNotification raw(String title, String text) => RawNotification(
  key: 'k',
  pkg: 'com.whatsapp',
  appName: 'WA',
  title: title,
  text: text,
  postedAt: DateTime(2026, 10, 14, 9),
  isMessaging: true,
);

void main() {
  group('extractJsonObject', () {
    test('plain, fenced and chatty output', () {
      expect(extractJsonObject('{"a":1}'), {'a': 1});
      expect(
        extractJsonObject('Sure!\n```json\n{"a":"x}y","b":{"c":2}}\n```'),
        {
          'a': 'x}y',
          'b': {'c': 2},
        },
      );
      expect(extractJsonObject('no json here'), isNull);
      expect(extractJsonObject('{"a":'), isNull);
    });
  });

  group('parseClassification', () {
    test('valid output is accepted and summary capped to 8 words', () {
      final c = parseClassification({
        'priority': 'urgent',
        'category': 'work',
        'action': 'reply',
        'summary': 'a b c d e f g h i j',
      });
      expect(c!.priority, Priority.urgent);
      expect(c.summary.split(' ').length, 8);
    });
    test('rejects bad enums, missing fields and OTP/bank categories', () {
      expect(parseClassification(null), isNull);
      expect(
        parseClassification({
          'priority': 'high',
          'category': 'work',
          'action': 'reply',
          'summary': 'x',
        }),
        isNull,
      );
      expect(
        parseClassification({
          'priority': 'urgent',
          'category': 'otp',
          'action': 'none',
          'summary': 'x',
        }),
        isNull,
      );
      expect(
        parseClassification({
          'priority': 'urgent',
          'category': 'work',
          'action': 'reply',
          'summary': '  ',
        }),
        isNull,
      );
    });
  });

  group('fitTurns', () {
    test(
      'keeps system + latest turns within budget, always the last user turn',
      () {
        final turns = [
          const ChatTurn.system('sys'),
          for (var i = 0; i < 20; i++) ChatTurn.user('message number $i ' * 20),
        ];
        final out = fitTurns(turns, 500);
        expect(out.first.role, TurnRole.system);
        expect(out.last.text, turns.last.text);
        expect(out.length, lessThan(turns.length));
      },
    );
    test('a single huge turn is truncated, not dropped', () {
      final out = fitTurns([ChatTurn.user('x' * 20000)], 300);
      expect(out.single.text.length, lessThan(20000));
    });
  });

  group('Refiner', () {
    const r = Refiner();
    const uncertain = Classification(
      priority: Priority.normal,
      category: Category.message,
      action: NotifAction.reply,
      summary: 's',
      score: 1,
    );
    test('uses the model for uncertain items', () async {
      final llm = FakeLlm(
        jsonReply: {
          'priority': 'urgent',
          'category': 'work',
          'action': 'reply',
          'summary': 'Report abhi bhejo',
        },
      );
      final c = await r.refine(raw('Boss', 'check this'), uncertain, llm);
      expect(c!.priority, Priority.urgent);
      expect(llm.jsonCalls, 1);
    });
    test('skips sensitive, promo and confident items', () async {
      final llm = FakeLlm(
        jsonReply: {
          'priority': 'urgent',
          'category': 'work',
          'action': 'reply',
          'summary': 'x',
        },
      );
      for (final c in [
        const Classification(
          priority: Priority.normal,
          category: Category.otp,
          action: NotifAction.none,
          summary: 'OTP received',
        ),
        const Classification(
          priority: Priority.junk,
          category: Category.promo,
          action: NotifAction.none,
          summary: 's',
          score: -4,
        ),
        const Classification(
          priority: Priority.urgent,
          category: Category.work,
          action: NotifAction.reply,
          summary: 's',
          score: 8,
        ),
      ]) {
        expect(await r.refine(raw('a', 'b'), c, llm), isNull);
      }
      expect(llm.jsonCalls, 0);
    });
    test('never sends notification text to a non-local backend', () async {
      final cloud = FakeLlm(
        local: false,
        jsonReply: {
          'priority': 'urgent',
          'category': 'work',
          'action': 'reply',
          'summary': 'x',
        },
      );
      expect(await r.refine(raw('a', 'b'), uncertain, cloud), isNull);
      expect(cloud.jsonCalls, 0);
    });
    test('invalid model output keeps rules result', () async {
      expect(
        await r.refine(
          raw('a', 'b'),
          uncertain,
          FakeLlm(jsonReply: {'priority': 'nope'}),
        ),
        isNull,
      );
      expect(
        await r.refine(raw('a', 'b'), uncertain, FakeLlm(jsonReply: null)),
        isNull,
      );
    });
  });

  group('CloudLlm', () {
    test('requires https', () {
      expect(
        () => CloudLlm(baseUrl: 'http://x.com/v1', model: 'm', apiKey: 'k'),
        throwsArgumentError,
      );
    });
    test('streams SSE deltas and sends the bearer key', () async {
      late http.BaseRequest seen;
      final client = MockClient.streaming((req, body) async {
        seen = req;
        final sse =
            'data: {"choices":[{"delta":{"content":"Namaste"}}]}\n\ndata: {"choices":[{"delta":{"content":" Ravi"}}]}\n\ndata: [DONE]\n\n';
        return http.StreamedResponse(Stream.value(utf8.encode(sse)), 200);
      });
      final llm = CloudLlm(
        baseUrl: 'https://api.example.com/v1/',
        model: 'm',
        apiKey: 'sk-test',
        client: client,
      );
      expect(await llm.complete([const ChatTurn.user('hi')]), 'Namaste Ravi');
      expect(seen.headers['Authorization'], 'Bearer sk-test');
      expect(
        seen.url.toString(),
        'https://api.example.com/v1/chat/completions',
      );
    });
    test('401 gives a friendly error', () async {
      final client = MockClient.streaming(
        (req, body) async => http.StreamedResponse(
          Stream.value(utf8.encode('{"error":{"message":"bad key"}}')),
          401,
        ),
      );
      final llm = CloudLlm(
        baseUrl: 'https://api.example.com/v1',
        model: 'm',
        apiKey: 'x',
        client: client,
      );
      expect(
        llm.complete([const ChatTurn.user('hi')]),
        throwsA(
          isA<CloudLlmException>().having(
            (e) => e.toString(),
            'msg',
            'Invalid API key',
          ),
        ),
      );
    });
  });

  group('LlmController', () {
    late Directory dir;
    late ProviderContainer c;
    late FakeLlm loaded;
    var loads = 0;

    Future<void> setup({
      int availRam = 6000,
      bool installed = true,
      String? model = 'gemma3-1b',
    }) async {
      dir = Directory.systemTemp.createTempSync('llm');
      if (installed) {
        File(p.join(dir.path, ModelCatalog.small.fileName))
            .writeAsBytesSync([0x47, 0x47, 0x55, 0x46, 0]);
      }
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      loaded = FakeLlm();
      loads = 0;
      c = ProviderContainer(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          modelDownloaderProvider.overrideWithValue(_Dl(dir)),
          nativeBridgeProvider.overrideWithValue(
            FakeNativeBridge(
              specs: DeviceSpecs(
                totalRamMb: 8000,
                availRamMb: availRam,
                freeStorageMb: 9000,
                cores: 8,
                abis: const ['arm64-v8a'],
                sdk: 34,
                lowRam: false,
                soc: '',
                model: '',
              ),
            ),
          ),
          localLoaderProvider.overrideWithValue((path, spec, d) async {
            loads++;
            return loaded;
          }),
        ],
      );
      await c.read(modelManagerProvider.notifier).refresh();
      await c
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(modelId: model));
    }

    tearDown(() {
      c.dispose();
      dir.deleteSync(recursive: true);
    });

    test('loads once and reuses', () async {
      await setup();
      final ctl = c.read(llmControllerProvider.notifier);
      final a = await ctl.local();
      final b = await ctl.local();
      expect(a, same(b));
      expect(loads, 1);
      expect(c.read(llmControllerProvider).phase, LlmPhase.ready);
    });
    test('refuses to load when free RAM is too low', () async {
      await setup(availRam: 300);
      expect(await c.read(llmControllerProvider.notifier).local(), isNull);
      expect(c.read(llmControllerProvider).phase, LlmPhase.error);
      expect(loads, 0);
    });
    test('no model chosen or not installed -> null (rules mode)', () async {
      await setup(model: null);
      expect(await c.read(llmControllerProvider.notifier).local(), isNull);
      c.dispose();
      dir.deleteSync(recursive: true);
      await setup(installed: false);
      expect(await c.read(llmControllerProvider.notifier).local(), isNull);
    });
    test('unload disposes the model', () async {
      await setup();
      final ctl = c.read(llmControllerProvider.notifier);
      await ctl.local();
      await ctl.unload();
      expect(loaded.disposed, isTrue);
      expect(c.read(llmControllerProvider).phase, LlmPhase.none);
    });
    test(
      'forChat falls back to cloud only when enabled and key present',
      () async {
        await setup(model: null);
        final ctl = c.read(llmControllerProvider.notifier);
        expect(await ctl.forChat(), isNull);
        await c
            .read(settingsProvider.notifier)
            .update((s) => s.copyWith(cloudEnabled: true));
        expect(await ctl.forChat(), isNull); // no key yet
        await c.read(secretStoreProvider).write('cloud_api_key', 'sk-1');
        final b = await ctl.forChat();
        expect(b, isA<CloudLlm>());
        expect(b!.isLocal, isFalse);
      },
    );
  });
}

class _Dl implements ModelDownloader {
  _Dl(this.dir);
  final Directory dir;
  @override
  Stream<DlUpdate> get updates => const Stream.empty();
  @override
  Future<Directory> modelsDir() async => dir;
  @override
  Future<void> start(
    String t,
    String u,
    String f, {
    required bool wifiOnly,
  }) async {}
  @override
  Future<void> pause(String t) async {}
  @override
  Future<void> resume(String t) async {}
  @override
  Future<void> cancel(String t) async {}
  @override
  Future<int?> remoteSize(String url) async => 1;
}
