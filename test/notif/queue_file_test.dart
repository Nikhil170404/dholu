import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/native/queue_file.dart';

void main() {
  test('drains valid lines, skips corrupt ones, clears the file', () async {
    final dir = Directory.systemTemp.createTempSync('q');
    addTearDown(() => dir.deleteSync(recursive: true));
    final good = jsonEncode({
      'key': 'k1',
      'pkg': 'com.whatsapp',
      'appName': 'WA',
      'title': 'Mummy',
      'text': 'hi',
      'postedAt': 1760000000000,
      'messaging': true,
    });
    final otp = jsonEncode({
      'key': 'k2',
      'pkg': 'bank',
      'appName': 'B',
      'title': '',
      'text': '',
      'postedAt': 1760000001000,
      'sensitive': 'otp',
    });
    File('${dir.path}/${QueueFile.fileName}')
        .writeAsStringSync('$good\nnot json\n\n$otp\n');
    final out = await QueueFile.drain(dir);
    expect(out.length, 2);
    expect(out.first.title, 'Mummy');
    expect(out.first.isMessaging, isTrue);
    expect(out.last.sensitiveHint, 'otp');
    expect(File('${dir.path}/${QueueFile.fileName}').existsSync(), isFalse);
    expect(await QueueFile.drain(dir), isEmpty);
    expect(dir.listSync(), isEmpty); // no leftover .processing files
  });
}
