import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../native/native_bridge.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';

final appIconProvider = FutureProvider.family<Uint8List?, String>(
  (ref, pkg) => ref.watch(nativeBridgeProvider).appIcon(pkg),
);

/// App launcher icon (lazy, cached) with a letter tile fallback.
class AppIcon extends ConsumerWidget {
  const AppIcon({
    super.key,
    required this.pkg,
    required this.name,
    this.size = 40,
  });
  final String pkg;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = ref.watch(appIconProvider(pkg)).asData?.value;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(DRadius.tile),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          gaplessPlayback: true,
          cacheWidth: (size * 3).round(),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DColors.iconTile,
        borderRadius: BorderRadius.circular(DRadius.tile),
      ),
      child: Text(
        name.isEmpty ? '?' : name.characters.first.toUpperCase(),
        style: DText.bodyStrong.copyWith(fontSize: size * 0.42),
      ),
    );
  }
}
