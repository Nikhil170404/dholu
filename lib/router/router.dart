import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../ui/all_screen.dart';
import '../ui/assistant_screen.dart';
import '../ui/choose_apps_screen.dart';
import '../ui/data_screen.dart';
import '../ui/done_screen.dart';
import '../ui/draft_screen.dart';
import '../ui/drum_alert_screen.dart';
import '../ui/email_screen.dart';
import '../ui/home_screen.dart';
import '../ui/loaders.dart';
import '../ui/models_screen.dart';
import '../ui/previews.dart';
import '../ui/settings_screen.dart';
import '../ui/splash_screen.dart';
import '../ui/summary_sheet.dart';
import '../ui/tips_screen.dart';
import '../ui/widgets.dart';

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/tips', builder: (_, _) => const TipsScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/talk', builder: (_, _) => const AssistantScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/settings/models', builder: (_, _) => const ModelsScreen()),
    GoRoute(
      path: '/apps',
      builder: (_, st) =>
          ChooseAppsScreen(first: st.uri.queryParameters['first'] == '1'),
    ),
    GoRoute(path: '/all', builder: (_, _) => const AllScreen()),
    GoRoute(path: '/data', builder: (_, _) => const DataScreen()),
    GoRoute(path: '/email', builder: (_, _) => const EmailScreen()),
    GoRoute(
      path: '/draft/:id',
      builder: (_, st) =>
          DraftScreen(eventId: int.parse(st.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/alert/:id',
      builder: (_, st) =>
          DrumAlertScreen(eventId: int.parse(st.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/done',
      builder: (_, st) => DoneScreen(next: st.uri.queryParameters['to']),
    ),
    GoRoute(
      path: '/summary',
      pageBuilder: (_, st) => CustomTransitionPage<void>(
        key: st.pageKey,
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        barrierLabel: 'close',
        transitionsBuilder: (_, a, _, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(a),
          child: child,
        ),
        child: const SummarySheet(),
      ),
    ),
    if (kDebugMode) ...[
      GoRoute(path: '/gallery', builder: (_, _) => const GalleryScreen()),
      GoRoute(path: '/loaders', builder: (_, _) => const LoadersScreen()),
      GoRoute(path: '/mascot', builder: (_, _) => const MascotPreview()),
      GoRoute(path: '/shutter', builder: (_, _) => const ShutterPreview()),
    ],
  ],
);

/// Dev-only index of screens (debug builds).
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
    appBar: AppBar(
      title: const Text('Dholu gallery'),
      backgroundColor: DColors.ground,
      surfaceTintColor: Colors.transparent,
    ),
    body: ListView(
      padding: const EdgeInsets.all(DSpace.screen),
      children: [
        DCard(
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const Divider(),
                ListTile(
                  minTileHeight: DSpace.minTouch + 8,
                  title: Text(_items[i].$1, style: DText.bodyStrong),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(_items[i].$2),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
