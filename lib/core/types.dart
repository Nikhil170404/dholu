/// Shared domain types. Pure Dart: no Flutter imports, so it is unit-testable.
enum Lang { hinglish, english }

enum Priority { urgent, important, normal, junk }

enum Category { bill, delivery, message, work, promo, otp, bank, other }

enum NotifAction { reply, pay, track, none }

/// A notification as captured by the native listener, before any storage.
class RawNotification {
  const RawNotification({
    required this.key,
    required this.pkg,
    required this.appName,
    required this.title,
    required this.text,
    required this.postedAt,
    this.isMessaging = false,
    this.hasContentIntent = false,
    this.sensitiveHint,
  });

  /// Native StatusBarNotification key; also the handle for firing the contentIntent.
  final String key;
  final String pkg;
  final String appName;

  /// Usually the sender or conversation name.
  final String title;
  final String text;
  final DateTime postedAt;

  /// Category MESSAGE / conversation style.
  final bool isMessaging;
  final bool hasContentIntent;

  /// "otp" | "bank" | "secret" when the native guard already flagged it (text was blanked).
  final String? sensitiveHint;
}

class Classification {
  const Classification({
    required this.priority,
    required this.category,
    required this.action,
    required this.summary,
    this.score = 0,
  });
  final Priority priority;
  final Category category;
  final NotifAction action;

  /// At most 8 words.
  final String summary;
  final double score;

  Map<String, dynamic> toJson() => {
    'priority': priority.name,
    'category': category.name,
    'action': action.name,
    'summary': summary,
  };
}
