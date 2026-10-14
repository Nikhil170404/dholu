import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../mascot/dholu_widget.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

/// Screen 13 loaders.

/// Mini drumming Dholu + progress ("summary building").
class SummaryLoader extends StatelessWidget {
  const SummaryLoader({super.key, this.progress = 0.6});
  final double progress;
  @override
  Widget build(BuildContext context) => Row(children: [
        const Dholu(pose: DholuPose.drumRoll, size: 44),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Summary ban raha hai...', style: DText.bodyStrong),
            const SizedBox(height: 8),
            ProgressBar(value: progress),
          ]),
        ),
      ]);
}

class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 6});
  final double value;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: value,
          minHeight: height,
          backgroundColor: DColors.border,
          valueColor: const AlwaysStoppedAnimation(DColors.accent),
        ),
      );
}

/// Three bouncing dots ("reply draft writing").
class BouncingDots extends StatefulWidget {
  const BouncingDots({super.key, this.label = 'Draft likh raha hai'});
  final String label;
  @override
  State<BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<BouncingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, _) => Row(
            children: List.generate(3, (i) {
              final t = ((_c.value - i * 0.15) % 1.0);
              final y = t < 0.4 ? -6 * math.sin(math.pi * t / 0.4) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Transform.translate(
                  offset: Offset(0, y),
                  child: Container(width: 9, height: 9, decoration: const BoxDecoration(color: DColors.accent, shape: BoxShape.circle)),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 6),
        Text(widget.label, style: DText.caption),
      ]);
}

/// On-device model download: progress, "64% · 180 MB / 280 MB", Wi-Fi-only chip.
class ModelDownloadLoader extends StatelessWidget {
  const ModelDownloadLoader({super.key, this.progress = 0.64, this.totalMb = 280});
  final double progress;
  final int totalMb;
  @override
  Widget build(BuildContext context) {
    final done = (progress * totalMb).round();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const IconTile(Icons.download_rounded, size: 36, color: DColors.accentTint, iconColor: DColors.accentDark),
        const SizedBox(width: 12),
        const Expanded(child: Text('Dholu ka dimaag download ho raha hai', style: DText.bodyStrong)),
      ]),
      const SizedBox(height: 12),
      ProgressBar(value: progress),
      const SizedBox(height: 8),
      Row(children: [
        Text('${(progress * 100).round()}% · $done MB / $totalMb MB', style: DText.caption),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: DColors.accentTint, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_rounded, size: 14, color: DColors.accentDark),
            const SizedBox(width: 4),
            Text('Sirf Wi-Fi', style: DText.caption.copyWith(color: DColors.accentDark, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    ]);
  }
}

/// Skeleton shimmer rows.
class SkeletonRows extends StatefulWidget {
  const SkeletonRows({super.key, this.rows = 3});
  final int rows;
  @override
  State<SkeletonRows> createState() => _SkeletonRowsState();
}

class _SkeletonRowsState extends State<SkeletonRows> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final shimmer = LinearGradient(
            begin: Alignment(-1.5 + 3 * _c.value, 0),
            end: Alignment(-0.5 + 3 * _c.value, 0),
            colors: const [DColors.iconTile, Color(0xFFFFFFFF), DColors.iconTile],
          );
          Widget bar(double w, double h) => Container(
              width: w, height: h, decoration: BoxDecoration(gradient: shimmer, borderRadius: BorderRadius.circular(6)));
          return DCard(
            child: Column(
              children: [
                for (var i = 0; i < widget.rows; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(gradient: shimmer, borderRadius: BorderRadius.circular(DRadius.tile))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(160, 12), const SizedBox(height: 8), bar(90, 10)])),
                    ]),
                  ),
                ],
              ],
            ),
          );
        },
      );
}

/// Screen 13 as a page.
class LoadersScreen extends StatelessWidget {
  const LoadersScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Widget section(String t, Widget w) => Padding(
          padding: const EdgeInsets.only(bottom: DSpace.section),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t, style: DText.caption.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DCard(padding: const EdgeInsets.all(16), child: w),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Loaders'), backgroundColor: DColors.ground, surfaceTintColor: Colors.transparent),
      body: ListView(padding: const EdgeInsets.all(DSpace.screen), children: [
        section('SUMMARY BAN RAHA HAI', const SummaryLoader()),
        section('DRAFT LIKH RAHA HAI', const BouncingDots()),
        section('MODEL DOWNLOAD', const ModelDownloadLoader()),
        const Text('LOADING', style: DText.caption),
        const SizedBox(height: 8),
        const SkeletonRows(),
      ]),
    );
  }
}
