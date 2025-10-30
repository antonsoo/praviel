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

bool _containsGreekText(Widget widget) {
  if (widget is Text) {
    final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
    return text.codeUnits.any((code) => code >= 0x0370 && code <= 0x03FF);
  }
  return false;
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 2));

  testWidgets('Text-range picker flow generates lesson from specific passage', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    // Find and tap "Learn from Famous Texts" card
    final famousTextsCard = find.text('Learn from Famous Texts');
    expect(
      famousTextsCard,
      findsOneWidget,
      reason: 'Famous Texts card should exist on home screen',
    );

    await tester.tap(famousTextsCard);
    await tester.pumpAndSettle();

    // Should navigate to text range picker page
    await pumpUntil(
      tester,
      find.text('Master Vocabulary from Classic Passages'),
      timeout: const Duration(seconds: 5),
    );

    // Verify text range options are displayed
    final iliadOption = find.text('Iliad 1.20-1.50 (Chryses)');
    expect(
      iliadOption,
      findsOneWidget,
      reason: 'Iliad 1.20-1.50 option should be available',
    );

    // Tap the Iliad 1.20-1.50 range
    await tester.tap(iliadOption);
    await tester.pumpAndSettle();

    // Wait for API call to complete and lesson page to load
    await pumpUntil(
      tester,
      find.text('Generated from Il.1.20–Il.1.50'),
      timeout: const Duration(seconds: 10),
    );

    // Verify lesson was generated
    final lessonIndicator = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data != null &&
          widget.data!.contains('Lesson contains'),
    );
    expect(
      lessonIndicator,
      findsOneWidget,
      reason: 'Lesson confirmation message should appear',
    );

    // Verify Greek text is present (indicates real vocabulary was loaded)
    final greekTextFinder = find.byWidgetPredicate(_containsGreekText);
    expect(
      greekTextFinder,
      findsAtLeastNWidgets(1),
      reason: 'Lesson should contain Greek vocabulary',
    );
  });

  testWidgets('Text-range picker displays multiple passage options', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();

    // Navigate to text range picker
    await tester.tap(find.text('Learn from Famous Texts'));
    await tester.pumpAndSettle();

    await pumpUntil(
      tester,
      find.text('Master Vocabulary from Classic Passages'),
      timeout: const Duration(seconds: 5),
    );

    // Verify multiple options exist
    expect(
      find.text('Iliad 1.1-1.10 (Opening)'),
      findsOneWidget,
      reason: 'Should have Iliad opening passage',
    );
    expect(
      find.text('Iliad 1.20-1.50 (Chryses)'),
      findsOneWidget,
      reason: 'Should have Chryses passage',
    );

    // Verify Greek subtitle text is shown
    final greekSubtitle = find.byWidgetPredicate(_containsGreekText);
    expect(
      greekSubtitle,
      findsAtLeastNWidgets(1),
      reason: 'Passage options should show Greek text previews',
    );
  });
}
