import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:ancient_languages_app/localization/strings_lessons_en.dart';
import 'package:ancient_languages_app/main.dart' as app;

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

    binding.reportData = <String, Object?>{
      'captures': <String>['demo_home', 'demo_lesson'],
    };
  });
}
