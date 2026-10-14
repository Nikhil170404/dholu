import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dholu/native/native_bridge.dart';
import 'package:dholu/data/repository.dart';

import 'helpers.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late Env env;
  Future<void> boot(
    WidgetTester t, {
    Env? e,
    String location = '/home',
    Size size = const Size(420, 1000),
  }) async {
    env = e ?? Env();
    await env.init();
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.reset);
    await t.pumpWidget(env.app(location: location));
    await settle(t);
  }

  /// Scrolls [f] fully into view (above the bottom navigation bar) before interacting.
  Future<void> reveal(WidgetTester t, Finder f) async {
    await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(f);
    await t.pump();
  }

  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.runAsync(() => env.dispose());
  }

  group('settings', () {
    testWidgets(
      'language switch changes the UI; lock-screen detail is off by default and persists',
      (t) async {
        await boot(t, location: '/settings');
        expect(find.text('BHASHA'), findsOneWidget);
        await t.tap(find.text('English'));
        await settle(t);
        expect(find.text('LANGUAGE'), findsOneWidget);
        expect(env.prefs.getString('lang'), 'english');
        expect(env.prefs.getBool('lockScreenDetail') ?? false, isFalse);
        await t.tap(find.text('Show detail on lock screen'));
        await settle(t);
        expect(env.prefs.getBool('lockScreenDetail'), isTrue);
        await done(t);
      },
    );

    testWidgets('online features are off by default; enabling web search reveals provider', (t) async {
      await boot(t, location: '/settings');
      await reveal(t, find.text('Web search chalu karo'));
      expect(find.text('DuckDuckGo'), findsNothing);
      await t.tap(find.text('Web search chalu karo'));
      await settle(t);
      await reveal(t, find.text('DuckDuckGo'));
      expect(find.text('DuckDuckGo'), findsOneWidget);
      expect(env.prefs.getBool('webSearch'), isTrue);
      await done(t);
    });

    testWidgets('turning the morning summary off cancels the scheduled task', (
      t,
    ) async {
      await boot(t);
      expect(env.scheduler.morningScheduled, greaterThanOrEqualTo(1));
      env.router.go('/settings');
      await settle(t);
      await t.tap(find.text('Subah ka summary'));
      await settle(t);
      expect(env.scheduler.morningCancelled, 1);
      await done(t);
    });

    testWidgets(
      'API keys are saved only to the secure store, never to preferences',
      (t) async {
        await boot(
          t,
          e: Env(prefs: {'cloudEnabled': true}),
          location: '/settings',
        );
        await t.scrollUntilVisible(
          find.text('API key'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await t.enterText(
          find.widgetWithText(TextField, 'API key'),
          'sk-secret',
        );
        await t.tap(find.text('OK').last);
        await settle(t);
        expect(await env.secrets.read('cloud_api_key'), 'sk-secret');
        expect(
          env.prefs.getKeys().any(
            (k) => (env.prefs.get(k) ?? '').toString().contains('sk-secret'),
          ),
          isFalse,
        );
        await done(t);
      },
    );
  });

  group('model screen', () {
    testWidgets('8 GB phone: recommends the 2 GB tier; download starts Wi-Fi-only', (t) async {
      await boot(t, location: '/settings/models');
      expect(find.text('Dholu Bada (Llama 3.2 3B)'), findsOneWidget);
      expect(find.text('Dholu ki pasand'), findsOneWidget);
      expect(find.textContaining('8.0 GB RAM'), findsWidgets);
      final dl = find.textContaining('Download  ·').first;
      await reveal(t, dl);
      await t.tap(dl); // first model = small
      await settle(t);
      expect(env.downloader.started, ['gemma3-1b']);
      expect(env.downloader.wifi, isTrue);
      await done(t);
    });

    testWidgets('2 GB phone: every model is blocked with a reason, rules mode is selected', (t) async {
      final e = Env(specs: const DeviceSpecs(totalRamMb: 2048, availRamMb: 700, freeStorageMb: 20000, cores: 4, abis: ['arm64-v8a'], sdk: 30, lowRam: true, soc: '', model: 'Tiny'));
      await boot(t, e: e, location: '/settings/models');
      expect(find.textContaining('low-RAM'), findsWidgets);
      expect(find.text('Dholu ki pasand'), findsNothing);
      final dl = find.textContaining('Download  ·').first;
      await reveal(t, dl);
      final btn = t.widget<InkWell>(find.ancestor(of: dl, matching: find.byType(InkWell)).first);
      expect(btn.onTap, isNull);
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      await done(t);
    });

  });

  group('assistant', () {
    testWidgets('no model: explains how to turn one on instead of failing', (
      t,
    ) async {
      await boot(t, location: '/talk');
      await t.enterText(find.byType(TextField), 'namaste');
      await t.tap(find.byIcon(Icons.arrow_upward_rounded));
      await settle(t);
      expect(
        find.text('Pehle Settings mein AI model chalu karo.'),
        findsOneWidget,
      );
      expect(find.text('Settings kholo'), findsOneWidget);
      await done(t);
    });

    testWidgets(
      'with a model: streams a reply; web chip is hidden unless enabled',
      (t) async {
        await boot(
          t,
          e: Env(llm: FakeLlm(reply: 'Namaste Ravi ji')),
          location: '/talk',
        );
        expect(find.text('Web search'), findsNothing);
        await t.enterText(find.byType(TextField), 'hello');
        await t.tap(find.byIcon(Icons.arrow_upward_rounded));
        await settle(t);
        await t.pump(const Duration(milliseconds: 200));
        expect(find.text('hello'), findsOneWidget);
        expect(find.textContaining('Namaste Ravi ji'), findsOneWidget);
        await done(t);
      },
    );

    testWidgets('web chip appears when web search is enabled in settings', (
      t,
    ) async {
      await boot(
        t,
        e: Env(llm: FakeLlm(), prefs: {'webSearch': true}),
        location: '/talk',
      );
      expect(find.text('Web search'), findsOneWidget);
      await done(t);
    });
  });

  group('email', () {
    testWidgets(
      'drafts with a local model, then opens the email app (never sends)',
      (t) async {
        await boot(
          t,
          e: Env(llm: FakeLlm()),
          location: '/email',
        );
        await t.enterText(
          find.widgetWithText(TextField, 'Kisko (naam ya email)'),
          'anil@example.com',
        );
        await t.enterText(
          find.widgetWithText(TextField, 'Kya likhna hai?'),
          'report kal tak bhej dunga',
        );
        await t.tap(find.text('Draft banao'));
        await settle(t);
        expect(find.text('Report update'), findsOneWidget);
        await t.scrollUntilVisible(
          find.text('Email app mein kholo'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(find.text('Email app mein kholo'));
        await settle(t);
        expect(env.bridge.emails.single.to, 'anil@example.com');
        expect(env.bridge.emails.single.subject, 'Report update');
        expect(env.bridge.emails.single.body, contains('Report kal tak'));
        await done(t);
      },
    );

    testWidgets(
      'cloud model + message context asks for consent first; declining sends nothing',
      (t) async {
        final e = Env(llm: FakeLlm(local: false));
        await e.init();
        await e.seed();
        await boot(t, e: e, location: '/email');
        await t.enterText(
          find.widgetWithText(TextField, 'Kya likhna hai?'),
          'update do',
        );
        await t.tap(find.text('Messages ka context lo'));
        await settle(t);
        await t.tap(find.byType(DropdownButtonFormField<String>));
        await settle(t);
        await t.tap(find.text('Anil Sir').last);
        await settle(t);
        await t.tap(find.text('Draft banao'));
        await settle(t);
        expect(
          find.text('Cloud model ko messages bhejne hain?'),
          findsOneWidget,
        );
        await t.tap(find.text('Cancel'));
        await settle(t);
        expect(find.text('Report update'), findsNothing);
        await done(t);
      },
    );
  });

  group('privacy screen', () {
    testWidgets('shows counts and deletes everything on confirm', (t) async {
      final e = Env();
      await e.init();
      await e.seed();
      await boot(t, e: e, location: '/data');
      expect(find.textContaining('3 notifications'), findsOneWidget);
      expect(find.textContaining('OTP, password aur bank'), findsOneWidget);
      await t.tap(find.text('Sab delete karo'));
      await settle(t);
      await t.tap(find.text('Delete'));
      await settle(t);
      await t.runAsync(() async => expect(await env.repo.eventCount(), 0));
      expect(find.text('Abhi kuch saved nahi hai'), findsOneWidget);
      await done(t);
    });
  });

  group('shell: urgent handling', () {
    testWidgets(
      'foreground: shutter alert + drum roll; background: urgent notification instead',
      (t) async {
        final e = Env();
        await e.init();
        await e.repo.syncApps(const [AppRef('com.whatsapp', 'WhatsApp')]);
        await e.repo.setImportant('com.whatsapp', true);
        await boot(t, e: e);
        env.bridge.emit(
          env.raw(
            'u1',
            'Anil Sir',
            'report 10 baje tak bhejna urgent asap',
            min: 0,
          ),
        );
        await settle(t);
        expect(find.textContaining('ZAROORI'), findsWidgets);
        expect(env.player.plays, 1);
        expect(env.notifier.urgent, isEmpty);
        await t.pump(
          const Duration(seconds: 6),
        ); // shutter plays once and rolls back up
        await t.pump(const Duration(seconds: 1));

        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        env.bridge.emit(
          env.raw('u2', 'Boss', 'deadline aaj urgent immediately', min: 0),
        );
        await settle(t);
        expect(env.notifier.urgent.length, 1);
        expect(env.player.plays, 1); // no in-app sound while backgrounded
        t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await settle(t);
        await done(t);
      },
    );

    testWidgets('OTP and muted-app notifications never trigger an alert', (
      t,
    ) async {
      final e = Env();
      await e.init();
      await e.repo.syncApps(const [
        AppRef('com.whatsapp', 'WhatsApp'),
        AppRef('com.myntra', 'Myntra'),
      ]);
      await e.repo.setImportant('com.whatsapp', true);
      await boot(t, e: e);
      env.bridge.emit(
        env.raw('o1', 'HDFC', 'Your OTP is 482913. Do not share. urgent'),
      );
      env.bridge.emit(
        env.raw(
          'm1',
          'Myntra',
          'urgent sale ending asap',
          pkg: 'com.myntra',
          app: 'Myntra',
        ),
      );
      await settle(t);
      expect(env.player.plays, 0);
      expect(env.notifier.urgent, isEmpty);
      expect(find.textContaining('ZAROORI'), findsNothing);
      await done(t);
    });
  });

  group('summary sheet', () {
    testWidgets('lists items with actions and links to all / apps', (t) async {
      final e = Env();
      await e.init();
      await e.seed();
      await boot(t, e: e, location: '/summary');
      expect(find.text('Bijli bill kal due'), findsOneWidget);
      expect(find.text('Pay now'), findsOneWidget);
      expect(find.text('Sab dekho (1)'), findsOneWidget);
      await done(t);
    });
  });
}
