import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/types.dart';
import '../data/repository.dart';

class DeviceSpecs {
  const DeviceSpecs({
    required this.totalRamMb,
    required this.availRamMb,
    required this.freeStorageMb,
    required this.cores,
    required this.abis,
    required this.sdk,
    required this.lowRam,
    required this.soc,
    required this.model,
  });
  final int totalRamMb;
  final int availRamMb;
  final int freeStorageMb;
  final int cores;
  final List<String> abis;
  final int sdk;
  final bool lowRam;
  final String soc;
  final String model;

  bool get isArm64 => abis.contains('arm64-v8a');
  double get totalRamGb => totalRamMb / 1024;

  factory DeviceSpecs.fromMap(Map<dynamic, dynamic> m) => DeviceSpecs(
    totalRamMb: (m['totalRamMb'] as num).toInt(),
    availRamMb: (m['availRamMb'] as num).toInt(),
    freeStorageMb: (m['freeStorageMb'] as num).toInt(),
    cores: (m['cores'] as num).toInt(),
    abis: [for (final a in (m['abis'] as List)) a.toString()],
    sdk: (m['sdk'] as num).toInt(),
    lowRam: m['lowRam'] as bool? ?? false,
    soc: m['soc']?.toString() ?? '',
    model: m['model']?.toString() ?? '',
  );
}

RawNotification decodeNotification(String jsonLine) {
  final m = jsonDecode(jsonLine) as Map<String, dynamic>;
  return RawNotification(
    key: m['key'] as String,
    pkg: m['pkg'] as String,
    appName: m['appName'] as String? ?? m['pkg'] as String,
    title: m['title'] as String? ?? '',
    text: m['text'] as String? ?? '',
    postedAt: DateTime.fromMillisecondsSinceEpoch(
      (m['postedAt'] as num).toInt(),
    ),
    isMessaging: m['messaging'] as bool? ?? false,
    hasContentIntent: m['hasContentIntent'] as bool? ?? false,
    sensitiveHint: m['sensitive'] as String?,
  );
}

/// Everything Dart needs from Android. Implemented by the Kotlin plugin; a fake
/// is used in tests and on non-Android hosts.
abstract class NativeBridge {
  Future<bool> isAccessGranted();
  Future<bool> openAccessSettings();
  Future<bool> openAppSettings();
  Future<bool> openBatterySettings();
  Future<bool> requestRebind();
  Future<bool> isListenerConnected();
  Stream<RawNotification> notifications();
  Future<List<RawNotification>> drainQueue();
  Future<List<AppRef>> installedApps();
  Future<Uint8List?> appIcon(String pkg);

  /// Fires the source notification's contentIntent; falls back to launching the app.
  /// Returns "intent", "launch" or "failed".
  Future<String> fire(String key, String pkg);
  Future<bool> launchApp(String pkg);
  Future<DeviceSpecs?> deviceSpecs();
  Future<bool> composeEmail({
    String to = '',
    required String subject,
    required String body,
  });
}

class AndroidNativeBridge implements NativeBridge {
  static const _m = MethodChannel('dholu/native');
  static const _e = EventChannel('dholu/notifications');

  Future<T?> _call<T>(String name, [Map<String, dynamic>? args]) async {
    try {
      return await _m.invokeMethod<T>(name, args);
    } on PlatformException catch (e) {
      debugPrint('native $name failed: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<bool> isAccessGranted() async =>
      await _call<bool>('isAccessGranted') ?? false;
  @override
  Future<bool> openAccessSettings() async =>
      await _call<bool>('openAccessSettings') ?? false;
  @override
  Future<bool> openAppSettings() async =>
      await _call<bool>('openAppSettings') ?? false;
  @override
  Future<bool> openBatterySettings() async =>
      await _call<bool>('openBatterySettings') ?? false;
  @override
  Future<bool> requestRebind() async =>
      await _call<bool>('requestRebind') ?? false;
  @override
  Future<bool> isListenerConnected() async =>
      await _call<bool>('isListenerConnected') ?? false;

  @override
  Stream<RawNotification> notifications() =>
      _e.receiveBroadcastStream().map((e) => decodeNotification(e as String));

  @override
  Future<List<RawNotification>> drainQueue() async {
    final lines = await _call<List<dynamic>>('drainQueue') ?? const [];
    return [
      for (final l in lines)
        if (l is String) decodeNotification(l),
    ];
  }

  @override
  Future<List<AppRef>> installedApps() async {
    final list = await _call<List<dynamic>>('getInstalledApps') ?? const [];
    return [
      for (final a in list)
        AppRef((a as Map)['pkg'] as String, a['name'] as String),
    ];
  }

  @override
  Future<Uint8List?> appIcon(String pkg) =>
      _call<Uint8List>('getAppIcon', {'pkg': pkg});

  @override
  Future<String> fire(String key, String pkg) async =>
      await _call<String>('fire', {'key': key, 'pkg': pkg}) ?? 'failed';
  @override
  Future<bool> launchApp(String pkg) async =>
      await _call<bool>('launchApp', {'pkg': pkg}) ?? false;

  @override
  Future<DeviceSpecs?> deviceSpecs() async {
    final m = await _call<Map<dynamic, dynamic>>('getDeviceSpecs');
    return m == null ? null : DeviceSpecs.fromMap(m);
  }

  @override
  Future<bool> composeEmail({
    String to = '',
    required String subject,
    required String body,
  }) async =>
      await _call<bool>('composeEmail', {
        'to': to,
        'subject': subject,
        'body': body,
      }) ??
      false;
}

/// In-memory bridge for tests, desktop and web previews.
class FakeNativeBridge implements NativeBridge {
  FakeNativeBridge({this.granted = true, this.specs, this.apps = const []});
  bool granted;
  DeviceSpecs? specs;
  List<AppRef> apps;
  final _ctrl = StreamController<RawNotification>.broadcast();
  final List<RawNotification> queue = [];
  final List<String> fired = [];
  final List<({String to, String subject, String body})> emails = [];

  void emit(RawNotification n) => _ctrl.add(n);

  @override
  Future<bool> isAccessGranted() async => granted;
  @override
  Future<bool> openAccessSettings() async => true;
  @override
  Future<bool> openAppSettings() async => true;
  @override
  Future<bool> openBatterySettings() async => true;
  @override
  Future<bool> requestRebind() async => true;
  @override
  Future<bool> isListenerConnected() async => granted;
  @override
  Stream<RawNotification> notifications() => _ctrl.stream;
  @override
  Future<List<RawNotification>> drainQueue() async {
    final out = List<RawNotification>.from(queue);
    queue.clear();
    return out;
  }

  @override
  Future<List<AppRef>> installedApps() async => apps;
  @override
  Future<Uint8List?> appIcon(String pkg) async => null;
  @override
  Future<String> fire(String key, String pkg) async {
    fired.add(key);
    return 'intent';
  }

  @override
  Future<bool> launchApp(String pkg) async => true;
  @override
  Future<DeviceSpecs?> deviceSpecs() async => specs;
  @override
  Future<bool> composeEmail({
    String to = '',
    required String subject,
    required String body,
  }) async {
    emails.add((to: to, subject: subject, body: body));
    return true;
  }
}

final nativeBridgeProvider = Provider<NativeBridge>(
  (_) => defaultTargetPlatform == TargetPlatform.android && !kIsWeb
      ? AndroidNativeBridge()
      : FakeNativeBridge(),
);
