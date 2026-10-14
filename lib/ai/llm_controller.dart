import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../native/native_bridge.dart';
import '../settings/settings.dart';
import 'cloud_llm.dart';
import 'llm.dart';
import 'local_llm.dart';
import 'model_catalog.dart';
import 'model_manager.dart';

enum LlmPhase { none, loading, ready, error }

class LlmStatus {
  const LlmStatus({this.phase = LlmPhase.none, this.label = '', this.error});
  final LlmPhase phase;
  final String label;
  final String? error;
}

typedef LocalLoader = Future<LlmBackend> Function(
  String path,
  ModelSpec spec,
  DeviceSpecs? device,
);

final localLoaderProvider = Provider<LocalLoader>(
  (_) =>
      (path, spec, device) => LocalLlm.load(path, spec, device: device),
);

/// Owns the single loaded on-device model: loads lazily, refuses to load when RAM is
/// too low, and unloads after a few idle minutes so Dholu stays light on cheap phones.
class LlmController extends Notifier<LlmStatus> {
  static const idleUnload = Duration(minutes: 3);

  LlmBackend? _local;
  ModelSpec? _loadedSpec;
  Future<LlmBackend?>? _loading;
  Timer? _idle;

  @override
  LlmStatus build() {
    ref.onDispose(() {
      _idle?.cancel();
      _local?.dispose();
    });
    return const LlmStatus();
  }

  ModelSpec? get _chosen =>
      ModelCatalog.byId(ref.read(settingsProvider).modelId);

  /// On-device backend, or null when no model is chosen/installed or RAM is too low.
  /// Notification classification uses ONLY this.
  Future<LlmBackend?> local() async {
    final spec = _chosen;
    if (spec == null) {
      return null;
    }
    if (_local != null && _loadedSpec?.id == spec.id) {
      _touch();
      return _local;
    }
    return _loading ??= _load(spec).whenComplete(() => _loading = null);
  }

  Future<LlmBackend?> _load(ModelSpec spec) async {
    await _unload();
    final path = await ref
        .read(modelManagerProvider.notifier)
        .installedPath(spec);
    if (path == null) {
      state = const LlmStatus(phase: LlmPhase.none);
      return null;
    }
    final device = await ref.read(nativeBridgeProvider).deviceSpecs();
    if (device != null) {
      final needMb = (spec.approxBytes / (1024 * 1024) * 1.1).round() + 250;
      if (device.availRamMb < needMb) {
        state = LlmStatus(
          phase: LlmPhase.error,
          error:
              'Not enough free RAM (${device.availRamMb} MB). Close some apps and try again.',
        );
        return null;
      }
    }
    state = LlmStatus(phase: LlmPhase.loading, label: spec.name);
    try {
      _local = await ref.read(localLoaderProvider)(path, spec, device);
      _loadedSpec = spec;
      state = LlmStatus(phase: LlmPhase.ready, label: _local!.label);
      _touch();
      return _local;
    } on Object catch (e) {
      state = LlmStatus(
        phase: LlmPhase.error,
        error: 'Could not start the model: $e',
      );
      return null;
    }
  }

  /// Best backend for a user-started chat / email: on-device first, then optional cloud.
  Future<LlmBackend?> forChat() async {
    final l = await local();
    if (l != null) {
      return l;
    }
    final s = ref.read(settingsProvider);
    if (!s.cloudEnabled) {
      return null;
    }
    final key = await ref.read(secretStoreProvider).read('cloud_api_key');
    if (key == null || key.isEmpty) {
      return null;
    }
    try {
      return CloudLlm(
        baseUrl: s.cloudBaseUrl,
        model: s.cloudModel,
        apiKey: key,
      );
    } on ArgumentError {
      return null;
    }
  }

  void _touch() {
    _idle?.cancel();
    _idle = Timer(idleUnload, () => unload());
  }

  Future<void> unload() => _unload();

  Future<void> _unload() async {
    _idle?.cancel();
    final l = _local;
    _local = null;
    _loadedSpec = null;
    if (l != null) {
      await l.dispose();
      state = const LlmStatus();
    }
  }
}

final llmControllerProvider = NotifierProvider<LlmController, LlmStatus>(
  LlmController.new,
);
