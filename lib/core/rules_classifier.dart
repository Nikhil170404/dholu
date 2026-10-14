import 'dates.dart';
import 'sensitive_filter.dart';
import 'types.dart';

/// Contact and learned-sender knowledge fed to the scorer.
class SenderKnowledge {
  const SenderKnowledge({this.starred = const {}, this.learned = const {}});

  /// Lower-cased contact names marked important (family, boss, ...).
  final Set<String> starred;

  /// Lower-cased sender -> boost in [-2, 2] learned from taps/dismissals.
  final Map<String, double> learned;
}

/// Cheap, deterministic first pass (brief section 8, steps 3-4).
abstract class Classifier {
  Future<Classification> classify(RawNotification n, DateTime now);
}

class RulesClassifier implements Classifier {
  RulesClassifier({
    this.knowledge = const SenderKnowledge(),
    this.lang = Lang.hinglish,
    this.filter = const SensitiveFilter(),
  });

  final SenderKnowledge knowledge;
  final Lang lang;
  final SensitiveFilter filter;

  static final _urgent = RegExp(
    r'\b(urgent|asap|immediately|emergency|deadline|jaldi|turant|abhi|important|zaroori|zaruri)\b',
    caseSensitive: false,
  );
  static final _soon = RegExp(
    r'\b(kal tak|aaj tak|aaj|by eod|eod|by tonight|bhejna|bhej do|send me|reply|call me|call karo)\b',
    caseSensitive: false,
  );
  static final _billWords = RegExp(
    r'\b(due|bill|overdue|payment failed|payment due|emi|recharge|premium|invoice|pay now|pending payment|bhugtan)\b',
    caseSensitive: false,
  );
  static final _failed = RegExp(
    r'\b(payment failed|failed|declined|overdue|expired|expiring)\b',
    caseSensitive: false,
  );
  static final _delivery = RegExp(
    r'\b(out for delivery|delivered|arriving|shipped|dispatched|order|delivery|courier|track)\b',
    caseSensitive: false,
  );
  static final _promo = RegExp(
    r'(\d+\s?%\s?off|\bsale\b|\boffer\b|\breward|cashback|coupon|discount|deal of|flat \d+|limited time|shop now|buy now|lowest price|mega|bumper)',
    caseSensitive: false,
  );
  static final _work = RegExp(
    r'\b(report|client|meeting|deadline|boss|sir|madam|presentation|invoice|office|standup|review)\b',
    caseSensitive: false,
  );

  static const _messagingPkgs = {
    'com.whatsapp',
    'com.whatsapp.w4b',
    'org.telegram.messenger',
    'com.google.android.apps.messaging',
    'com.facebook.orca',
    'org.thoughtcrime.securesms',
    'com.truecaller',
    'com.android.mms',
  };

  @override
  Future<Classification> classify(RawNotification n, DateTime now) async =>
      classifySync(n, now);

  Classification classifySync(RawNotification n, DateTime now) {
    var f = filter.apply(n.title, n.text);
    if (!f.sensitive && n.sensitiveHint != null) {
      f = FilterResult.redacted(
        n.sensitiveHint == 'bank'
            ? SensitiveKind.bank
            : (n.sensitiveHint == 'secret'
                  ? SensitiveKind.secret
                  : SensitiveKind.otp),
        n.sensitiveHint == 'bank' ? 'Bank message' : 'OTP received',
      );
    }
    if (f.sensitive) {
      return Classification(
        priority: Priority.normal,
        category: f.kind == SensitiveKind.bank ? Category.bank : Category.otp,
        action: NotifAction.none,
        summary: f.text,
      );
    }
    final text = '${n.title} ${n.text}';
    var score = 0.0;

    final isMessage = n.isMessaging || _messagingPkgs.contains(n.pkg);
    final sender = n.title.trim().toLowerCase();
    if (isMessage) score += 1;
    if (knowledge.starred.contains(sender)) score += 3;
    score += (knowledge.learned[sender] ?? 0).clamp(-2.0, 2.0);

    final urgent = _urgent.hasMatch(text);
    final soon = _soon.hasMatch(text);
    final bill = _billWords.hasMatch(text);
    final delivery = _delivery.hasMatch(text);
    final promo = _promo.hasMatch(text);
    final work = _work.hasMatch(text);

    if (urgent) score += 3;
    if (soon) score += 1.5;
    if (bill) score += 2;
    if (_failed.hasMatch(text)) score += 1.5;
    if (delivery) score += 1.5;
    if (work) score += 1;
    if (promo) score -= 4;

    final due = findDueDate(text, now);
    if (due != null && !promo) {
      final hours = due.difference(now).inHours;
      if (hours <= 48) score += 2;
      if (hours < 0) score += 1;
    }

    final category = promo
        ? Category.promo
        : bill
        ? Category.bill
        : delivery
        ? Category.delivery
        : work
        ? Category.work
        : isMessage
        ? Category.message
        : Category.other;

    final action = switch (category) {
      Category.bill => NotifAction.pay,
      Category.delivery => NotifAction.track,
      Category.message || Category.work => NotifAction.reply,
      _ => NotifAction.none,
    };

    final priority = score >= 5
        ? Priority.urgent
        : score >= 2
        ? Priority.important
        : score <= -2
        ? Priority.junk
        : Priority.normal;

    return Classification(
      priority: priority,
      category: category,
      action: action,
      summary: _summary(n, category, due, now),
      score: score,
    );
  }

  String _summary(RawNotification n, Category c, DateTime? due, DateTime now) {
    final en = lang == Lang.english;
    final body = n.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    switch (c) {
      case Category.bill:
        final subject = body
            .split(
              RegExp(r'\b(rs\.?|inr|₹|due|is due|of)\b', caseSensitive: false),
            )
            .first
            .trim();
        final name = subject.isEmpty
            ? (en ? 'Bill' : 'Bill')
            : _words(subject, 3);
        return due != null
            ? (en
                  ? '$name due ${relativeDay(due, now, lang)}'
                  : '$name ${relativeDay(due, now, lang)} due')
            : (en ? '$name pending' : '$name baaki hai');
      case Category.delivery:
        if (RegExp(r'out for delivery', caseSensitive: false).hasMatch(body)) {
          return en ? 'Order out for delivery' : 'Order aaj aayega';
        }
        if (RegExp(r'delivered', caseSensitive: false).hasMatch(body)) {
          return en ? 'Order delivered' : 'Order pahunch gaya';
        }
        return _words(body, 8);
      case Category.promo:
        return en ? 'Sale offer' : 'Sale offer';
      default:
        return _words(body.isEmpty ? n.title : body, 8);
    }
  }

  static String _words(String s, int max) {
    final w = s.split(' ').where((e) => e.isNotEmpty).toList();
    return w.length <= max ? w.join(' ') : w.take(max).join(' ');
  }
}
