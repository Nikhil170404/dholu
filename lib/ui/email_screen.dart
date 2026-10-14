import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ai/llm_controller.dart';
import '../app_providers.dart';
import '../assistant/assistant.dart';
import '../core/digest.dart';
import '../data/repository.dart';
import '../native/native_bridge.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'loaders.dart';
import 'widgets.dart';

final _sendersProvider = FutureProvider.autoDispose<List<String>>(
  (ref) => ref.watch(repositoryProvider).recentSenders(),
);

/// Email drafting with context from the user's own stored messages. Opens the email app with a
/// prefilled draft; sending is always the user's action.
class EmailScreen extends ConsumerStatefulWidget {
  const EmailScreen({super.key});
  @override
  ConsumerState<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends ConsumerState<EmailScreen> {
  final _to = TextEditingController();
  final _say = TextEditingController();
  final _subject = TextEditingController();
  final _body = TextEditingController();
  String? _sender;
  bool _useContext = false;
  Tone _tone = Tone.normal;
  bool _busy = false;
  bool _generated = false;
  String? _error;
  bool _consent = false;

  @override
  void dispose() {
    for (final c in [_to, _say, _subject, _body]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    final tr = ref.read(trProvider);
    if (_say.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final llm = await ref.read(llmControllerProvider.notifier).forChat();
    if (!mounted) {
      return;
    }
    if (llm == null) {
      setState(() {
        _busy = false;
        _error = tr('need_model');
      });
      return;
    }
    try {
      final ctx = _useContext && _sender != null
          ? await ref.read(repositoryProvider).forSender(_sender!, limit: 8)
          : <StoredEvent>[];
      final d = await ref
          .read(assistantProvider)
          .draftEmail(
            llm,
            instruction: _say.text.trim(),
            recipientName: _to.text.trim(),
            context: ctx,
            tone: _tone,
            cloudConsent: _consent,
          );
      if (mounted) {
        _subject.text = d.subject;
        _body.text = d.body;
        setState(() {
          _busy = false;
          _generated = true;
        });
      }
    } on ConsentRequired {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      final ok = await showDialog<bool>(
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
      if (ok == true) {
        _consent = true;
        await _generate();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _openMail() async {
    final to = _to.text.contains('@') ? _to.text.trim() : '';
    await ref
        .read(nativeBridgeProvider)
        .composeEmail(to: to, subject: _subject.text, body: _body.text);
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final senders = ref.watch(_sendersProvider).asData?.value ?? const [];
    final llm = ref.watch(llmControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('email_title')),
        backgroundColor: DColors.ground,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/talk'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DSpace.screen),
        children: [
          TextField(
            controller: _to,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: tr('email_to'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _say,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: tr('email_say'),
              hintText: tr('email_say_hint'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr('use_context'), style: DText.bodyStrong),
            value: _useContext,
            onChanged: senders.isEmpty
                ? null
                : (v) => setState(() => _useContext = v),
          ),
          if (_useContext && senders.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _sender,
              decoration: InputDecoration(
                labelText: tr('context_from'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final s in senders)
                  DropdownMenuItem(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _sender = v),
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
                  onSelected: (_) =>
                      setState(() => _tone = _tone == t ? Tone.normal : t),
                  selectedColor: DColors.accentTint,
                ),
            ],
          ),
          const SizedBox(height: 16),
          DButton(
            label: tr('generate'),
            icon: Icons.auto_awesome_rounded,
            onPressed: _busy ? null : _generate,
          ),
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: BouncingDots(
                label: llm.phase == LlmPhase.loading
                    ? tr('model_loading')
                    : tr('drafting'),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: DText.caption.copyWith(color: DColors.urgent),
              ),
            ),
          if (_generated) ...[
            const SizedBox(height: DSpace.section),
            TextField(
              controller: _subject,
              decoration: InputDecoration(
                labelText: tr('subject'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              minLines: 6,
              maxLines: null,
              decoration: InputDecoration(
                labelText: tr('body'),
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(tr('mail_note'), style: DText.caption),
            const SizedBox(height: 12),
            DButton(
              label: tr('open_mail'),
              icon: Icons.open_in_new_rounded,
              onPressed: _openMail,
            ),
            const SizedBox(height: 8),
            DButton(
              label: tr('copy'),
              tint: true,
              icon: Icons.copy_rounded,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await ref.read(clipboardProvider)(
                  '${_subject.text}\n\n${_body.text}',
                );
                messenger.showSnackBar(SnackBar(content: Text(tr('copied'))));
              },
            ),
          ],
        ],
      ),
    );
  }
}
