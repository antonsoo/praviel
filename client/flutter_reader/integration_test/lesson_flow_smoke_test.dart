import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:praviel/localization/strings_lessons_en.dart';
import 'package:praviel/main.dart' as app;

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration interval = const Duration(milliseconds: 120),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(interval);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TimeoutException('Timed out waiting for ${finder.toString()}');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 3));

  testWidgets('lesson flow smoke test', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    if (kIsWeb) {
      await binding.convertFlutterSurfaceToImage();
    }

    await binding.takeScreenshot('demo_home');

    final lessonsTab = find.text(L10nLessons.tabTitle);
    expect(lessonsTab, findsWidgets);
    await tester.tap(lessonsTab.last);
    await tester.pumpAndSettle();

    await pumpUntil(
      tester,
      find.text('Sources'),
      timeout: const Duration(seconds: 10),
    );

    await binding.takeScreenshot('demo_lesson');

    // Navigate to profile and confirm guest upsell renders instead of blank UI
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pumpAndSettle();

    await pumpUntil(
      tester,
      find.text('Create a free account'),
      timeout: const Duration(seconds: 10),
    );

    expect(find.text('Create a free account'), findsOneWidget);
    expect(find.text('Sign in or sign up'), findsOneWidget);

    await binding.takeScreenshot('guest_profile');

    // Return home and confirm guest fallback content appears.
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();

    await pumpUntil(
      tester,
      find.text('Quick Start'),
      timeout: const Duration(seconds: 10),
    );

    expect(find.text('Quick Start'), findsWidgets);

    await binding.takeScreenshot('guest_home');

    binding.reportData = <String, Object?>{
      'captures': <String>[
        'demo_home',
        'demo_lesson',
        'guest_profile',
        'guest_home',
      ],
    };
  });
}
