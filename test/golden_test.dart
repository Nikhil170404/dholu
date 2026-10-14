import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/mascot/dholu_widget.dart';
import 'package:dholu/theme/tokens.dart';

void main() {
  testWidgets('mascot pose sheet golden', (t) async {
    await t.binding.setSurfaceSize(const Size(760, 190));
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        backgroundColor: DColors.ground,
        body: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          for (final p in DholuPose.values) Dholu(pose: p, size: 120, animate: false),
        ]),
      ),
    ));
    await expectLater(find.byType(Scaffold), matchesGoldenFile('goldens/mascot_poses.png'));
  });
}
