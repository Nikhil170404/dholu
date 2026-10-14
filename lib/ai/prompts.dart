import '../core/types.dart';

/// JSON schema for notification classification (brief section 8, step 5).
const classificationSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'priority': {
      'type': 'string',
      'enum': ['urgent', 'important', 'normal', 'junk'],
    },
    'category': {
      'type': 'string',
      'enum': ['bill', 'delivery', 'message', 'work', 'promo', 'other'],
    },
    'action': {
      'type': 'string',
      'enum': ['reply', 'pay', 'track', 'none'],
    },
    'summary': {'type': 'string'},
  },
  'required': ['priority', 'category', 'action', 'summary'],
  'additionalProperties': false,
};

String classifySystemPrompt(Lang lang) =>
    '''
You sort phone notifications for an Indian user. Messages may be English, Hindi or Hinglish.
Reply with ONE JSON object: priority, category, action, summary.
priority: urgent (needs action today / from boss or family), important, normal, junk (ads, offers).
category: bill, delivery, message, work, promo, other.
action: reply (a person wrote), pay (bill/payment due), track (delivery), none.
summary: at most 8 words, ${lang == Lang.english ? 'English' : 'simple Hinglish'}.
Never copy OTPs, passwords or account numbers.

Examples:
Anil Sir: report 10 baje tak bhejna, client ko forward karna hai
{"priority":"urgent","category":"work","action":"reply","summary":"Report 10 baje tak"}
Bijli bill Rs 1840 due 15 Oct
{"priority":"important","category":"bill","action":"pay","summary":"Bijli bill due"}
Weekend sale 20% off on all items
{"priority":"junk","category":"promo","action":"none","summary":"Sale offer"}
''';

/// Validates model output. Returns null when it is not usable (caller keeps the rules result).
Classification? parseClassification(Map<String, dynamic>? j) {
  if (j == null) {
    return null;
  }
  Priority? pr;
  Category? ca;
  NotifAction? ac;
  for (final v in Priority.values) {
    if (v.name == j['priority']) {
      pr = v;
    }
  }
  for (final v in Category.values) {
    if (v.name == j['category']) {
      ca = v;
    }
  }
  for (final v in NotifAction.values) {
    if (v.name == j['action']) {
      ac = v;
    }
  }
  final summary = j['summary'];
  if (pr == null || ca == null || ac == null || summary is! String) {
    return null;
  }
  // Model must never introduce OTP/bank categories: those are decided by the filter only.
  if (ca == Category.otp || ca == Category.bank) {
    return null;
  }
  final words = summary
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) {
    return null;
  }
  return Classification(
    priority: pr,
    category: ca,
    action: ac,
    summary: words.take(8).join(' '),
  );
}
