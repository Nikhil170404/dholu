import 'types.dart';

/// A stored, already-classified event (what the DB hands to the digest).
class StoredEvent {
  const StoredEvent({
    required this.id,
    required this.key,
    required this.pkg,
    required this.appName,
    required this.sender,
    required this.text,
    required this.postedAt,
    required this.classification,
    this.handled = false,
  });
  final int id;
  final String key;
  final String pkg;
  final String appName;
  final String sender;
  final String text;
  final DateTime postedAt;
  final Classification classification;
  final bool handled;
}

class DigestItem {
  const DigestItem({
    required this.title,
    required this.appName,
    required this.pkg,
    required this.action,
    required this.urgent,
    required this.eventIds,
    required this.latestKey,
    required this.category,
    this.count = 1,
  });
  final String title;
  final String appName;
  final String pkg;
  final NotifAction action;
  final bool urgent;
  final List<int> eventIds;

  /// Key of the most recent notification (target of the redirect).
  final String latestKey;
  final Category category;
  final int count;
}

class Digest {
  const Digest({required this.items, required this.hiddenCount});
  final List<DigestItem> items;
  final int hiddenCount;
  List<DigestItem> get urgent => items.where((e) => e.urgent).toList();
  int get importantCount => items.length;
}

class DigestBuilder {
  const DigestBuilder({this.lang = Lang.hinglish, this.maxItems = 6});
  final Lang lang;
  final int maxItems;

  /// Groups events from important apps into lines; everything else is "hidden".
  Digest build(List<StoredEvent> events, Set<String> importantApps) {
    final important = <StoredEvent>[];
    var hidden = 0;
    for (final e in events) {
      if (e.handled) continue;
      final p = e.classification.priority;
      final cat = e.classification.category;
      final keep =
          importantApps.contains(e.pkg) &&
          (p == Priority.urgent || p == Priority.important) &&
          cat != Category.otp &&
          cat != Category.bank;
      keep ? important.add(e) : hidden++;
    }

    final groups = <String, List<StoredEvent>>{};
    for (final e in important) {
      final k =
          e.classification.category == Category.message ||
              e.classification.category == Category.work
          ? '${e.pkg}|${e.sender.toLowerCase()}'
          : '${e.pkg}|${e.id}';
      (groups[k] ??= []).add(e);
    }

    final items = <DigestItem>[];
    for (final g in groups.values) {
      g.sort((a, b) => b.postedAt.compareTo(a.postedAt));
      final latest = g.first;
      final urgent = g.any((e) => e.classification.priority == Priority.urgent);
      final n = g.length;
      final title = n > 1
          ? (lang == Lang.english
                ? '${latest.sender}: $n messages'
                : '${latest.sender} ke $n messages')
          : (latest.classification.category == Category.message ||
                    latest.classification.category == Category.work
                ? '${latest.sender}: ${latest.classification.summary}'
                : latest.classification.summary);
      items.add(
        DigestItem(
          title: title,
          appName: latest.appName,
          pkg: latest.pkg,
          action: latest.classification.action,
          urgent: urgent,
          eventIds: [for (final e in g) e.id],
          latestKey: latest.key,
          category: latest.classification.category,
          count: n,
        ),
      );
    }

    items.sort((a, b) {
      if (a.urgent != b.urgent) return a.urgent ? -1 : 1;
      return b.count.compareTo(a.count);
    });
    final shown = items.take(maxItems).toList();
    final overflow = items.skip(maxItems).fold<int>(0, (s, e) => s + e.count);
    return Digest(items: shown, hiddenCount: hidden + overflow);
  }
}
