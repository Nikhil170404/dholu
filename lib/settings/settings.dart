import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/types.dart';

enum SearchProvider { duckduckgo, brave, searxng }

/// User-facing settings (brief section 5 + the v2 AI/search options).
/// Everything that talks to the internet is OFF by default.
class Settings {
  const Settings({
    this.lang = Lang.hinglish,
    this.drumSound = true,
    this.lockScreenDetail = false,
    this.summaryHour = 8,
    this.summaryMinute = 0,
    this.summaryEnabled = true,
    this.onboarded = false,
    this.wifiOnlyDownloads = true,
    this.modelId,
    this.useAiClassifier = true,
    this.webSearch = false,
    this.searchProvider = SearchProvider.duckduckgo,
    this.searxngUrl = '',
    this.cloudEnabled = false,
    this.cloudBaseUrl = 'https://api.openai.com/v1',
    this.cloudModel = 'gpt-4o-mini',
  });

  final Lang lang;

  /// "Dhol ki awaaz".
  final bool drumSound;

  /// "Lock screen par detail dikhao" (off by default: lock screen stays private).
  final bool lockScreenDetail;
  final int summaryHour;
  final int summaryMinute;
  final bool summaryEnabled;
  final bool onboarded;
  final bool wifiOnlyDownloads;

  /// Chosen on-device model (ModelCatalog id), null = rules only.
  final String? modelId;

  /// Use the model to classify what the rules are unsure about.
  final bool useAiClassifier;
  final bool webSearch;
  final SearchProvider searchProvider;
  final String searxngUrl;

  /// Optional BYOK cloud model. Keys live in the secure store, never here.
  final bool cloudEnabled;
  final String cloudBaseUrl;
  final String cloudModel;

  Settings copyWith({
    Lang? lang,
    bool? drumSound,
    bool? lockScreenDetail,
    int? summaryHour,
    int? summaryMinute,
    bool? summaryEnabled,
    bool? onboarded,
    bool? wifiOnlyDownloads,
    Object? modelId = _keep,
    bool? useAiClassifier,
    bool? webSearch,
    SearchProvider? searchProvider,
    String? searxngUrl,
    bool? cloudEnabled,
    String? cloudBaseUrl,
    String? cloudModel,
  }) => Settings(
    lang: lang ?? this.lang,
    drumSound: drumSound ?? this.drumSound,
    lockScreenDetail: lockScreenDetail ?? this.lockScreenDetail,
    summaryHour: summaryHour ?? this.summaryHour,
    summaryMinute: summaryMinute ?? this.summaryMinute,
    summaryEnabled: summaryEnabled ?? this.summaryEnabled,
    onboarded: onboarded ?? this.onboarded,
    wifiOnlyDownloads: wifiOnlyDownloads ?? this.wifiOnlyDownloads,
    modelId: identical(modelId, _keep) ? this.modelId : modelId as String?,
    useAiClassifier: useAiClassifier ?? this.useAiClassifier,
    webSearch: webSearch ?? this.webSearch,
    searchProvider: searchProvider ?? this.searchProvider,
    searxngUrl: searxngUrl ?? this.searxngUrl,
    cloudEnabled: cloudEnabled ?? this.cloudEnabled,
    cloudBaseUrl: cloudBaseUrl ?? this.cloudBaseUrl,
    cloudModel: cloudModel ?? this.cloudModel,
  );

  static const _keep = Object();

  static Settings load(SharedPreferences p) => Settings(
    lang: p.getString('lang') == 'english' ? Lang.english : Lang.hinglish,
    drumSound: p.getBool('drumSound') ?? true,
    lockScreenDetail: p.getBool('lockScreenDetail') ?? false,
    summaryHour: p.getInt('summaryHour') ?? 8,
    summaryMinute: p.getInt('summaryMinute') ?? 0,
    summaryEnabled: p.getBool('summaryEnabled') ?? true,
    onboarded: p.getBool('onboarded') ?? false,
    wifiOnlyDownloads: p.getBool('wifiOnlyDownloads') ?? true,
    modelId: p.getString('modelId'),
    useAiClassifier: p.getBool('useAiClassifier') ?? true,
    webSearch: p.getBool('webSearch') ?? false,
    searchProvider:
        SearchProvider.values.asNameMap()[p.getString('searchProvider')] ??
        SearchProvider.duckduckgo,
    searxngUrl: p.getString('searxngUrl') ?? '',
    cloudEnabled: p.getBool('cloudEnabled') ?? false,
    cloudBaseUrl: p.getString('cloudBaseUrl') ?? 'https://api.openai.com/v1',
    cloudModel: p.getString('cloudModel') ?? 'gpt-4o-mini',
  );

  Future<void> save(SharedPreferences p) async {
    await p.setString('lang', lang.name);
    await p.setBool('drumSound', drumSound);
    await p.setBool('lockScreenDetail', lockScreenDetail);
    await p.setInt('summaryHour', summaryHour);
    await p.setInt('summaryMinute', summaryMinute);
    await p.setBool('summaryEnabled', summaryEnabled);
    await p.setBool('onboarded', onboarded);
    await p.setBool('wifiOnlyDownloads', wifiOnlyDownloads);
    if (modelId == null) {
      await p.remove('modelId');
    } else {
      await p.setString('modelId', modelId!);
    }
    await p.setBool('useAiClassifier', useAiClassifier);
    await p.setBool('webSearch', webSearch);
    await p.setString('searchProvider', searchProvider.name);
    await p.setString('searxngUrl', searxngUrl);
    await p.setBool('cloudEnabled', cloudEnabled);
    await p.setString('cloudBaseUrl', cloudBaseUrl);
    await p.setString('cloudModel', cloudModel);
  }
}

/// API keys. Backed by Android Keystore via flutter_secure_storage.
abstract class SecretStore {
  Future<String?> read(String name);
  Future<void> write(String name, String? value);
}

class KeystoreSecretStore implements SecretStore {
  const KeystoreSecretStore();
  static const _s = FlutterSecureStorage();
  @override
  Future<String?> read(String name) => _s.read(key: name);
  @override
  Future<void> write(String name, String? value) =>
      value == null || value.isEmpty
      ? _s.delete(key: name)
      : _s.write(key: name, value: value);
}

class MemorySecretStore implements SecretStore {
  final Map<String, String> _m = {};
  @override
  Future<String?> read(String name) async => _m[name];
  @override
  Future<void> write(String name, String? value) async =>
      value == null || value.isEmpty ? _m.remove(name) : _m[name] = value;
}

final prefsProvider = Provider<SharedPreferences>(
  (_) => throw UnimplementedError('override in main()'),
);
final secretStoreProvider = Provider<SecretStore>(
  (_) => const KeystoreSecretStore(),
);

class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => Settings.load(ref.watch(prefsProvider));

  Future<void> update(Settings Function(Settings s) f) async {
    state = f(state);
    await state.save(ref.read(prefsProvider));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
