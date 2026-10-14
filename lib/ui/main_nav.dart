import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_providers.dart';
import '../theme/tokens.dart';

/// Bottom navigation shared by Home, Talk and Settings.
class MainNav extends ConsumerWidget {
  const MainNav({super.key, required this.index});
  final int index;

  static const _routes = ['/home', '/talk', '/settings'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(trProvider);
    return NavigationBar(
      selectedIndex: index,
      backgroundColor: DColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: DColors.accentTint,
      height: 68,
      onDestinationSelected: (i) {
        if (i != index) {
          context.go(_routes[i]);
        }
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.notifications_none_rounded),
          selectedIcon: const Icon(
            Icons.notifications_rounded,
            color: DColors.accentDark,
          ),
          label: tr('tab_home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(
            Icons.chat_bubble_rounded,
            color: DColors.accentDark,
          ),
          label: tr('tab_talk'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.settings_outlined),
          selectedIcon: const Icon(
            Icons.settings_rounded,
            color: DColors.accentDark,
          ),
          label: tr('tab_settings'),
        ),
      ],
    );
  }
}
