import 'dart:io';

import 'native_bridge.dart';
import '../core/types.dart';

/// Reader for the JSON-lines file the Kotlin listener writes while the Flutter engine is
/// not attached (android/.../NotificationQueue.kt). Same name, same directory (app files).
class QueueFile {
  static const fileName = 'dholu_queue.jsonl';

  /// Atomically takes the queue (rename, then read) so a concurrent append is never lost
  /// or half-read; any duplicate is removed by the DB's unique (key, ts) constraint.
  static Future<List<RawNotification>> drain(Directory dir) async {
    final f = File('${dir.path}/$fileName');
    if (!f.existsSync()) {
      return const [];
    }
    final taken = File(
      '${dir.path}/$fileName.${DateTime.now().microsecondsSinceEpoch}.processing',
    );
    try {
      await f.rename(taken.path);
    } on FileSystemException {
      return const [];
    }
    final out = <RawNotification>[];
    try {
      for (final line in await taken.readAsLines()) {
        if (line.trim().isEmpty) {
          continue;
        }
        try {
          out.add(decodeNotification(line));
        } on Object {
          // skip a corrupt line, keep the rest
        }
      }
    } finally {
      await taken.delete();
    }
    return out;
  }
}
