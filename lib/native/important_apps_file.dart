import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Shares the important-apps set with the Kotlin listener (android/.../ImportantApps.kt), which
/// uses it to blank text from other apps while the Flutter engine is not running.
class ImportantAppsFile {
  static const fileName = 'dholu_important_apps.txt';

  static Future<void> write(Directory dir, Set<String> pkgs) async {
    final tmp = File('${dir.path}/$fileName.tmp');
    await tmp.writeAsString(pkgs.join('\n'), flush: true);
    await tmp.rename(
      '${dir.path}/$fileName',
    ); // atomic swap: Kotlin never reads a half-written file
  }

  /// Best effort: a missing plugin (tests, desktop) must never break choosing apps.
  static Future<void> writeToAppDir(Set<String> pkgs) async {
    try {
      final dir = await getApplicationSupportDirectory();
      await write(Directory(dir.path), pkgs);
    } on Object {
      // not on a device
    }
  }
}
