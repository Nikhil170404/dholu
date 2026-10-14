import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../actions/actions.dart';
import '../ai/llm_controller.dart';
import '../app_providers.dart';
import '../assistant/assistant.dart';
import '../core/digest.dart';
import '../data/repository.dart';
import '../l10n/strings.dart';
import '../mascot/dholu_widget.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'loaders.dart';
import 'widgets.dart';

/// Screen 5: Reply draft. The reply is only a draft: it is copied and the chat opens, so the user
/// pastes and sends. Dholu never sends anything.
class DraftScreen extends ConsumerStatefulWidget {
  const DraftScreen({super.key, required this.eventId});
  final int eventId;
  @override
  ConsumerState<DraftScreen> createState() => _DraftScreenState();
}

class _DraftScreenState extends ConsumerState<DraftScreen> {
  final _ctrl = TextEditingController();
  Tone _tone = Tone.normal;
  bool _busy = false;
  bool _noModel = false;
  String? _error;
  bool _cloudConsent = false;
  StoredEvent? _event;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final repo = ref.read(repositoryProvider);
    final e = await repo.byId(widget.eventId);
    if (e == null || !mounted) {
      return;
    }
    setState(() {
      _event = e;
      _busy = true;
      _error = null;
      _noModel = false;
    });
    final llm = await ref.read(llmControllerProvider.notifier).forChat();
    if (!mounted) {
      return;
    }
    if (llm == null) {
      setState(() {
        _busy = false;
        _noModel = true;
      });
      return;
    }
    try {
      final ctx = await repo.forSender(e.sender, limit: 8);
      final text = await ref
          .read(assistantProvider)
          .draftReply(
            llm,
            sender: e.sender,
            message: e.text.isEmpty ? e.classification.summary : e.text,
            context: ctx,
            tone: _tone,
            cloudConsent: _cloudConsent,
          );
      if (mounted) {
        _ctrl.text = text;
        setState(() => _busy = false);
      }
    } on ConsentRequired {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      final ok = await _askConsent();
      if (ok == true) {
        _cloudConsent = true;
        await _generate();
      }
    } on Object catch (err) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$err';
        });
      }
    }
  }

  Future<bool?> _askConsent() {
    final tr = ref.read(trProvider);
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('consent_title')),
        content: Text(tr('consent_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr('send_anyway')),
          ),
        ],
      ),
    );
  }

  void _setTone(Tone t) {
    setState(() => _tone = _tone == t ? Tone.normal : t);
    _generate();
  }

  Future<void> _open(StoredEvent e) async {
    final tr = ref.read(trProvider);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(clipboardProvider)(_ctrl.text);
    await ref
        .read(actionsProvider)
        .openSource(e.key, e.pkg, eventIds: [e.id], feedback: 'opened');
    messenger.showSnackBar(SnackBar(content: Text(tr('pasted'))));
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final e = _event;
    final llm = ref.watch(llmControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('draft_title')),
        backgroundColor: DColors.ground,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: e == null
          ? const Center(
              child: CircularProgressIndicator(color: DColors.accent),
            )
          : ListView(
              padding: const EdgeInsets.all(DSpace.screen),
              children: [
                Text(tr('their_msg', {'name': e.sender}), style: DText.caption),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: DColors.card,
                    borderRadius: BorderRadius.circular(DRadius.card),
                    border: Border.all(color: DColors.border),
                  ),
                  child: Text(
                    e.text.isEmpty ? e.classification.summary : e.text,
                    style: DText.body,
                  ),
                ),
                const SizedBox(height: DSpace.section),
                Row(
                  children: [
                    Dholu(
                      pose: _busy ? DholuPose.drumRoll : DholuPose.idle,
                      size: 36,
                      animate: _busy,
                    ),
                    const SizedBox(width: 10),
                    Text(tr('dholu_draft'), style: DText.bodyStrong),
                  ],
                ),
                const SizedBox(height: 10),
                if (_busy)
                  DCard(
                    padding: const EdgeInsets.all(16),
                    child: BouncingDots(
                      label: llm.phase == LlmPhase.loading
                          ? tr('model_loading')
                          : tr('drafting'),
                    ),
                  )
                else if (_noModel)
                  _NoModel(
                    tr: tr,
                    onPick: (t) => setState(() => _ctrl.text = t),
                    onSettings: () => context.push('/settings/models'),
                  )
                else ...[
                  TextField(
                    controller: _ctrl,
                    maxLines: null,
                    minLines: 3,
                    style: DText.body,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: DColors.accentTint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DRadius.card),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: DText.caption.copyWith(color: DColors.urgent),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final (t, k) in [
                        (Tone.short, 'tone_short'),
                        (Tone.formal, 'tone_formal'),
                        (Tone.english, 'tone_english'),
                      ])
                        ChoiceChip(
                          label: Text(tr(k)),
                          selected: _tone == t,
                          onSelected: (_) => _setTone(t),
                          selectedColor: DColors.accentTint,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: DColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(tr('send_note'), style: DText.caption),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DButton(
                  label: tr('open_in_app', {'app': e.appName}),
                  onPressed: _busy ? null : () => _open(e),
                ),
              ],
            ),
    );
  }
}

class _NoModel extends StatelessWidget {
  const _NoModel({
    required this.tr,
    required this.onPick,
    required this.onSettings,
  });
  final Tr tr;
  final void Function(String) onPick;
  final VoidCallback onSettings;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(tr('no_ai_hint'), style: DText.caption),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final k in ['qr1', 'qr2', 'qr3', 'qr4'])
            ActionChip(label: Text(tr(k)), onPressed: () => onPick(tr(k))),
        ],
      ),
      const SizedBox(height: 10),
      DButton(label: tr('go_settings'), tint: true, onPressed: onSettings),
    ],
  );
}
