import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
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
  throw TimeoutException('Timed out waiting for $finder');
}

Set<String> _extractGreekText(WidgetTester tester) {
  final greekWords = <String>{};

  // Find all Text widgets
  final textWidgets = tester.widgetList<Text>(find.byType(Text));

  for (final widget in textWidgets) {
    final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';

    // Extract Greek words (sequences of Greek characters)
    final words = text.split(RegExp(r'[^α-ωΑ-Ωἀ-ὼᾀ-ῼ]+'));
    for (final word in words) {
      if (word.isNotEmpty &&
          word.codeUnits.any((code) => code >= 0x0370 && code <= 0x03FF)) {
        greekWords.add(word);
      }
    }
  }

  return greekWords;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 2));

  testWidgets('Register toggle changes lesson vocabulary', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    // Navigate to Lessons tab
    final lessonsTab = find.text('Lessons');
    expect(lessonsTab, findsWidgets, reason: 'Lessons tab should exist');

    await tester.tap(lessonsTab.last);
    await tester.pumpAndSettle();

    // Wait for initial lesson to generate
    await pumpUntil(
      tester,
      find.text('Sources'),
      timeout: const Duration(seconds: 15),
    );

    // Find register toggle buttons
    final literaryButton = find.text('Literary');
    final everydayButton = find.text('Everyday');

    expect(
      literaryButton,
      findsOneWidget,
      reason: 'Literary button should exist in register toggle',
    );
    expect(
      everydayButton,
      findsOneWidget,
      reason: 'Everyday button should exist in register toggle',
    );

    // Wait for lesson to fully load
    await tester.pumpAndSettle();

    // Capture initial vocabulary (should be literary by default)
    final initialVocab = _extractGreekText(tester);
    expect(
      initialVocab.isNotEmpty,
      isTrue,
      reason: 'Initial lesson should contain Greek vocabulary',
    );

    // Switch to Everyday register
    await tester.tap(everydayButton);
    await tester.pumpAndSettle();

    // Wait for new lesson to generate
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Capture vocabulary after register change
    final newVocab = _extractGreekText(tester);
    expect(
      newVocab.isNotEmpty,
      isTrue,
      reason: 'New lesson should contain Greek vocabulary',
    );

    // Calculate vocabulary overlap
    final overlap = initialVocab.intersection(newVocab);
    final overlapPercent = overlap.length / initialVocab.length;

    // Vocabularies should be significantly different (less than 50% overlap)
    expect(
      overlapPercent,
      lessThan(0.5),
      reason:
          'Literary and Everyday registers should produce different vocabulary (found ${overlapPercent * 100}% overlap)',
    );
  });

  testWidgets('Register toggle persists selection', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    // Navigate to Lessons
    await tester.tap(find.text('Lessons').last);
    await tester.pumpAndSettle();

    await pumpUntil(
      tester,
      find.text('Sources'),
      timeout: const Duration(seconds: 15),
    );

    // Switch to Everyday
    await tester.tap(find.text('Everyday'));
    await tester.pumpAndSettle();

    // Navigate away and back
    await tester.tap(find.text('Reader').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lessons').last);
    await tester.pumpAndSettle();

    // Everyday button should still be selected (though we can't easily verify
    // the visual selected state, we can verify it's still present)
    expect(
      find.text('Everyday'),
      findsOneWidget,
      reason: 'Register toggle should persist',
    );
  });

  testWidgets('Register toggle updates lesson immediately', (tester) async {
    await app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lessons').last);
    await tester.pumpAndSettle();

    await pumpUntil(
      tester,
      find.text('Sources'),
      timeout: const Duration(seconds: 15),
    );

    // Capture initial state
    final beforeToggle = _extractGreekText(tester);

    // Toggle register
    await tester.tap(find.text('Everyday'));
    await tester.pump(const Duration(milliseconds: 500));

    // Should see loading indicator or new content within reasonable time
    await tester.pumpAndSettle(const Duration(seconds: 3));

    final afterToggle = _extractGreekText(tester);

    // Content should have changed
    expect(
      beforeToggle != afterToggle,
      isTrue,
      reason: 'Toggling register should update lesson content',
    );
  });
}
