import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ai/llm_controller.dart';
import '../ai/model_catalog.dart';
import '../ai/model_manager.dart';
import '../ai/recommender.dart';
import '../app_providers.dart';
import '../l10n/strings.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'settings_widgets.dart';
import 'widgets.dart';

/// Choose, download, pause, resume and delete the on-device model. Recommends a tier from
/// the phone's real RAM, storage and CPU.
class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});
  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(modelManagerProvider.notifier).refresh());
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final s = ref.watch(settingsProvider);
    final installs = ref.watch(modelManagerProvider);
    final rec = ref.watch(recommendationProvider).asData?.value;
    final specs = ref.watch(deviceSpecsProvider).asData?.value;
    final llm = ref.watch(llmControllerProvider);

    // First model that finishes becomes the active one, so a download "just works".
    ref.listen(modelManagerProvider, (prev, next) {
      for (final m in ModelCatalog.all) {
        if (prev?[m.id]?.status != InstallStatus.ready &&
            next[m.id]?.status == InstallStatus.ready &&
            ref.read(settingsProvider).modelId == null) {
          ref
              .read(settingsProvider.notifier)
              .update((x) => x.copyWith(modelId: m.id));
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('sec_ai')),
        backgroundColor: DColors.ground,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/settings'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DSpace.screen),
        children: [
          Text(tr('ai_intro'), style: DText.caption),
          const SizedBox(height: 16),
          if (specs != null)
            DCard(
              color: DColors.accentTint,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('for_phone'),
                    style: DText.caption.copyWith(
                      color: DColors.accentDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('phone_specs', {
                      'ram': specs.totalRamGb.toStringAsFixed(1),
                      'storage': (specs.freeStorageMb / 1024).toStringAsFixed(
                        1,
                      ),
                    }),
                    style: DText.bodyStrong,
                  ),
                  if (rec != null) ...[
                    const SizedBox(height: 4),
                    Text(rec.summary, style: DText.caption),
                  ],
                ],
              ),
            ),
          const SizedBox(height: DSpace.section),
          SettingsSection(tr('sec_ai'), [
            _RulesTile(
              tr: tr,
              selected: s.modelId == null,
              onTap: () => ref
                  .read(settingsProvider.notifier)
                  .update((x) => x.copyWith(modelId: null)),
            ),
            for (final m in ModelCatalog.all)
              _ModelTile(
                spec: m,
                fit: rec?.fits.where((f) => f.spec.id == m.id).firstOrNull,
                recommended: rec?.best?.spec.id == m.id,
                install: installs[m.id] ?? const ModelInstall(),
                active: s.modelId == m.id,
                loaded: s.modelId == m.id ? llm : null,
                tr: tr,
                freeStorageMb: specs?.freeStorageMb ?? 1 << 30,
              ),
          ]),
          SettingsSection('', [
            SwitchRow(
              title: tr('wifi_only'),
              value: s.wifiOnlyDownloads,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .update((x) => x.copyWith(wifiOnlyDownloads: v)),
            ),
            SwitchRow(
              title: tr('ai_classify'),
              subtitle: tr('ai_classify_sub'),
              value: s.useAiClassifier,
              onChanged: (v) => ref
                  .read(settingsProvider.notifier)
                  .update((x) => x.copyWith(useAiClassifier: v)),
            ),
          ]),
        ],
      ),
    );
  }
}

class _RulesTile extends StatelessWidget {
  const _RulesTile({
    required this.tr,
    required this.selected,
    required this.onTap,
  });
  final Tr tr;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    minTileHeight: 64,
    leading: Icon(
      selected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_off_rounded,
      color: selected ? DColors.accent : DColors.textSecondary,
    ),
    title: Text(tr('rules_only'), style: DText.bodyStrong),
    subtitle: Text(tr('rules_only_sub'), style: DText.caption),
    onTap: onTap,
  );
}

