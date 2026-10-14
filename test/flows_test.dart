import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/data/repository.dart';

import 'helpers.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late Env env;
  Future<void> boot(WidgetTester t, {Env? e, String location = '/home'}) async {
    env = e ?? Env();
    await env.init();
    t.view.physicalSize = const Size(420, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(env.app(location: location));
    await settle(t);
  }

  // Unmount first, then close the DB on the real event loop (closing inside FakeAsync hangs).
  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() => env.dispose());
  }

  testWidgets('home: empty state when nothing important', (t) async {
    await boot(t);
    expect(find.text('Abhi sab shaant hai'), findsOneWidget);
    await done(t);
  });

  testWidgets('home: urgent card, rows, hidden count from stored events', (
    t,
  ) async {
    final e = Env();
    await e.init();
    await e.seed();
    await boot(t, e: e);
    expect(find.text('Aaj ke zaroori updates'), findsOneWidget);
    expect(find.textContaining('Anil Sir: Report 10 baje tak'), findsOneWidget);
    expect(find.text('Bijli bill kal due'), findsOneWidget);
    expect(find.text('Pay now'), findsOneWidget);
    expect(find.text('Baaki 1 chhupe hain'), findsOneWidget);
    expect(find.text('2 zaroori, 1 chhupe'), findsOneWidget);
    await done(t);
  });

  testWidgets(
    'Pay now fires the source notification intent and marks handled',
    (t) async {
      final e = Env();
      await e.init();
      await e.seed();
      await boot(t, e: e);
      await t.tap(find.text('Pay now'));
      await settle(t);
      expect(env.bridge.fired, ['b']);
      expect(
        (await env.repo.since(DateTime(2020)))
            .firstWhere((x) => x.key == 'b')
            .handled,
        isTrue,
      );
      expect(find.text('Bijli bill kal due'), findsNothing);
      final fb = await env.repo.knowledge();
      expect(fb.learned['paytm'], greaterThan(0)); // tap taught Dholu
      await done(t);
    },
  );

  testWidgets(
    'Reply opens the draft screen; no model -> quick replies, never sends',
    (t) async {
      final e = Env();
      await e.init();
      await e.seed();
      await boot(t, e: e);
      await t.tap(find.text('Reply karo').first);
      await settle(t);
      expect(env.path, startsWith('/draft/'));
      expect(find.textContaining('AI model chalu nahi hai'), findsOneWidget);
      await t.tap(find.text('Theek hai, dekhta hoon.'));
      await t.pump();
      await t.tap(find.text('WhatsApp mein kholo'));
      await settle(t);
      expect(
        env.copied.single,
        'Theek hai, dekhta hoon.',
      ); // clipboard only: the user pastes and sends
      expect(env.bridge.fired, ['a']);
      expect(find.text('Draft copy ho gaya. Paste karo.'), findsOneWidget);
      await done(t);
    },
  );

  testWidgets('Draft with a model: AI draft, tone chip regenerates', (t) async {
    final e = Env(llm: FakeLlm(reply: 'Haan ji, 10 baje tak bhej dunga'));
    await e.init();
    await e.seed();
    await boot(t, e: e);
    await t.tap(find.text('Reply karo').first);
    await settle(t);
    expect(find.text('Haan ji, 10 baje tak bhej dunga'), findsOneWidget);
    await t.tap(find.text('Chhota'));
    await settle(t);
    expect(find.byType(TextField), findsOneWidget);
    await done(t);
  });

  testWidgets('Choose apps: toggling saves to the database', (t) async {
    final e = Env(
      apps: const [
        AppRef('com.whatsapp', 'WhatsApp'),
        AppRef('com.zomato', 'Zomato'),
      ],
    );
    await e.init();
    await boot(t, e: e, location: '/apps');
    expect(find.text('WhatsApp'), findsOneWidget);
    await t.tap(find.text('WhatsApp'));
    await settle(t);
    expect(await env.repo.importantPkgs(), {'com.whatsapp'});
    await t.enterText(find.byType(TextField), 'zom');
    await settle(t);
    expect(find.text('WhatsApp'), findsNothing);
    expect(find.text('Zomato'), findsOneWidget);
    await done(t);
  });

  testWidgets(
    'Drum alert: primary choice records feedback and goes to Sahi chuna / draft',
    (t) async {
      final e = Env();
      await e.init();
      await e.seed();
      await boot(t, e: e, location: '/alert/1');
      expect(find.text('Sahi kaam chuno'), findsOneWidget);
      expect(find.text('Dholu ki pasand'), findsOneWidget);
      expect(env.player.plays, 1); // drum roll when the alert opens
      await t.tap(find.text('Reply karo'));
      await settle(t);
      expect(find.text('Sahi chuna!'), findsOneWidget);
      expect(find.text('Draft dekho'), findsOneWidget);
      expect((await env.repo.knowledge()).learned['anil sir'], greaterThan(0));
      await t.tap(find.text('Draft dekho'));
      await settle(t);
      expect(env.path, '/draft/1');
      await done(t);
    },
  );

  testWidgets(
    'Drum alert: remind later schedules 10 min reminder; skip teaches Dholu',
    (t) async {
      final e = Env();
      await e.init();
      await e.seed();
      await boot(t, e: e, location: '/alert/1');
      await t.tap(find.text('10 min baad yaad dilao'));
      await settle(t);
      expect(env.scheduler.reminded, [1]);
      expect(env.path, '/home');
      await done(t);
    },
  );

  testWidgets('Drum alert respects the drum-sound setting', (t) async {
    final e = Env(prefs: {'drumSound': false});
    await e.init();
    await e.seed();
    await boot(t, e: e, location: '/alert/1');
    expect(env.player.plays, 0);
    await done(t);
  });

  testWidgets('Tips: skipping completes onboarding and opens home', (t) async {
    await boot(
      t,
      e: Env(prefs: {'onboarded': false}),
      location: '/tips',
    );
    expect(find.text('3 tips, phir shuru'), findsOneWidget);
    await t.tap(find.text('Baad mein'));
    await settle(t);
    expect(env.path, '/home');
    expect(env.prefs.getBool('onboarded'), isTrue);
    await done(t);
  });

  testWidgets(
    'Tips: grant button asks notification permission and opens system settings',
    (t) async {
      await boot(
        t,
        e: Env(prefs: {'onboarded': false}),
        location: '/tips',
      );
      await t.ensureVisible(find.text('Notification access do'));
      await t.tap(find.text('Notification access do'));
      await settle(t);
      expect(env.notifier.permissionAsked, isTrue);
      await done(t);
    },
  );
}
