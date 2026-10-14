import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/mascot/dholu_widget.dart';

void main() {
  testWidgets('every pose renders and animates without errors', (tester) async {
    for (final p in DholuPose.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(child: Dholu(pose: p, size: 120)),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(Dholu), findsOneWidget);
    }
  });

  testWidgets('drum pose is taller than idle (drum below body)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Dholu(pose: DholuPose.drumRoll, size: 120, animate: false),
        ),
      ),
    );
    expect(tester.getSize(find.byType(Dholu)).height, closeTo(130, 0.01));
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: Dholu(size: 120, animate: false))),
    );
    expect(tester.getSize(find.byType(Dholu)).height, closeTo(120, 0.01));
  });
}
