import 'dart:ui' show Color, DartPluginRegistrant;

import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/digest.dart';
import '../l10n/strings.dart';
import '../work/scheduler.dart';

class DigestContent {
  const DigestContent({
    required this.title,
    required this.body,
    this.lines = const [],
  });
  final String title;
  final String body;

  /// Detail lines (InboxStyle). Empty unless the user allowed lock-screen detail.
  final List<String> lines;
}

/// Lock-screen privacy (brief section 8): by default the notification carries only counts.
/// Message text is included only when the user turned "Lock screen par detail dikhao" on.
DigestContent buildDigestContent(Digest d, Tr tr, {required bool detail}) {
  final n = d.importantCount;
  final title = n == 0
      ? tr('digest_none')
      : (n == 1 ? tr('digest_title_1') : tr('digest_title', {'n': n}));
  final hidden = d.hiddenCount > 0
      ? tr('digest_hidden', {'n': d.hiddenCount})
      : '';
  if (!detail || n == 0) {
    return DigestContent(
      title: title,
      body: [tr('digest_tap'), hidden].where((e) => e.isNotEmpty).join('  ·  '),
    );
  }
  return DigestContent(
    title: title,
    body: hidden.isEmpty ? tr('digest_tap') : hidden,
    lines: [for (final i in d.items) '${i.urgent ? '• ' : ''}${i.title}'],
  );
}

class UrgentContent {
  const UrgentContent({required this.title, required this.body});
  final String title;
  final String body;
}

UrgentContent buildUrgentContent(
  StoredEvent e,
  Tr tr, {
  required bool detail,
}) => detail
    ? UrgentContent(
        title: '${e.appName}: ${e.sender}',
        body: e.classification.summary,
      )
    : UrgentContent(title: tr('urgent_title'), body: tr('urgent_hidden_body'));

/// Payloads carried by notification taps, parsed by the router.
class NotifPayload {
  const NotifPayload(this.kind, [this.eventId]);
  final String kind; // summary | alert | draft
  final int? eventId;
  String encode() => eventId == null ? kind : '$kind:$eventId';
  static NotifPayload? parse(String? s) {
    if (s == null || s.isEmpty) {
      return null;
    }
    final parts = s.split(':');
    return NotifPayload(
      parts[0],
      parts.length > 1 ? int.tryParse(parts[1]) : null,
    );
  }
}

typedef NotifTapHandler = void Function(String? payload, String? actionId);

/// Runs in a background isolate when a notification action without UI is tapped while the app
/// is not in the foreground ("Baad mein" -> remind in 10 minutes).
@pragma('vm:entry-point')
Future<void> dholuNotificationBackground(NotificationResponse r) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  final p = NotifPayload.parse(r.payload);
  if (r.actionId == 'later' && p?.eventId != null) {
    await const Scheduler().remindIn(p!.eventId!);
  }
}

/// What the app needs from the notification layer (lets tests swap in a recorder).
abstract class AppNotifier {
  Future<void> init(Tr tr, {NotifTapHandler? onTap});
  Future<bool> requestPermission();
  Future<String?> launchPayload();
  Future<void> showDigest(Digest d, Tr tr, {required bool detail});
  Future<void> showUrgent(
    StoredEvent e,
    Tr tr, {
    required bool detail,
    required bool sound,
  });
  Future<void> showReminder(StoredEvent e, Tr tr);
  Future<void> cancelFor(int eventId);
}

class NotificationService implements AppNotifier {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _p = plugin ?? FlutterLocalNotificationsPlugin();
  final FlutterLocalNotificationsPlugin _p;

  static const digestChannel = 'digest';
  static const urgentChannel = 'urgent';
  static const urgentQuietChannel = 'urgent_quiet';
  static const reminderChannel = 'reminder';
  static const digestId = 1;
  static const _color = Color(0xFF2F4BDB);

  @override
  Future<void> init(
    Tr tr, {
    NotifTapHandler? onTap,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundTap,
  }) async {
    await _p.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) =>
          onTap?.call(r.payload, r.actionId),
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundTap ?? dholuNotificationBackground,
    );
    final a = _p
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await a?.createNotificationChannel(
      AndroidNotificationChannel(
        digestChannel,
        tr('ch_digest'),
        importance: Importance.defaultImportance,
        playSound: false,
      ),
    );
    // Sound is fixed per channel, so the drum sound lives on one channel and silence on another.
    await a?.createNotificationChannel(
      AndroidNotificationChannel(
        urgentChannel,
        tr('ch_urgent'),
        importance: Importance.high,
        sound: const RawResourceAndroidNotificationSound('drumroll'),
      ),
    );
    await a?.createNotificationChannel(
      AndroidNotificationChannel(
        urgentQuietChannel,
        tr('ch_urgent_quiet'),
        importance: Importance.high,
        playSound: false,
      ),
    );
    await a?.createNotificationChannel(
      AndroidNotificationChannel(
        reminderChannel,
        tr('ch_reminder'),
        importance: Importance.defaultImportance,
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    final a = _p
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await a?.requestNotificationsPermission() ?? false;
  }

  @override
  Future<String?> launchPayload() async {
    final d = await _p.getNotificationAppLaunchDetails();
    return d?.didNotificationLaunchApp == true
        ? d!.notificationResponse?.payload
        : null;
  }

  @override
  Future<void> showDigest(Digest d, Tr tr, {required bool detail}) {
    final c = buildDigestContent(d, tr, detail: detail);
    return _p.show(
      id: digestId,
      title: c.title,
      body: c.body,
      payload: const NotifPayload('summary').encode(),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          digestChannel,
          tr('ch_digest'),
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.recommendation,
          color: _color,
          playSound: false,
          styleInformation: c.lines.isEmpty
              ? null
              : InboxStyleInformation(
                  c.lines,
                  contentTitle: c.title,
                  summaryText: c.body,
                ),
        ),
      ),
    );
  }

  @override
  Future<void> showUrgent(
    StoredEvent e,
    Tr tr, {
    required bool detail,
    required bool sound,
  }) {
    final c = buildUrgentContent(e, tr, detail: detail);
    return _p.show(
      id: 1000 + e.id % 100000,
      title: c.title,
      body: c.body,
      payload: NotifPayload('alert', e.id).encode(),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          sound ? urgentChannel : urgentQuietChannel,
          sound ? tr('ch_urgent') : tr('ch_urgent_quiet'),
          importance: Importance.high,
          priority: Priority.high,
          visibility: detail
              ? NotificationVisibility.public
              : NotificationVisibility.private,
          category: AndroidNotificationCategory.message,
          color: _color,
          actions: [
            AndroidNotificationAction(
              'reply',
              tr('a_reply'),
              showsUserInterface: true,
            ),
            AndroidNotificationAction('later', tr('notif_later')),
          ],
        ),
      ),
    );
  }

  @override
  Future<void> showReminder(StoredEvent e, Tr tr) => _p.show(
    id: 200000 + e.id % 100000,
    title: tr('remind_title'),
    body: tr('urgent_hidden_body'),
    payload: NotifPayload('alert', e.id).encode(),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        reminderChannel,
        tr('ch_reminder'),
        importance: Importance.defaultImportance,
        visibility: NotificationVisibility.private,
        color: _color,
      ),
    ),
  );

  @override
  Future<void> cancelFor(int eventId) => _p.cancel(id: 1000 + eventId % 100000);
}
