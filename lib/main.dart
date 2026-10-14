import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'app.dart';
import 'settings/settings.dart';
import 'work/background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Workmanager().initialize(callbackDispatcher);
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const DholuApp(),
    ),
  );
}
