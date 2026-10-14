import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/ai/llm.dart';
import 'package:dholu/core/digest.dart';
import 'package:dholu/core/types.dart';
import 'package:dholu/data/database.dart';
import 'package:dholu/data/repository.dart';
import 'package:dholu/l10n/strings.dart';
import 'package:dholu/native/native_bridge.dart';
import 'package:dholu/notif/ingest_service.dart';
import 'package:dholu/notif/notification_service.dart';
import 'package:dholu/settings/settings.dart';
import 'package:dholu/work/background.dart';
import 'package:dholu/work/scheduler.dart';

DigestItem item(String t, {bool urgent = false}) => DigestItem(
  title: t,
  appName: 'WhatsApp',
  pkg: 'p',
  action: NotifAction.reply,
  urgent: urgent,
  eventIds: const [1],
  latestKey: 'k',
  category: Category.message,
);

RawNotification raw(
  String key,
  String title,
  String text, {
  String pkg = 'com.whatsapp',
  int sec = 0,
  String? hint,
}) => RawNotification(
  key: key,
  pkg: pkg,
  appName: 'WhatsApp',
  title: title,
  text: text,
  postedAt: DateTime(2026, 10, 14, 9, 0, sec),
  isMessaging: true,
  sensitiveHint: hint,
);

