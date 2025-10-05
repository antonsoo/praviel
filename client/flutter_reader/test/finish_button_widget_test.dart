import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_reader/models/lesson.dart';
import 'package:flutter_reader/pages/lessons_page.dart';
import 'package:flutter_reader/services/lesson_api.dart';
import 'package:flutter_reader/services/byok_controller.dart';

/// Widget test to verify FINISH button fix
///
/// This test verifies that:
/// 1. FINISH button is enabled on the last task before checking
/// 2. Clicking FINISH checks the answer and completes the lesson
/// 3. Empty answers are handled correctly
void main() {
  testWidgets('FINISH button is enabled on last task before checking',
      (WidgetTester tester) async {
    final mockApi = _MockLessonApi();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LessonsPage(
              api: mockApi,
              openReader: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Generate a lesson (mock returns 3 tasks)
    final generateButton = find.text('Start Daily Practice');
    expect(generateButton, findsOneWidget);
    await tester.tap(generateButton);
    await tester.pumpAndSettle();

    // Should be on first task
    expect(find.textContaining('Task 1 of 3'), findsOneWidget);

    // Complete first task (alphabet - select the correct answer)
    final alphaOption = find.text('α');
    await tester.tap(alphaOption);
    await tester.pumpAndSettle();

    // Check button should be enabled
    final checkButton1 = find.text('CHECK');
    expect(checkButton1, findsOneWidget);

    // Click check
    await tester.tap(checkButton1);
    await tester.pumpAndSettle();

    // Move to next task
    final nextButton1 = find.text('NEXT');
    expect(nextButton1, findsOneWidget);
    await tester.tap(nextButton1);
    await tester.pumpAndSettle();

    // Should be on second task
    expect(find.textContaining('Task 2 of 3'), findsOneWidget);

    // Complete second task (cloze - fill the blank)
    final blankField = find.byType(TextField).first;
    await tester.enterText(blankField, 'ἐν');
    await tester.pumpAndSettle();

    // Check and move to next
    final checkButton2 = find.text('CHECK');
    await tester.tap(checkButton2);
    await tester.pumpAndSettle();

    final nextButton2 = find.text('NEXT');
    await tester.tap(nextButton2);
    await tester.pumpAndSettle();

    // Should be on LAST task (task 3)
    expect(find.textContaining('Task 3 of 3'), findsOneWidget);

    // This is a translate task - has a text field
    final translateField = find.byType(TextField).first;

    // KEY TEST: FINISH button should exist and be ENABLED
    // even though we haven't entered text or clicked CHECK
    final finishButton = find.text('FINISH');
    expect(finishButton, findsOneWidget,
        reason: 'FINISH button should exist on last task');

    // Find the actual button widget to check if it's enabled
    final finishButtonWidget = tester.widget<OutlinedButton>(
      find.ancestor(
        of: finishButton,
        matching: find.byType(OutlinedButton),
      ),
    );

    expect(finishButtonWidget.onPressed, isNotNull,
        reason: 'FINISH button should be enabled (have an onPressed callback)');

    // Now enter text and click FINISH
    await tester.enterText(translateField, 'And the Word was with God');
    await tester.pumpAndSettle();

    // Click FINISH
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    // Should show lesson completion summary
    expect(find.byKey(const Key('lesson-summary')), findsOneWidget,
        reason: 'Lesson summary should appear after clicking FINISH');
  });

  testWidgets('FINISH button with empty answer completes lesson',
      (WidgetTester tester) async {
    final mockApi = _MockLessonApi();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LessonsPage(
              api: mockApi,
              openReader: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Generate lesson
    await tester.tap(find.text('Start Daily Practice'));
    await tester.pumpAndSettle();

    // Skip through to last task
    // Task 1
    await tester.tap(find.text('α'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHECK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    // Task 2
    await tester.enterText(find.byType(TextField).first, 'ἐν');
    await tester.pumpAndSettle();
    await tester.tap(find.text('CHECK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('NEXT'));
    await tester.pumpAndSettle();

    // Task 3 (last) - DON'T enter any text, just click FINISH
    final finishButton = find.text('FINISH');
    expect(finishButton, findsOneWidget);

    // Click FINISH without entering text
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    // Should show error message for empty answer
    expect(
      find.textContaining('Write a draft translation first'),
      findsOneWidget,
      reason: 'Should show error for empty answer',
    );

    // But lesson should still complete (marked as wrong)
    expect(
      find.byKey(const Key('lesson-summary')),
      findsOneWidget,
      reason: 'Lesson should complete even with empty answer',
    );
  });
}

/// Mock LessonApi that returns a predictable 3-task lesson
class _MockLessonApi implements LessonApi {
  @override
  String get baseUrl => 'http://mock';

  @override
  Future<void> close() async {}

  @override
  Future<LessonResponse> generate(
    GeneratorParams params,
    ByokSettings settings,
  ) async {
    // Return a simple 3-task lesson for testing
    return LessonResponse(
      meta: Meta(
        language: 'grc',
        profile: 'beginner',
        provider: 'echo',
        model: null,
        note: null,
      ),
      tasks: [
        AlphabetTask(
          prompt: 'Which letter makes the "alpha" sound?',
          options: const ['α', 'β', 'γ', 'δ'],
          answer: 'α',
        ),
        ClozeTask(
          text: 'ἐν ἀρχῇ ἦν ὁ λόγος',
          blanks: [
            Blank(idx: 0, surface: 'ἐν'),
          ],
          sourceKind: 'daily',
        ),
        TranslateTask(
          text: 'καὶ ὁ λόγος ἦν πρὸς τὸν θεόν',
          sampleSolution: 'And the Word was with God',
          direction: 'grc→en',
          rubric: 'Translate this Greek text to English',
        ),
      ],
    );
  }
}
