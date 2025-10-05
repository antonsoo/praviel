import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_reader/main.dart' as app;

/// Integration test to verify FINISH button works on last lesson task
///
/// This test verifies the bug fix where the FINISH button was disabled
/// on the last task until the user clicked CHECK first.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('FINISH button is clickable on last lesson task',
      (WidgetTester tester) async {
    // Start the app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Navigate to Lessons page
    final lessonsFinder = find.text('Lessons');
    expect(lessonsFinder, findsOneWidget);
    await tester.tap(lessonsFinder);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Generate a lesson - look for "Start Daily Practice" button
    final startButton = find.text('Start Daily Practice');
    if (startButton.evaluate().isNotEmpty) {
      await tester.tap(startButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    } else {
      // Try finding other generate buttons
      final generateButton = find.text('Generate Custom Lesson');
      if (generateButton.evaluate().isNotEmpty) {
        await tester.tap(generateButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    }

    // Verify we have a lesson loaded
    expect(find.textContaining('Task'), findsWidgets);

    // Navigate through tasks to the last one
    // Keep clicking NEXT until we reach the last task
    int safetyCounter = 0;
    while (safetyCounter < 10) {
      // Look for NEXT button
      final nextButton = find.text('NEXT');
      if (nextButton.evaluate().isEmpty) {
        // No NEXT button found, we might be on the last task
        break;
      }

      // If NEXT button exists and is enabled, click it
      await tester.tap(nextButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      safetyCounter++;
    }

    // Now we should be on the last task
    // Verify FINISH button exists
    final finishButton = find.text('FINISH');
    expect(finishButton, findsOneWidget,
        reason: 'FINISH button should exist on last task');

    // The key test: FINISH button should be ENABLED (tappable)
    // even if we haven't checked the answer yet
    final finishButtonWidget = tester.widget<ElevatedButton>(
      find.ancestor(
        of: finishButton,
        matching: find.byType(ElevatedButton),
      ),
    );

    expect(finishButtonWidget.enabled, isTrue,
        reason: 'FINISH button should be enabled on last task before checking');

    // Click FINISH - it should check the answer and complete the lesson
    await tester.tap(finishButton);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify lesson completed - should see summary or completion message
    final completionIndicators = [
      find.textContaining('complete', skipOffstage: false),
      find.textContaining('Nice', skipOffstage: false),
      find.textContaining('Try another', skipOffstage: false),
      find.byKey(const Key('lesson-summary')),
    ];

    bool foundCompletion = false;
    for (final finder in completionIndicators) {
      if (finder.evaluate().isNotEmpty) {
        foundCompletion = true;
        break;
      }
    }

    expect(foundCompletion, isTrue,
        reason: 'Lesson should complete after clicking FINISH');
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('FINISH button with empty answer still completes lesson',
      (WidgetTester tester) async {
    // Start the app
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Navigate to Lessons page
    await tester.tap(find.text('Lessons'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Generate a lesson
    final startButton = find.text('Start Daily Practice');
    if (startButton.evaluate().isNotEmpty) {
      await tester.tap(startButton);
      await tester.pumpAndSettle(const Duration(seconds: 5));
    }

    // Navigate to last task
    int safetyCounter = 0;
    while (safetyCounter < 10) {
      final nextButton = find.text('NEXT');
      if (nextButton.evaluate().isEmpty) break;
      await tester.tap(nextButton);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      safetyCounter++;
    }

    // On last task with translate exercise, don't enter any text
    // Just click FINISH directly
    final finishButton = find.text('FINISH');
    if (finishButton.evaluate().isNotEmpty) {
      await tester.tap(finishButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should show error message but still complete
      // (marked as wrong, matching NEXT button behavior)
      expect(
        find.textContaining('complete', skipOffstage: false),
        findsWidgets,
        reason: 'Lesson should complete even with empty answer',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
