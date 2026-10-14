import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/core/types.dart';
import 'package:dholu/data/database.dart';
import 'package:dholu/data/repository.dart';

RawNotification raw(
  String key,
  String text, {
  String pkg = 'com.whatsapp',
  DateTime? at,
  String title = 'Mummy',
}) => RawNotification(
  key: key,
  pkg: pkg,
  appName: 'WhatsApp',
  title: title,
  text: text,
  postedAt: at ?? DateTime(2026, 10, 14, 9),
);

const cls = Classification(
  priority: Priority.important,
  category: Category.message,
  action: NotifAction.reply,
  summary: 'x',
);

void main() {
  late AppDatabase db;
  late Repository repo;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = Repository(db);
  });
  tearDown(() => db.close());

  test('stores text only for important apps', () async {
    await repo.ingest(
      raw('a', 'secret chat'),
      cls,
      importantApps: {'com.whatsapp'},
    );
    await repo.ingest(
      raw('b', 'promo text', pkg: 'com.myntra'),
      cls,
      importantApps: {'com.whatsapp'},
    );
    final all = await repo.since(DateTime(2020));
    expect(all.firstWhere((e) => e.key == 'a').text, 'secret chat');
    expect(all.firstWhere((e) => e.key == 'b').text, '');
  });

  test('OTP / bank text is never persisted', () async {
    const otp = Classification(
      priority: Priority.normal,
      category: Category.otp,
      action: NotifAction.none,
      summary: 'OTP received',
    );
    await repo.ingest(
      raw('o', 'OTP is 123456', pkg: 'com.whatsapp'),
      otp,
      importantApps: {'com.whatsapp'},
    );
    final e = (await repo.since(DateTime(2020))).single;
    expect(e.text, 'OTP received');
    expect(e.text.contains('123456'), isFalse);
  });

  test('duplicate delivery is ignored', () async {
    final n = raw('a', 'hi');
    expect(await repo.ingest(n, cls, importantApps: {}), isNotNull);
    expect(await repo.ingest(n, cls, importantApps: {}), isNull);
    expect(await repo.eventCount(), 1);
  });

  test('purge deletes events older than 7 days', () async {
    await repo.ingest(
      raw('old', 'x', at: DateTime(2026, 10, 1)),
      cls,
      importantApps: {},
    );
    await repo.ingest(
      raw('new', 'x', at: DateTime(2026, 10, 13)),
      cls,
      importantApps: {},
    );
    final removed = await repo.purge(now: DateTime(2026, 10, 14));
    expect(removed, 1);
    expect((await repo.since(DateTime(2020))).single.key, 'new');
  });

  test('important apps toggle + sync keeps user choices', () async {
    await repo.syncApps(const [AppRef('a', 'A'), AppRef('b', 'B')]);
    await repo.setImportant('a', true);
    await repo.syncApps(const [AppRef('a', 'A'), AppRef('c', 'C')]);
    expect(await repo.importantPkgs(), {'a'});
    expect((await db.select(db.appPrefs).get()).length, 3);
  });

  test('learning boosts and caps', () async {
    for (var i = 0; i < 10; i++) {
      await repo.recordFeedback(1, 'Ravi', 'opened');
    }
    await repo.recordFeedback(1, 'Spam', 'wrong_priority');
    await repo.setStarred('Mummy', true);
    final k = await repo.knowledge();
    expect(k.learned['ravi'], 2.0);
    expect(k.learned['spam'], lessThan(0));
    expect(k.starred, {'mummy'});
  });

  test('wipe removes events and feedback', () async {
    await repo.ingest(raw('a', 'x'), cls, importantApps: {});
    await repo.recordFeedback(1, 'a', 'opened');
    await repo.wipeEvents();
    expect(await repo.eventCount(), 0);
    expect((await repo.knowledge()).learned, isEmpty);
  });
}
