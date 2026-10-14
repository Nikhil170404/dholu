import 'dart:async';

import '../ai/llm.dart';
import '../ai/refiner.dart';
import '../core/digest.dart';
import '../core/rules_classifier.dart';
import '../core/types.dart';
import '../data/repository.dart';
import '../native/native_bridge.dart';

/// Capture -> sensitive filter -> rules -> store (-> optional on-device refinement).
/// Cheap steps first, the model last (brief section 8). Works the same in the foreground
/// (live stream) and in the WorkManager isolate (queue drain, no model).
class IngestService {
  IngestService({
    required this.bridge,
    required this.repo,
    required this.lang,
    this.localLlm,
    this.useAi = false,
    this.onChanged,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final NativeBridge bridge;
  final Repository repo;
  final Lang lang;

  /// Returns the on-device model if (and only if) it is already available. Null in the worker.
  final Future<LlmBackend?> Function()? localLlm;
  final bool useAi;
  final void Function()? onChanged;
  final DateTime Function() _now;

  final _urgent = StreamController<StoredEvent>.broadcast();
  StreamSubscription<RawNotification>? _sub;
  final _refineQueue = <int>[];
  var _refining = false;

  /// Urgent items from important apps (drives the Drum/Shutter alert or the urgent notification).
  Stream<StoredEvent> get urgent => _urgent.stream;

  Future<void> start() async {
    await drainQueue();
    _sub ??= bridge.notifications().listen((n) => handle(n));
    await repo.purge(now: _now());
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  /// Notifications that arrived while the app was closed. Never emits urgent alerts (they are old).
  Future<int> drainQueue() async {
    final items = await bridge.drainQueue();
    for (final n in items) {
      await handle(n, live: false);
    }
    return items.length;
  }

  Future<StoredEvent?> handle(RawNotification n, {bool live = true}) async {
    final important = await repo.importantPkgs();
    final knowledge = await repo.knowledge();
    final rules = RulesClassifier(knowledge: knowledge, lang: lang);
    final c = rules.classifySync(n, _now());
    final id = await repo.ingest(n, c, importantApps: important);
    if (id == null) {
      return null;
    }
    onChanged?.call();
    final stored = StoredEvent(
      id: id,
      key: n.key,
      pkg: n.pkg,
      appName: n.appName,
      sender: n.title,
      text: n.text,
      postedAt: n.postedAt,
      classification: c,
    );
    final isImportantApp = important.contains(n.pkg);
    if (live && isImportantApp && c.priority == Priority.urgent) {
      _urgent.add(stored);
    } else if (isImportantApp &&
        useAi &&
        localLlm != null &&
        const Refiner().isUncertain(c)) {
      _refineQueue.add(id);
      unawaited(_drainRefine(live: live));
    }
    return stored;
  }

  /// One at a time: on-device inference is slow on cheap phones.
  Future<void> _drainRefine({required bool live}) async {
    if (_refining) {
      return;
    }
    _refining = true;
    try {
      while (_refineQueue.isNotEmpty) {
        final id = _refineQueue.removeAt(0);
        final llm = await localLlm?.call();
        if (llm == null) {
          continue;
        }
        final e = await repo.byId(id);
        if (e == null) {
          continue;
        }
        final raw = RawNotification(
          key: e.key,
          pkg: e.pkg,
          appName: e.appName,
          title: e.sender,
          text: e.text,
          postedAt: e.postedAt,
        );
        final better = await Refiner(lang: lang)
            .refine(raw, e.classification, llm, alreadyJudgedUncertain: true);
        if (better == null) {
          continue;
        }
        await repo.updateClassification(id, better);
        onChanged?.call();
        if (live && better.priority == Priority.urgent) {
          final updated = await repo.byId(id);
          if (updated != null) {
            _urgent.add(updated);
          }
        }
      }
    } finally {
      _refining = false;
    }
  }

  /// Waits for queued refinement (tests).
  Future<void> idle() async {
    while (_refining || _refineQueue.isNotEmpty) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Future<void> dispose() async {
    await stop();
    await _urgent.close();
  }
}
