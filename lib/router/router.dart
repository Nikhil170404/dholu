import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../ui/choose_apps_screen.dart';
import '../ui/home_screen.dart';
import '../ui/loaders.dart';
import '../ui/previews.dart';
import '../ui/splash_screen.dart';
import '../ui/tips_screen.dart';
import '../ui/widgets.dart';

final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/tips', builder: (_, _) => const TipsScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/apps', builder: (_, _) => const ChooseAppsScreen()),
    GoRoute(path: '/loaders', builder: (_, _) => const LoadersScreen()),
    GoRoute(path: '/mascot', builder: (_, _) => const MascotPreview()),
    GoRoute(path: '/shutter', builder: (_, _) => const ShutterPreview()),
    GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),
  ],
);

/// Dev-only index of every M1 screen.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});
  static const _items = [
    ('1  Loading', '/'),
    ('2  Quick tips', '/tips'),
    ('6  Home', '/home'),
    ('7  Choose apps', '/apps'),
    ('9  Meet Dholu', '/mascot'),
    ('12  Shutter alert', '/shutter'),
    ('13  Loaders', '/loaders'),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Dholu gallery'), backgroundColor: DColors.ground, surfaceTintColor: Colors.transparent),
        body: ListView(padding: const EdgeInsets.all(DSpace.screen), children: [
          DCard(
            child: Column(children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const Divider(),
                ListTile(
                  minTileHeight: DSpace.minTouch + 8,
                  title: Text(_items[i].$1, style: DText.bodyStrong),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(_items[i].$2),
                ),
              ],
            ]),
          ),
        ]),
      );
}
