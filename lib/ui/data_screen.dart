import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_providers.dart';
import '../data/repository.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'widgets.dart';

final _countsProvider = FutureProvider.autoDispose<Map<String, int>>((ref) {
  ref.watch(changeTickProvider);
  return ref.watch(repositoryProvider).countsByApp();
});

/// "What Dholu knows": view and delete stored data. Everything is on this phone only.
class DataScreen extends ConsumerWidget {
  const DataScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    final counts = ref.watch(_countsProvider).asData?.value ?? const {};
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    Future<void> deleteAll() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(tr('delete_all')),
          content: Text(tr('delete_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(tr('delete')),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref.read(repositoryProvider).wipeEvents();
        ref.read(changeTickProvider.notifier).bump();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(tr('deleted'))));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('data_title')),
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
          Text(tr('data_intro', {'n': total}), style: DText.body),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: DColors.success,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(tr('data_no_otp'), style: DText.caption)),
            ],
          ),
          const SizedBox(height: DSpace.section),
          if (counts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(tr('no_data'), style: DText.caption),
              ),
            )
          else
            DCard(
              child: Column(
                children: [
                  for (final (i, e)
                      in (counts.entries.toList()
                            ..sort((a, b) => b.value.compareTo(a.value)))
                          .indexed) ...[
                    if (i > 0) const Divider(),
                    ListTile(
                      title: Text(e.key, style: DText.bodyStrong),
                      trailing: Text('${e.value}', style: DText.bodyStrong),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: DSpace.section),
          DButton(
            label: tr('delete_all'),
            tint: true,
            icon: Icons.delete_outline_rounded,
            onPressed: total == 0 ? null : deleteAll,
          ),
        ],
      ),
    );
  }
}
