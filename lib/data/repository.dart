import 'package:drift/drift.dart';

import '../core/digest.dart';
import '../core/rules_classifier.dart';
import '../core/types.dart';
import 'database.dart';

class AppRef {
  const AppRef(this.pkg, this.name);
  final String pkg;
  final String name;
}

/// Single entry point to storage. Enforces the privacy rules:
/// - text is stored only for apps the user marked important (others are just counted)
/// - OTP / bank bodies are never stored (placeholder only)
/// - everything older than [retention] is deleted.
class Repository {
  Repository(this.db, {this.onImportantChanged});
  final AppDatabase db;

  /// Called with the new important set after it changes (shared with the Kotlin listener).
  final Future<void> Function(Set<String>)? onImportantChanged;

  static const retention = Duration(days: 7);

  // ---- events ----

  /// Returns the new row id, or null when the same notification was already stored.
  Future<int?> ingest(
    RawNotification n,
    Classification c, {
    required Set<String> importantApps,
  }) async {
    final keepText =
        importantApps.contains(n.pkg) &&
        c.category != Category.otp &&
        c.category != Category.bank;
    try {
      return await db
          .into(db.notificationEvents)
          .insert(
            NotificationEventsCompanion.insert(
              key: n.key,
              pkg: n.pkg,
              appName: n.appName,
              sender: n.title,
              textRedacted: keepText
                  ? n.text
                  : (c.category == Category.otp || c.category == Category.bank
                        ? c.summary
                        : ''),
              ts: n.postedAt,
              category: c.category.name,
              priority: c.priority.name,
              action: c.action.name,
              summary: c.summary,
            ),
          );
    } on Exception {
      return null; // unique (key, ts) violation: duplicate delivery
    }
  }

  Future<List<StoredEvent>> since(DateTime from) async {
    final rows =
        await (db.select(db.notificationEvents)
              ..where((t) => t.ts.isBiggerOrEqualValue(from))
              ..orderBy([(t) => OrderingTerm.desc(t.ts)]))
            .get();
    return rows.map(_toStored).toList();
  }

  Future<List<StoredEvent>> forSender(String sender, {int limit = 20}) async {
    final rows =
        await (db.select(db.notificationEvents)
              ..where((t) => t.sender.equals(sender))
              ..orderBy([(t) => OrderingTerm.desc(t.ts)])
              ..limit(limit))
            .get();
    return rows.map(_toStored).toList();
  }

  Future<void> markHandled(List<int> ids) =>
      (db.update(db.notificationEvents)..where((t) => t.id.isIn(ids))).write(
        const NotificationEventsCompanion(handled: Value(true)),
      );

  /// Deletes events older than [retention]. Returns rows removed.
  Future<int> purge({DateTime? now}) {
    final cutoff = (now ?? DateTime.now()).subtract(retention);
    return (db.delete(
      db.notificationEvents,
    )..where((t) => t.ts.isSmallerThanValue(cutoff))).go();
  }

  Future<int> eventCount() async =>
      (await db.select(db.notificationEvents).get()).length;

  /// "Delete my data": events, feedback and learned data. Keeps app choices.
  Future<void> wipeEvents() async {
    await db.delete(db.notificationEvents).go();
    await db.delete(db.feedbacks).go();
  }

  Future<void> wipeEverything() async {
    await wipeEvents();
    await db.delete(db.appPrefs).go();
    await db.delete(db.contacts).go();
  }

  StoredEvent toStoredEvent(NotificationEvent r) => _toStored(r);

  StoredEvent _toStored(NotificationEvent r) => StoredEvent(
    id: r.id,
    key: r.key,
    pkg: r.pkg,
    appName: r.appName,
    sender: r.sender,
    text: r.textRedacted,
    postedAt: r.ts,
    handled: r.handled,
    classification: Classification(
      priority: Priority.values.byName(r.priority),
      category: Category.values.byName(r.category),
      action: NotifAction.values.byName(r.action),
      summary: r.summary,
    ),
  );

  // ---- apps ----

