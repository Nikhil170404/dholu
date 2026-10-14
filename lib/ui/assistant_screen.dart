import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ai/llm.dart';
import '../ai/llm_controller.dart';
import '../app_providers.dart';
import '../assistant/assistant.dart';
import '../assistant/web_search.dart';
import '../l10n/strings.dart';
import '../mascot/dholu_widget.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'loaders.dart';
import 'main_nav.dart';
import 'widgets.dart';

class _Msg {
  _Msg(this.fromUser, this.text);
  final bool fromUser;
  String text;
  List<SearchResult> sources = const [];
  String? searching;
}

/// Chat with Dholu: on-device model first, optional cloud, optional web search.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  StreamSubscription<AssistantEvent>? _sub;
  LlmBackend? _llm;
  bool _busy = false;
  bool _web = true;
  bool _noModel = false;
  Timer? _flush;

  @override
  void dispose() {
    _sub?.cancel();
    _flush?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) {
      return;
    }
    _input.clear();
    final llm = await ref.read(llmControllerProvider.notifier).forChat();
    if (!mounted) {
      return;
    }
    if (llm == null) {
      setState(() => _noModel = true);
      return;
    }
    _llm = llm;
    final history = [
      for (final m
          in _msgs
              .where((m) => m.text.isNotEmpty)
              .toList()
              .reversed
              .take(10)
              .toList()
              .reversed)
        m.fromUser ? ChatTurn.user(m.text) : ChatTurn.assistant(m.text),
    ];
    final reply = _Msg(false, '');
    setState(() {
      _noModel = false;
      _busy = true;
      _msgs
        ..add(_Msg(true, text))
        ..add(reply);
    });
    _scrollDown();
    final web = _web ? await ref.read(webSearchProvider.future) : null;
    final buf = StringBuffer();
    _sub = ref
        .read(assistantProvider)
        .chat(llm, history, text, web: web)
        .listen(
          (e) {
            switch (e) {
              case SearchStarted(:final query):
                reply.searching = query;
              case SearchDone(:final results):
                reply.sources = results;
                reply.searching = null;
              case SearchFailed():
                reply.searching = null;
              case Token(:final text):
                buf.write(text);
                reply.text = buf.toString();
            }
            _flush ??= Timer(const Duration(milliseconds: 60), () {
              _flush = null;
              if (mounted) {
                setState(() {});
                _scrollDown();
              }
            });
          },
          onError: (Object err) {
            reply.text = reply.text.isEmpty ? '$err' : '${reply.text}\n$err';
            if (mounted) {
              setState(() => _busy = false);
            }
          },
          onDone: () {
            if (mounted) {
              setState(() => _busy = false);
              _scrollDown();
            }
          },
        );
  }

  void _stop() {
    _llm?.cancel();
    _sub?.cancel();
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final s = ref.watch(settingsProvider);
    final status = ref.watch(llmControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('assistant_title')),
        backgroundColor: DColors.ground,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: tr('write_email'),
            onPressed: () => context.push('/email'),
            icon: const Icon(Icons.mail_outline_rounded),
          ),
          IconButton(
            tooltip: tr('new_chat'),
            onPressed: _busy ? null : () => setState(_msgs.clear),
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      bottomNavigationBar: const MainNav(index: 1),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(DSpace.screen),
              children: [
                if (_msgs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        const Dholu(size: 96),
                        const SizedBox(height: 16),
                        Text(
                          tr('assistant_intro'),
                          style: DText.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        DButton(
                          label: tr('write_email'),
                          tint: true,
                          expand: false,
                          icon: Icons.mail_outline_rounded,
                          onPressed: () => context.push('/email'),
                        ),
                      ],
                    ),
                  ),
                for (final m in _msgs) _Bubble(msg: m, tr: tr),
                if (_busy &&
                    _msgs.isNotEmpty &&
                    _msgs.last.text.isEmpty &&
                    _msgs.last.searching == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: BouncingDots(
                      label: status.phase == LlmPhase.loading
                          ? tr('model_loading')
                          : tr('thinking'),
                    ),
                  ),
                if (_noModel)
                  DCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.error ?? tr('need_model'),
                          style: DText.body,
                        ),
                        const SizedBox(height: 12),
                        DButton(
                          label: tr('go_settings'),
                          onPressed: () => context.push('/settings/models'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(
                color: DColors.card,
                border: Border(top: BorderSide(color: DColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (s.webSearch)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        avatar: const Icon(Icons.public_rounded, size: 16),
                        label: Text(tr('web_chip')),
                        selected: _web,
                        onSelected: (v) => setState(() => _web = v),
                        selectedColor: DColors.accentTint,
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: tr('ask_hint'),
                            filled: true,
                            fillColor: DColors.ground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: _busy ? tr('stop') : null,
                        style: IconButton.styleFrom(
                          backgroundColor: DColors.accent,
                          minimumSize: const Size(48, 48),
                        ),
                        onPressed: _busy ? _stop : _send,
                        icon: Icon(
                          _busy
                              ? Icons.stop_rounded
                              : Icons.arrow_upward_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.tr});
  final _Msg msg;
  final Tr tr;
  @override
  Widget build(BuildContext context) {
    final user = msg.fromUser;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        decoration: BoxDecoration(
          color: user ? DColors.accent : DColors.card,
          borderRadius: BorderRadius.circular(DRadius.card),
          border: user ? null : Border.all(color: DColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.searching != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      tr('searching', {'q': msg.searching!}),
                      style: DText.caption,
                    ),
                  ),
                ],
              ),
            if (msg.text.isNotEmpty)
              SelectableText(
                msg.text,
                style: DText.body.copyWith(
                  color: user ? Colors.white : DColors.ink,
                ),
              ),
            if (msg.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                tr('sources'),
                style: DText.caption.copyWith(fontWeight: FontWeight.w700),
              ),
              for (var i = 0; i < msg.sources.length; i++)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '[${i + 1}] ${msg.sources[i].title}',
                    style: DText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
