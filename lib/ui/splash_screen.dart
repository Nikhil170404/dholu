import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_providers.dart';
import '../mascot/dholu_widget.dart';
import '../settings/settings.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'loaders.dart';

/// Screen 1: Loading. Drumming Dholu, app name, progress bar, 3 steps (last spins).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, this.autoAdvance = true});
  final bool autoAdvance;
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
    if (widget.autoAdvance) {
      _c.addStatusListener((s) {
        if (s == AnimationStatus.completed && mounted) {
          context.go(ref.read(settingsProvider).onboarded ? '/home' : '/tips');
        }
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(trProvider);
    final steps = [tr('step1'), tr('step2'), tr('step3')];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DSpace.screen),
          child: Column(
            children: [
              const Spacer(flex: 3),
              const Dholu(pose: DholuPose.drumRoll, size: 150),
              const SizedBox(height: 20),
              const Text('Dholu', style: DText.title),
              const SizedBox(height: 6),
              Text(tr('splash_sub'), style: DText.caption),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Column(
                  children: [
                    ProgressBar(value: _c.value),
                    const SizedBox(height: 24),
                    for (var i = 0; i < steps.length; i++)
                      _Step(label: steps[i], state: _stateFor(i)),
                  ],
                ),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }

  _StepState _stateFor(int i) {
    final v = _c.value;
    if (i == 2) {
      if (v >= 1) {
        return _StepState.done;
      }
      return v >= 2 / 3 ? _StepState.running : _StepState.waiting;
    }
    if (v >= (i + 1) / 3) {
      return _StepState.done;
    }
    return v >= i / 3 ? _StepState.running : _StepState.waiting;
  }
}

enum _StepState { waiting, running, done }

class _Step extends StatelessWidget {
  const _Step({required this.label, required this.state});
  final String label;
  final _StepState state;
  @override
  Widget build(BuildContext context) {
    final Widget lead = switch (state) {
      _StepState.done => const Icon(
        Icons.check_circle_rounded,
        color: DColors.success,
        size: 22,
      ),
      _StepState.running => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: DColors.accent,
        ),
      ),
      _StepState.waiting => const Icon(
        Icons.circle_outlined,
        color: DColors.border,
        size: 22,
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 24, child: Center(child: lead)),
          const SizedBox(width: 12),
          Text(
            label,
            style: DText.body.copyWith(
              color: state == _StepState.waiting
                  ? DColors.textSecondary
                  : DColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
