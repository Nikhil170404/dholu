import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'core/digest.dart';
import 'notif/notification_service.dart';
import 'settings/settings.dart';
import 'shutter/shutter_alert.dart';

/// Wraps the router: starts ingestion, wires notification taps, schedules the morning summary,
/// and decides how an urgent item is shown (in-app shutter in the foreground, a notification otherwise).
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  StreamSubscription<StoredEvent>? _urgentSub;
  StoredEvent? _alert;
  int _alertRun = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _urgentSub?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final tr = ref.read(trProvider);
    final notifier = ref.read(notifierProvider);
    await notifier.init(tr, onTap: _onTap);
    final payload = await notifier.launchPayload();
    if (payload != null) {
      _route(payload);
    }
    if (ref.read(settingsProvider).onboarded) {
      await _startIngest();
    }
  }

  Future<void> _startIngest() async {
    if (_started) {
      return;
    }
    _started = true;
    final ingest = ref.read(ingestProvider);
    _urgentSub = ingest.urgent.listen(_onUrgent);
    await ingest.start();
    await _syncSchedule();
  }

  Future<void> _syncSchedule() async {
    final s = ref.read(settingsProvider);
    final sched = ref.read(schedulerProvider);
    if (s.summaryEnabled) {
      await sched.scheduleMorning(s.summaryHour, s.summaryMinute);
    } else {
      await sched.cancelMorning();
    }
  }

  void _onTap(String? payload, String? actionId) {
    final p = NotifPayload.parse(payload);
    if (p == null) {
      return;
    }
    if (actionId == 'later' && p.eventId != null) {
      ref.read(schedulerProvider).remindIn(p.eventId!);
      return;
    }
    if (actionId == 'reply' && p.eventId != null) {
      ref.read(routerProvider).go('/draft/${p.eventId}');
      return;
    }
    _route(payload!);
  }

  void _route(String payload) {
    final p = NotifPayload.parse(payload);
    final r = ref.read(routerProvider);
    switch (p?.kind) {
      case 'summary':
        r.go('/home');
        r.push('/summary');
      case 'alert':
        if (p?.eventId != null) {
          r.go('/home');
          r.push('/alert/${p!.eventId}');
        }
      case 'draft':
        if (p?.eventId != null) {
          r.go('/draft/${p!.eventId}');
        }
    }
  }

  Future<void> _onUrgent(StoredEvent e) async {
    final s = ref.read(settingsProvider);
    final tr = ref.read(trProvider);
    final state = WidgetsBinding.instance.lifecycleState;
    // null = before the first lifecycle event, while the UI is already running.
    final foreground = state == null || state == AppLifecycleState.resumed;
    if (foreground) {
      if (s.drumSound) {
        ref.read(drumPlayerProvider).play();
      }
      setState(() {
        _alert = e;
        _alertRun++;
      });
    } else {
      await ref
          .read(notifierProvider)
          .showUrgent(e, tr, detail: s.lockScreenDetail, sound: s.drumSound);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(accessGrantedProvider);
      if (_started) {
        ref.read(ingestProvider).drainQueue();
      } else if (ref.read(settingsProvider).onboarded) {
        _startIngest();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start ingestion as soon as onboarding finishes; reschedule when summary settings change.
    ref.listen(settingsProvider.select((s) => s.onboarded), (a, b) {
      if (b == true) {
        _startIngest();
      }
    });
    ref.listen(
      settingsProvider.select(
        (s) => (s.summaryEnabled, s.summaryHour, s.summaryMinute),
      ),
      (a, b) {
        if (_started) {
          _syncSchedule();
        }
      },
    );
    final e = _alert;
    return Stack(
      children: [
        widget.child,
        if (e != null)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Material(
                type: MaterialType.transparency,
                child: ShutterAlert(
                  key: ValueKey(_alertRun),
                  title: '${e.sender}: ${e.classification.summary}',
                  source: e.appName,
                  onOpen: () {
                    setState(() => _alert = null);
                    ref.read(routerProvider).push('/alert/${e.id}');
                  },
                  onFinished: () => setState(() => _alert = null),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
