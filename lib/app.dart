import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_providers.dart';
import 'shell.dart';
import 'theme/theme.dart';

class DholuApp extends ConsumerWidget {
  const DholuApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Dholu',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) =>
        AppShell(child: child ?? const SizedBox.shrink()),
  );
}
