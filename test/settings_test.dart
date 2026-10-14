import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dholu/core/types.dart';
import 'package:dholu/settings/settings.dart';

void main() {
  test('defaults are private and offline-first', () {
    const s = Settings();
    expect(s.lockScreenDetail, isFalse);
    expect(s.webSearch, isFalse);
    expect(s.cloudEnabled, isFalse);
    expect(s.wifiOnlyDownloads, isTrue);
    expect(s.lang, Lang.hinglish);
  });

  test('settings persist and reload', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [prefsProvider.overrideWithValue(p)],
    );
    await c
        .read(settingsProvider.notifier)
        .update(
          (s) => s.copyWith(
            lang: Lang.english,
            webSearch: true,
            modelId: 'gemma3-1b',
            summaryHour: 7,
            searchProvider: SearchProvider.brave,
          ),
        );
    final reloaded = Settings.load(p);
    expect(reloaded.lang, Lang.english);
    expect(reloaded.webSearch, isTrue);
    expect(reloaded.modelId, 'gemma3-1b');
    expect(reloaded.summaryHour, 7);
    expect(reloaded.searchProvider, SearchProvider.brave);
    await c
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(modelId: null));
    expect(Settings.load(p).modelId, isNull);
  });
}
