import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../actions/actions.dart';
import '../app_providers.dart';
import '../core/digest.dart';
import '../core/types.dart';
import '../l10n/strings.dart';
import '../mascot/dholu_widget.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'item_actions.dart';
import 'widgets.dart';

/// Screen 10: Drum alert. Dark scrim, the message, "Sahi kaam chuno" with 3 choices, and
/// Dholu popping in from the corner with a drum roll. Foreground only; no overlay permission.
class DrumAlertScreen extends ConsumerStatefulWidget {
  const DrumAlertScreen({super.key, required this.eventId});
  final int eventId;
  @override
  ConsumerState<DrumAlertScreen> createState() => _DrumAlertScreenState();
}

class _DrumAlertScreenState extends ConsumerState<DrumAlertScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();
  // 0.85 -> 1.04 -> 1, entering from the bottom-right.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.85,
        end: 1.04,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 70,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 30),
  ]).animate(_pop);

  @override
  void initState() {
    super.initState();
    if (ref.read(settingsProvider).drumSound) {
      ref.read(drumPlayerProvider).play();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  Future<void> _primary(StoredEvent e) async {
    final actions = ref.read(actionsProvider);
    await actions.feedback(e, 'opened');
    if (!mounted) {
      return;
    }
    if (e.classification.action == NotifAction.reply) {
      context.go('/done?to=${Uri.encodeComponent('/draft/${e.id}')}');
    } else {
      await actions.openSource(e.key, e.pkg, eventIds: [e.id]);
      if (mounted) {
        context.go('/done');
      }
    }
  }

  Future<void> _later(StoredEvent e) async {
    final tr = ref.read(trProvider);
    await ref.read(schedulerProvider).remindIn(e.id);
    await ref.read(actionsProvider).feedback(e, 'later');
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr('reminder_set'))));
    context.go('/home');
  }

  Future<void> _skip(StoredEvent e) async {
    await ref.read(actionsProvider).feedback(e, 'dismissed');
    if (mounted) {
      context.canPop() ? context.pop() : context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final e = ref.watch(eventProvider(widget.eventId)).asData?.value;
    return Scaffold(
      backgroundColor: DColors.ink,
      body: SafeArea(
        child: e == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(DSpace.screen),
                    children: [
                      const SizedBox(height: 8),
                      _MessageCard(e: e, tr: tr),
                      const SizedBox(height: 28),
                      Text(
                        tr('choose_right'),
                        style: DText.heading.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      _Choice(
                        icon: actionIcon(e.classification.action),
                        label: actionLabel(tr, e.classification.action),
                        tag: tr('dholu_pick'),
                        primary: true,
                        onTap: () => _primary(e),
                      ),
                      const SizedBox(height: 10),
                      _Choice(
                        icon: Icons.alarm_rounded,
                        label: tr('remind10'),
                        onTap: () => _later(e),
                      ),
                      const SizedBox(height: 10),
                      _Choice(
                        icon: Icons.close_rounded,
                        label: tr('skip'),
                        onTap: () => _skip(e),
                      ),
                      const SizedBox(height: 180),
                    ],
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: AnimatedBuilder(
                      animation: _pop,
                      builder: (context, child) => Opacity(
                        opacity: _pop.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(
                            40 * (1 - _pop.value),
                            40 * (1 - _pop.value),
                          ),
                          child: Transform.scale(
                            scale: _scale.value,
                            alignment: Alignment.bottomRight,
                            child: child,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: DColors.drum,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tr('drumroll'),
                              style: DText.caption.copyWith(
                                color: DColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Dholu(pose: DholuPose.drumRoll, size: 120),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.e, required this.tr});
  final StoredEvent e;
  final Tr tr;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(DRadius.feature),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const UrgentDot(),
            const SizedBox(width: 8),
            Text(
              '${tr('urgent_tag')}  ·  ${e.appName}',
              style: DText.caption.copyWith(
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(e.sender, style: DText.heading),
        const SizedBox(height: 4),
        Text(
          e.text.isEmpty ? e.classification.summary : e.text,
          style: DText.body,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tag,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final String? tag;
  final bool primary;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: primary ? DColors.accent : const Color(0xFF1B2540),
    borderRadius: BorderRadius.circular(DRadius.card),
    child: InkWell(
      borderRadius: BorderRadius.circular(DRadius.card),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: DText.bodyStrong.copyWith(color: Colors.white),
                ),
              ),
              if (tag != null)
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
                    tag!,
                    style: DText.caption.copyWith(
                      color: DColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