  Future<void> syncApps(List<AppRef> apps) async {
    final existing = {
      for (final a in await db.select(db.appPrefs).get()) a.pkg,
    };
    await db.batch((b) {
      for (final a in apps) {
        if (existing.contains(a.pkg)) continue;
        b.insert(
          db.appPrefs,
          AppPrefsCompanion.insert(pkg: a.pkg, name: a.name),
        );
      }
    });
  }

  Stream<List<AppPref>> watchApps() => (db.select(
    db.appPrefs,
  )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();

  Future<Set<String>> importantPkgs() async => {
    for (final a in await (db.select(
      db.appPrefs,
    )..where((t) => t.important)).get())
      a.pkg,
  };

  Future<void> setImportant(String pkg, bool on) async {
    await (db.update(db.appPrefs)..where((t) => t.pkg.equals(pkg))).write(
      AppPrefsCompanion(important: Value(on)),
    );
    await onImportantChanged?.call(await importantPkgs());
  }

  // ---- contacts + learning ----

  Future<void> setStarred(String name, bool on) async {
    final n = name.trim().toLowerCase();
    if (n.isEmpty) return;
    if (on) {
      await db
          .into(db.contacts)
          .insertOnConflictUpdate(ContactsCompanion.insert(name: n));
    } else {
      await (db.delete(db.contacts)..where((t) => t.name.equals(n))).go();
    }
  }

  Future<void> recordFeedback(
    int eventId,
    String sender,
    String userAction, {
    DateTime? now,
  }) => db
      .into(db.feedbacks)
      .insert(
        FeedbacksCompanion.insert(
          eventId: eventId,
          sender: sender.toLowerCase(),
          userAction: userAction,
          ts: now ?? DateTime.now(),
        ),
      );

  /// Starred contacts + per-sender boost learned from taps/dismissals.
  Future<SenderKnowledge> knowledge() async {
    final starred = {
      for (final c in await db.select(db.contacts).get()) c.name,
    };
    final learned = <String, double>{};
    for (final f in await db.select(db.feedbacks).get()) {
      final d = switch (f.userAction) {
        'opened' => 0.4,
        'later' => 0.1,
        'dismissed' => -0.4,
        'wrong_priority' => -0.8,
        _ => 0.0,
      };
      learned[f.sender] = ((learned[f.sender] ?? 0) + d).clamp(-2.0, 2.0);
    }
    return SenderKnowledge(starred: starred, learned: learned);
  }
}

extension RepositoryRefine on Repository {
  /// Replaces the rules result with a refined one (priority, category, action, summary).
  Future<void> updateClassification(int id, Classification c) =>
      (db.update(db.notificationEvents)..where((t) => t.id.equals(id))).write(
        NotificationEventsCompanion(
          priority: Value(c.priority.name),
          category: Value(c.category.name),
          action: Value(c.action.name),
          summary: Value(c.summary),
        ),
      );

  Future<StoredEvent?> byId(int id) async {
    final r = await (db.select(
      db.notificationEvents,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : toStoredEvent(r);
  }

  /// Distinct recent senders (for the email "use context" picker), newest first.
  Future<List<String>> recentSenders({int limit = 20}) async {
    final rows =
        await (db.select(db.notificationEvents)
              ..where((t) => t.textRedacted.equals('').not())
              ..orderBy([(t) => OrderingTerm.desc(t.ts)])
              ..limit(200))
            .get();
    final seen = <String>[];
    for (final r in rows) {
      if (r.sender.trim().isNotEmpty && !seen.contains(r.sender)) {
        seen.add(r.sender);
      }
      if (seen.length >= limit) {
        break;
      }
    }
    return seen;
  }

  /// Per-app counts for the "What Dholu knows" screen.
  Future<Map<String, int>> countsByApp() async {
    final rows = await db.select(db.notificationEvents).get();
    final m = <String, int>{};
    for (final r in rows) {
      m[r.appName] = (m[r.appName] ?? 0) + 1;
    }
    return m;
  }
}
