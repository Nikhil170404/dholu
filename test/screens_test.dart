import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/data/providers.dart';
import 'package:dholu/shutter/shutter_alert.dart';
import 'package:dholu/theme/theme.dart';
import 'package:dholu/ui/choose_apps_screen.dart';
import 'package:dholu/ui/home_screen.dart';
import 'package:dholu/ui/loaders.dart';
import 'package:dholu/ui/tips_screen.dart';

Widget wrap(Widget w) => ProviderScope(child: MaterialApp(theme: buildTheme(), home: w));

void main() {
  testWidgets('home shows urgent card and hidden count', (t) async {
    await t.pumpWidget(wrap(const HomeScreen(animate: false)));
    expect(find.text('Aaj ke zaroori updates'), findsOneWidget);
    expect(find.textContaining('Baaki 47 chhupe hain'), findsOneWidget);
    expect(find.text('Reply karo'), findsWidgets);
  });

  testWidgets('choose apps toggles important state', (t) async {
    await t.pumpWidget(wrap(const ChooseAppsScreen()));
    final container = ProviderScope.containerOf(t.element(find.byType(ChooseAppsScreen)));
    final before = container.read(importantAppsProvider).length;
    await t.tap(find.byType(Switch).at(4));
    await t.pump();
    expect(container.read(importantAppsProvider).length, before + 1);
  });

  testWidgets('tips screen has permission CTA and skip', (t) async {
    await t.pumpWidget(wrap(const TipsScreen()));
    expect(find.text('Notification access do'), findsOneWidget);
    expect(find.text('Baad mein'), findsOneWidget);
  });

  testWidgets('shutter alert plays once and reports finished', (t) async {
    var done = false;
    await t.pumpWidget(wrap(Align(
      alignment: Alignment.topCenter,
      child: ShutterAlert(title: 'Test', source: 'WhatsApp', onFinished: () => done = true),
    )));
    await t.pump(const Duration(milliseconds: 2000));
    expect(find.text('Test'), findsOneWidget);
    expect(done, isFalse);
    await t.pump(const Duration(seconds: 4));
    expect(done, isTrue);
  });

  testWidgets('shutter alert swipe-up dismisses early', (t) async {
    var done = false;
    await t.pumpWidget(wrap(Align(
      alignment: Alignment.topCenter,
      child: ShutterAlert(title: 'Test', source: 'WhatsApp', onFinished: () => done = true),
    )));
    await t.pump(const Duration(milliseconds: 1800));
    await t.fling(find.text('Test'), const Offset(0, -150), 800);
    await t.pump(); await t.pump(const Duration(milliseconds: 1200));
    expect(done, isTrue);
  });

  testWidgets('loaders page renders all four loaders', (t) async {
    await t.pumpWidget(wrap(const LoadersScreen()));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(SummaryLoader), findsOneWidget);
    expect(find.byType(BouncingDots), findsOneWidget);
    expect(find.byType(ModelDownloadLoader), findsOneWidget);
    expect(find.byType(SkeletonRows), findsOneWidget);
    expect(find.textContaining('64% · 179 MB / 280 MB'), findsOneWidget);
  });
}
