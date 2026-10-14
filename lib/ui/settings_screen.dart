import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ai/model_catalog.dart';
import '../app_providers.dart';
import '../core/types.dart';
import '../native/native_bridge.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'main_nav.dart';
import 'settings_widgets.dart';

/// All user settings (brief section 5 + AI/search options). Everything online is opt-in.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final access = ref.watch(accessGrantedProvider).asData?.value ?? false;
    final bridge = ref.read(nativeBridgeProvider);
    final model = ModelCatalog.byId(s.modelId);
    final time = TimeOfDay(
      hour: s.summaryHour,
      minute: s.summaryMinute,
    ).format(context);

    Future<void> saveSecret(String name, String v) async {
      await ref.read(secretStoreProvider).write(name, v);
      ref.invalidate(webSearchProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('saved'))));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings_title')),
        backgroundColor: DColors.ground,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: const MainNav(index: 2),
      body: ListView(
        padding: const EdgeInsets.all(DSpace.screen),
        children: [
          SettingsSection(tr('language'), [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SegmentedButton<Lang>(
                segments: [
                  ButtonSegment(
                    value: Lang.hinglish,
                    label: Text(tr('lang_hi')),
                  ),
                  ButtonSegment(
                    value: Lang.english,
                    label: Text(tr('lang_en')),
                  ),
                ],
                selected: {s.lang},
                onSelectionChanged: (v) =>
                    n.update((x) => x.copyWith(lang: v.first)),
              ),
            ),
          ]),
          SettingsSection(tr('sec_notif'), [
            SwitchRow(
              title: tr('summary_on'),
              value: s.summaryEnabled,
              onChanged: (v) => n.update((x) => x.copyWith(summaryEnabled: v)),
            ),
            NavRow(
              title: tr('summary_time'),
              trailing: Text(time, style: DText.bodyStrong),
              onTap: () async {
                final t = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(
                    hour: s.summaryHour,
                    minute: s.summaryMinute,
                  ),
                );
                if (t != null) {
                  await n.update(
                    (x) => x.copyWith(
                      summaryHour: t.hour,
                      summaryMinute: t.minute,
                    ),
                  );
                }
              },
            ),
            SwitchRow(
              title: tr('drum_sound'),
              subtitle: tr('drum_sound_sub'),
              value: s.drumSound,
              onChanged: (v) => n.update((x) => x.copyWith(drumSound: v)),
            ),
            SwitchRow(
              title: tr('lock_detail'),
              subtitle: tr('lock_detail_sub'),
              value: s.lockScreenDetail,
              onChanged: (v) =>
                  n.update((x) => x.copyWith(lockScreenDetail: v)),
            ),
          ]),
          SettingsSection(tr('sec_apps'), [
            NavRow(
              icon: Icons.apps_rounded,
              title: tr('choose_apps'),
              onTap: () => context.push('/apps'),
            ),
          ]),
          SettingsSection(tr('sec_ai'), [
            NavRow(
              icon: Icons.memory_rounded,
              title: model?.name ?? tr('rules_only'),
              subtitle: model == null ? tr('rules_only_sub') : model.sizeLabel,
              onTap: () => context.push('/settings/models'),
            ),
            SwitchRow(
              title: tr('ai_classify'),
              subtitle: tr('ai_classify_sub'),
              value: s.useAiClassifier,
              onChanged: (v) => n.update((x) => x.copyWith(useAiClassifier: v)),
            ),
          ]),
          SettingsSection(tr('sec_web'), [
            SwitchRow(
              title: tr('web_enable'),
              subtitle: tr('web_enable_sub'),
              value: s.webSearch,
              onChanged: (v) => n.update((x) => x.copyWith(webSearch: v)),
            ),
            if (s.webSearch) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: DropdownButtonFormField<SearchProvider>(
                  initialValue: s.searchProvider,
                  decoration: InputDecoration(
                    labelText: tr('provider'),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: SearchProvider.duckduckgo,
                      child: Text('DuckDuckGo'),
                    ),
                    DropdownMenuItem(
                      value: SearchProvider.brave,
                      child: Text('Brave Search API'),
                    ),
                    DropdownMenuItem(
                      value: SearchProvider.searxng,
                      child: Text('SearXNG'),
                    ),
                  ],
                  onChanged: (v) => v == null
                      ? null
                      : n.update((x) => x.copyWith(searchProvider: v)),
                ),
              ),
              if (s.searchProvider == SearchProvider.brave)
                _SecretField(
                  label: tr('brave_key'),
                  name: 'brave_api_key',
                  saveLabel: 'OK',
                  onSave: saveSecret,
                ),
              if (s.searchProvider == SearchProvider.searxng)
                SaveField(
                  label: tr('searx_url'),
                  initial: s.searxngUrl,
                  saveLabel: 'OK',
                  onSave: (v) => n.update((x) => x.copyWith(searxngUrl: v)),
                ),
            ],
          ]),
          SettingsSection(tr('sec_cloud'), [
            SwitchRow(
              title: tr('cloud_enable'),
              subtitle: tr('cloud_note'),
              value: s.cloudEnabled,
              onChanged: (v) => n.update((x) => x.copyWith(cloudEnabled: v)),
            ),
            if (s.cloudEnabled) ...[
              SaveField(
                label: tr('base_url'),
                initial: s.cloudBaseUrl,
                saveLabel: 'OK',
                onSave: (v) => n.update((x) => x.copyWith(cloudBaseUrl: v)),
              ),
              SaveField(
                label: tr('model_name'),
                initial: s.cloudModel,
                saveLabel: 'OK',
                onSave: (v) => n.update((x) => x.copyWith(cloudModel: v)),
              ),
              _SecretField(
                label: tr('api_key'),
                name: 'cloud_api_key',
                saveLabel: 'OK',
                onSave: saveSecret,
              ),
            ],
          ]),
          SettingsSection(tr('sec_privacy'), [
            NavRow(
              icon: Icons.shield_outlined,
              title: tr('what_knows'),
              onTap: () => context.push('/data'),
            ),
          ]),
          SettingsSection(tr('sec_perms'), [
            NavRow(
              icon: Icons.notifications_active_outlined,
              title: tr('access_status'),
              subtitle: access ? tr('on') : tr('off'),
              trailing: Text(
                tr('open'),
                style: DText.bodyStrong.copyWith(color: DColors.accent),
              ),
              onTap: () => bridge.openAccessSettings(),
            ),
            NavRow(
              icon: Icons.battery_saver_outlined,
              title: tr('battery'),
              subtitle: tr('battery_sub'),
              trailing: Text(
                tr('open'),
                style: DText.bodyStrong.copyWith(color: DColors.accent),
              ),
              onTap: () => bridge.openBatterySettings(),
            ),
          ]),
        ],
      ),
    );
  }
}

/// A secret field: shows nothing from the store, writes only on Save.
class _SecretField extends ConsumerWidget {
  const _SecretField({
    required this.label,
    required this.name,
    required this.saveLabel,
    required this.onSave,
  });
  final String label;
  final String name;
  final String saveLabel;
  final Future<void> Function(String name, String value) onSave;
  @override
  Widget build(BuildContext context, WidgetRef ref) => SaveField(
    label: label,
    initial: '',
    obscure: true,
    saveLabel: saveLabel,
    onSave: (v) => onSave(name, v),
  );
}