class FakeLlm extends LlmBackend {
  FakeLlm(this.j);
  final Map<String, dynamic>? j;
  int calls = 0;
  @override
  String get label => 'f';
  @override
  bool get isLocal => true;
  @override
  Stream<String> chat(
    List<ChatTurn> turns, {
    int maxTokens = 512,
    double temperature = 0.7,
  }) => const Stream.empty();
  @override
  Future<Map<String, dynamic>?> json(
    List<ChatTurn> turns,
    Map<String, dynamic> schema, {
    int maxTokens = 160,
  }) async {
    calls++;
    return j;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  group('digest content / lock-screen privacy', () {
    const tr = Tr(Lang.hinglish);
    final d = Digest(
      items: [
        item('Anil Sir: report 10 baje tak', urgent: true),
        item('Mummy ke 5 messages'),
      ],
      hiddenCount: 47,
    );
    test('detail OFF (default): counts only, no message text anywhere', () {
      final c = buildDigestContent(d, tr, detail: false);
      expect(c.title, '2 zaroori updates');
      expect(c.lines, isEmpty);
      final all = '${c.title} ${c.body}';
      expect(all.contains('Anil'), isFalse);
      expect(all.contains('Mummy'), isFalse);
      expect(c.body, contains('+47 chhupe hue'));
    });
    test('detail ON: lines with urgent marker', () {
      final c = buildDigestContent(d, tr, detail: true);
      expect(c.lines, [
        '• Anil Sir: report 10 baje tak',
        'Mummy ke 5 messages',
      ]);
    });
    test('singular, empty, English', () {
      expect(
        buildDigestContent(
          Digest(items: [item('x')], hiddenCount: 0),
          tr,
          detail: false,
        ).title,
        '1 zaroori update',
      );
      expect(
        buildDigestContent(
          const Digest(items: [], hiddenCount: 3),
          const Tr(Lang.english),
          detail: true,
        ).title,
        'No important updates today',
      );
    });
    test('urgent notification hides content unless detail is on', () {
      final e = StoredEvent(
        id: 5,
        key: 'k',
        pkg: 'p',
        appName: 'WhatsApp',
        sender: 'Anil Sir',
        text: 'report',
        postedAt: DateTime(2026),
        classification: const Classification(
          priority: Priority.urgent,
          category: Category.work,
          action: NotifAction.reply,
          summary: 'Report 10 baje tak',
        ),
      );
      final hidden = buildUrgentContent(e, tr, detail: false);
      expect('${hidden.title} ${hidden.body}'.contains('Anil'), isFalse);
      expect(
        buildUrgentContent(e, tr, detail: true).body,
        'Report 10 baje tak',
      );
    });
    test('payload round trip', () {
      expect(
        NotifPayload.parse(const NotifPayload('alert', 12).encode())!.eventId,
        12,
      );
      expect(NotifPayload.parse('summary')!.kind, 'summary');
      expect(NotifPayload.parse(null), isNull);
    });
  });

  group('scheduler delay', () {
    test('later today vs tomorrow', () {
      final now = DateTime(2026, 10, 14, 7, 30);
      expect(delayUntilNext(now, 8, 0), const Duration(minutes: 30));
      expect(delayUntilNext(now, 7, 0), const Duration(hours: 23, minutes: 30));
      expect(
        delayUntilNext(now, 7, 30),
        const Duration(hours: 24),
      ); // exactly now -> tomorrow
    });
  });

  group('IngestService', () {
    late AppDatabase db;
    late Repository repo;
    late FakeNativeBridge bridge;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = Repository(db);
      bridge = FakeNativeBridge();
      await repo.syncApps(const [
        AppRef('com.whatsapp', 'WhatsApp'),
        AppRef('com.myntra', 'Myntra'),
      ]);
      await repo.setImportant('com.whatsapp', true);
    });
    tearDown(() => db.close());

    IngestService svc({LlmBackend? llm, bool ai = false}) => IngestService(
      bridge: bridge,
      repo: repo,
      lang: Lang.hinglish,
      localLlm: llm == null ? null : () async => llm,
      useAi: ai,
      clock: () => DateTime(2026, 10, 14, 10),
    );

    test(
      'live urgent message from important app emits an urgent event',
      () async {
        final s = svc();
        final urgent = s.urgent.first;
        await s.handle(
          raw('k1', 'Anil Sir', 'report 10 baje tak bhejna urgent'),
        );
        expect((await urgent).sender, 'Anil Sir');
        await s.dispose();
      },
    );

    test('urgent from a NON-important app does not alert', () async {
      final s = svc();
      var fired = false;
      s.urgent.listen((_) => fired = true);
      await s.handle(
        raw('k2', 'Myntra', 'urgent: your order', pkg: 'com.myntra'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(fired, isFalse);
      expect(
        (await repo.since(DateTime(2020))).single.text,
        '',
      ); // text not stored for muted apps
      await s.dispose();
    });

    test('OTP is stored only as a placeholder, never alerted', () async {
      final s = svc();
      var fired = false;
      s.urgent.listen((_) => fired = true);
      await s.handle(raw('k3', 'HDFC', 'Your OTP is 482913. Do not share.'));
      await Future<void>.delayed(Duration.zero);
      final e = (await repo.since(DateTime(2020))).single;
      expect(e.text.contains('482913'), isFalse);
      expect(e.classification.category, Category.otp);
      expect(fired, isFalse);
      await s.dispose();
    });

    test('queued (offline) items: sensitive hint honoured, no urgent alerts, duplicates ignored', () async {
      bridge.queue.addAll([
        raw('q1', 'Anil Sir', 'report urgent asap'),
        raw('q2', '', '', hint: 'otp'),
        raw('q1', 'Anil Sir', 'report urgent asap'), // duplicate delivery
      ]);
      final s = svc();
      var fired = false;
      s.urgent.listen((_) => fired = true);
      expect(await s.drainQueue(), 3);
      await Future<void>.delayed(Duration.zero);
      final all = await repo.since(DateTime(2020));
      expect(all.length, 2);
      expect(all.any((e) => e.classification.category == Category.otp), isTrue);
      expect(fired, isFalse);
      await s.dispose();
    });

    test(
      'AI refinement updates an uncertain item and can raise it to urgent',
      () async {
        final llm = FakeLlm({
          'priority': 'urgent',
          'category': 'work',
          'action': 'reply',
          'summary': 'Boss ko jawab do',
        });
        final s = svc(llm: llm, ai: true);
        final urgent = s.urgent.first;
        await s.handle(raw('k4', 'Boss', 'ek baar dekh lena please'));
        await s.idle();
        expect(llm.calls, 1);
        final e = (await repo.since(DateTime(2020))).single;
        expect(e.classification.priority, Priority.urgent);
        expect(e.classification.summary, 'Boss ko jawab do');
        expect((await urgent).sender, 'Boss');
        await s.dispose();
      },
    );

    test('AI off -> model never called', () async {
      final llm = FakeLlm({
        'priority': 'urgent',
        'category': 'work',
        'action': 'reply',
        'summary': 'x',
      });
      final s = svc(llm: llm, ai: false);
      await s.handle(raw('k5', 'Boss', 'ek baar dekh lena please'));
      await s.idle();
      expect(llm.calls, 0);
      await s.dispose();
    });

    test('morning digest builder uses last 24h of important apps', () async {
      final s = svc();
      await s.handle(raw('a', 'Mummy', 'khana khaya? urgent', sec: 1));
      await s.handle(
        raw('b', 'Myntra', 'sale 50% off', pkg: 'com.myntra', sec: 2),
      );
      final d = await buildTodayDigest(
        repo,
        const Settings(),
        now: DateTime(2026, 10, 14, 11),
      );
      expect(d.items.length, 1);
      expect(d.hiddenCount, 1);
      await s.dispose();
    });
  });
}
