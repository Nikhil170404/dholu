import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/core/types.dart';
import 'package:dholu/l10n/strings.dart';

void main() {
  test('every key has Hinglish and English, placeholders match', () {
    final hi = const Tr(Lang.hinglish), en = const Tr(Lang.english);
    for (final k in Tr.keys) {
      final a = hi(k), b = en(k);
      expect(a.trim(), isNotEmpty, reason: k);
      expect(b.trim(), isNotEmpty, reason: k);
      final pa = RegExp(r'\{(\w+)\}')
          .allMatches(a)
          .map((m) => m.group(1))
          .toSet();
      final pb = RegExp(r'\{(\w+)\}')
          .allMatches(b)
          .map((m) => m.group(1))
          .toSet();
      expect(pa, pb, reason: 'placeholders differ in $k');
    }
  });
  test('placeholder substitution and language switch', () {
    expect(
      const Tr(Lang.hinglish)('hidden_title', {'n': 47}),
      'Baaki 47 chhupe hain',
    );
    expect(
      const Tr(Lang.english)('hidden_title', {'n': 47}),
      '47 more are hidden',
    );
    expect(const Tr(Lang.english)('nope_missing'), 'nope_missing');
  });
}
