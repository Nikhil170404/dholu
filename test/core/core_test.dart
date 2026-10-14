import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/core/digest.dart';
import 'package:dholu/core/rules_classifier.dart';
import 'package:dholu/core/sensitive_filter.dart';
import 'package:dholu/core/types.dart';

RawNotification n(
  String title,
  String text, {
  String pkg = 'com.whatsapp',
  bool msg = true,
}) => RawNotification(
  key: 'k',
  pkg: pkg,
  appName: 'App',
  title: title,
  text: text,
  postedAt: DateTime(2026, 10, 14, 9),
  isMessaging: msg,
);

final now = DateTime(2026, 10, 14, 9);

void main() {
  group('SensitiveFilter', () {
    const f = SensitiveFilter();
    test('redacts OTPs', () {
      for (final t in [
        'Your OTP is 482913. Do not share it.',
        '482913 is your verification code',
        'Use code 123456 to log in',
        'ओटीपी 4829 kisi se share na karein',
        'OTP: 5521.',
        'Dear user, 778899 is the OTP for your txn. Valid 10 mins.',
        'G-123456 is your Google verification code',
      ]) {
        final r = f.apply('Bank', t);
        expect(r.sensitive, isTrue, reason: t);
        expect(r.text, 'OTP received');
      }
    });
    test('redacts bank transaction bodies but not bills', () {
      expect(
        f
            .apply(
              'HDFC',
              'Rs 5,000 debited from A/c XX1234 on 14-Oct. Avl bal Rs 12,000',
            )
            .kind,
        SensitiveKind.bank,
      );
      expect(
        f.apply('Paytm', 'Bijli bill Rs 1840 due 15 Oct').sensitive,
        isFalse,
      );
    });
    test('redacts passwords', () {
      expect(
        f.apply('x', 'Your password is hunter2').kind,
        SensitiveKind.secret,
      );
    });
    test('keeps normal chat', () {
      expect(
        f.apply('Mummy', 'Khana kha liya? 2 baje aana').sensitive,
        isFalse,
      );
    });
    test('placeholder never contains the code', () {
      expect(f.apply('x', 'OTP 998877').text.contains('998877'), isFalse);
    });
  });

  group('RulesClassifier', () {
    final c = RulesClassifier();
    test('boss deadline is urgent + reply', () {
      final r = c.classifySync(
        n(
          'Anil Sir',
          'report 10 baje tak bhejna, client ko forward karna hai urgent',
        ),
        now,
      );
      expect(r.priority, Priority.urgent);
      expect(r.action, NotifAction.reply);
    });
    test('bill due tomorrow is important, pay, Hinglish summary', () {
      final r = c.classifySync(
        n(
          'Paytm',
          'Bijli bill Rs 1840 due kal',
          pkg: 'net.one97.paytm',
          msg: false,
        ),
        now,
      );
      expect(r.category, Category.bill);
      expect(r.action, NotifAction.pay);
      expect(r.priority, anyOf(Priority.important, Priority.urgent));
      expect(r.summary, 'Bijli bill kal due');
    });
    test('bill with explicit date', () {
      final r = c.classifySync(
        n(
          'Paytm',
          'Bijli bill Rs 1840 due 15 Oct',
          pkg: 'net.one97.paytm',
          msg: false,
        ),
        now,
      );
      expect(r.summary, 'Bijli bill kal due');
    });
    test('dd/mm due date', () {
      final r = c.classifySync(n('Paytm', 'Recharge due 15/10', pkg: 'p', msg: false), now);
      expect(r.summary, contains('kal due'));
    });
    test('promo is junk', () {
      final r = c.classifySync(
        n(
          'Myntra',
          'Weekend sale 20% off on all items',
          pkg: 'com.myntra',
          msg: false,
        ),
        now,
      );
      expect(r.priority, Priority.junk);
      expect(r.category, Category.promo);
    });
    test('out for delivery -> track', () {
      final r = c.classifySync(
        n(
          'Amazon',
          'Your order is out for delivery',
          pkg: 'in.amazon',
          msg: false,
        ),
        now,
      );
      expect(r.action, NotifAction.track);
      expect(r.summary, 'Order aaj aayega');
    });
    test('starred contact boosts', () {
      final k = RulesClassifier(
        knowledge: const SenderKnowledge(starred: {'mummy'}),
      );
      expect(
        k.classifySync(n('Mummy', 'ghar kab aaoge'), now).priority,
        isNot(Priority.normal),
      );
      expect(
        c.classifySync(n('Random', 'ghar kab aaoge'), now).priority,
        Priority.normal,
      );
    });
    test('OTP never classified with content', () {
      final r = c.classifySync(n('Bank', 'OTP 123456 for payment'), now);
      expect(r.category, Category.otp);
      expect(r.summary.contains('123456'), isFalse);
    });
    test('summary is at most 8 words', () {
      final r = c.classifySync(
        n('Ravi', 'one two three four five six seven eight nine ten eleven'),
        now,
      );
      expect(
        r.summary.split(' ').length,
        lessThanOrEqualTo(9),
      ); // "Ravi" not included; body capped at 8
    });
    test('English language summaries', () {
      final e = RulesClassifier(lang: Lang.english);
      expect(
        e
            .classifySync(
              n('Paytm', 'Bijli bill Rs 1840 due kal', pkg: 'p', msg: false),
              now,
            )
            .summary,
        'Bijli bill due tomorrow',
      );
    });
  });

  group('DigestBuilder', () {
    StoredEvent ev(
      int id,
      String pkg,
      String sender,
      Priority p, {
      Category cat = Category.message,
      String text = 'hi',
    }) => StoredEvent(
      id: id,
      key: 'k$id',
      pkg: pkg,
      appName: 'WhatsApp',
      sender: sender,
      text: text,
      postedAt: DateTime(2026, 10, 14, 9, id),
      classification: Classification(
        priority: p,
        category: cat,
        action: NotifAction.reply,
        summary: text,
      ),
    );
    test('merges many messages from one sender and counts hidden', () {
      final events = [
        for (var i = 0; i < 5; i++)
          ev(i, 'com.whatsapp', 'Mummy', Priority.important),
        ev(
          10,
          'com.whatsapp',
          'Anil Sir',
          Priority.urgent,
          text: 'report bhejna',
        ),
        ev(11, 'com.myntra', 'Myntra', Priority.junk, cat: Category.promo),
        ev(12, 'com.other', 'X', Priority.important), // app not important
      ];
      final d = const DigestBuilder().build(events, {'com.whatsapp'});
      expect(d.items.first.urgent, isTrue);
      expect(d.items.any((i) => i.title == 'Mummy ke 5 messages'), isTrue);
      expect(d.hiddenCount, 2);
    });
    test('never surfaces OTP/bank', () {
      final d = const DigestBuilder().build(
        [ev(1, 'com.whatsapp', 'Bank', Priority.urgent, cat: Category.otp)],
        {'com.whatsapp'},
      );
      expect(d.items, isEmpty);
      expect(d.hiddenCount, 1);
    });
  });
}