class _ModelTile extends ConsumerWidget {
  const _ModelTile({
    required this.spec,
    required this.fit,
    required this.recommended,
    required this.install,
    required this.active,
    required this.loaded,
    required this.tr,
    required this.freeStorageMb,
  });
  final ModelSpec spec;
  final ModelFit? fit;
  final bool recommended;
  final ModelInstall install;
  final bool active;
  final LlmStatus? loaded;
  final Tr tr;
  final int freeStorageMb;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mgr = ref.read(modelManagerProvider.notifier);
    final allowed = fit?.downloadable ?? true;
    Widget actions;
    switch (install.status) {
      case InstallStatus.none:
        actions = DButton(
          label: '${tr('download')}  ·  ${spec.sizeLabel}',
          expand: false,
          onPressed: allowed
              ? () => mgr.download(spec, freeStorageMb: freeStorageMb)
              : null,
        );
      case InstallStatus.downloading:
        actions = _Progress(
          value: install.progress,
          label: install.totalBytes == null
              ? '${(install.progress * 100).round()}%'
              : '${(install.progress * 100).round()}% · ${(install.progress * install.totalBytes! / 1048576).round()} MB / ${(install.totalBytes! / 1048576).round()} MB',
          buttons: [
            DButton(
              label: tr('pause'),
              tint: true,
              expand: false,
              onPressed: () => mgr.pause(spec.id),
            ),
            DButton(
              label: tr('cancel'),
              tint: true,
              expand: false,
              onPressed: () => mgr.cancel(spec.id),
            ),
          ],
        );
      case InstallStatus.paused:
        actions = _Progress(
          value: install.progress,
          label: '${(install.progress * 100).round()}%',
          buttons: [
            DButton(
              label: tr('resume'),
              expand: false,
              onPressed: () => mgr.resume(spec.id),
            ),
            DButton(
              label: tr('cancel'),
              tint: true,
              expand: false,
              onPressed: () => mgr.cancel(spec.id),
            ),
          ],
        );
      case InstallStatus.verifying:
        actions = Text(tr('verifying'), style: DText.caption);
      case InstallStatus.ready:
        actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            active
                ? Chip(
                    label: Text(tr('in_use')),
                    backgroundColor: DColors.accentTint,
                    avatar: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: DColors.accentDark,
                    ),
                  )
                : DButton(
                    label: tr('use_this'),
                    expand: false,
                    onPressed: () => ref
                        .read(settingsProvider.notifier)
                        .update((x) => x.copyWith(modelId: spec.id)),
                  ),
            DButton(
              label: tr('delete'),
              tint: true,
              expand: false,
              onPressed: () async {
                if (active) {
                  await ref
                      .read(settingsProvider.notifier)
                      .update((x) => x.copyWith(modelId: null));
                  await ref.read(llmControllerProvider.notifier).unload();
                }
                await mgr.delete(spec);
              },
            ),
          ],
        );
      case InstallStatus.failed:
        actions = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              install.error ?? tr('error_generic'),
              style: DText.caption.copyWith(color: DColors.urgent),
            ),
            const SizedBox(height: 8),
            DButton(
              label: tr('retry'),
              expand: false,
              onPressed: () => mgr.download(spec, freeStorageMb: freeStorageMb),
            ),
          ],
        );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(spec.name, style: DText.bodyStrong)),
              if (recommended)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: DColors.drum,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tr('dholu_pick'),
                    style: DText.caption.copyWith(
                      color: DColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(spec.blurb, style: DText.caption),
          const SizedBox(height: 4),
          Text(
            '${spec.sizeLabel}${spec.sizeVerified ? '' : ' (~)'} · ${fit?.reason ?? ''}',
            style: DText.caption.copyWith(
              color: allowed ? DColors.textSecondary : DColors.urgent,
            ),
          ),
          Text(spec.licenseNote, style: DText.caption.copyWith(fontSize: 11)),
          const SizedBox(height: 10),
          actions,
          if (loaded?.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                loaded!.error!,
                style: DText.caption.copyWith(color: DColors.urgent),
              ),
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.value,
    required this.label,
    required this.buttons,
  });
  final double value;
  final String label;
  final List<Widget> buttons;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: value == 0 ? null : value,
          minHeight: 6,
          backgroundColor: DColors.border,
          color: DColors.accent,
        ),
      ),
      const SizedBox(height: 6),
      Text(label, style: DText.caption),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: buttons),
    ],
  );
}
