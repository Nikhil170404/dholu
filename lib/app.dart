import 'package:flutter/material.dart';
import 'router/router.dart';
import 'theme/theme.dart';

class DholuApp extends StatelessWidget {
  const DholuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Dholu',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        routerConfig: router,
      );
}
