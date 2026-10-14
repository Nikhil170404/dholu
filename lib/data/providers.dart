import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'fake_data.dart';

/// Which apps are marked important. M1: in-memory, seeded from fake data.
class ImportantApps extends Notifier<Set<String>> {
  @override
  Set<String> build() => {
    for (final a in fakeApps)
      if (a.important) a.pkg,
  };

  void toggle(String pkg, bool on) =>
      state = on ? {...state, pkg} : ({...state}..remove(pkg));
}

final importantAppsProvider = NotifierProvider<ImportantApps, Set<String>>(
  ImportantApps.new,
);
