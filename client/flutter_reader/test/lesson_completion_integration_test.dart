import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/models/lesson.dart';
import 'package:flutter_reader/widgets/exercises/alphabet_exercise.dart';
import 'package:flutter_reader/widgets/exercises/match_exercise.dart';
import 'package:flutter_reader/widgets/exercises/cloze_exercise.dart';
import 'package:flutter_reader/widgets/exercises/translate_exercise.dart';
import 'package:flutter_reader/widgets/exercises/exercise_control.dart';

void main() {
  group('Lesson Completion Integration Tests', () {
    testWidgets('AlphabetExercise enables Check button after selection',
        (WidgetTester tester) async {
      final task = AlphabetTask(
        prompt: 'Which letter sounds like "a" in "father"?',
        options: ['α', 'β', 'γ', 'δ'],
        answer: 'α',
      );

      final handle = LessonExerciseHandle();
      bool wasNotified = false;
      handle.addListener(() {
        wasNotified = true;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlphabetExercise(
              task: task,
              ttsEnabled: false,
              handle: handle,
            ),
          ),
        ),
      );

      // Initially, handle should not be ready
      expect(handle.canCheck, false);

      // Find and tap the first letter option
      final firstOption = find.text('α').first;
      await tester.tap(firstOption);
      await tester.pump();

      // Verify the handle was notified and canCheck is now true
      expect(wasNotified, true);
      expect(handle.canCheck, true);
    });

    testWidgets('MatchExercise enables Check button after all pairs matched',
        (WidgetTester tester) async {
      final task = MatchTask(
        pairs: [
          MatchPair(grc: 'ἄνθρωπος', en: 'human'),
          MatchPair(grc: 'λόγος', en: 'word'),
        ],
      );

      final handle = LessonExerciseHandle();
      int notificationCount = 0;
      handle.addListener(() {
        notificationCount++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MatchExercise(
              task: task,
              handle: handle,
            ),
          ),
        ),
      );

      // Initially not ready
      expect(handle.canCheck, false);

      // Tap first Greek word
      await tester.tap(find.text('ἄνθρωπος'));
      await tester.pump();

      // Should have been notified but still not ready (no pair made yet)
      expect(notificationCount, greaterThan(0));
      expect(handle.canCheck, false);

      // Tap matching English word
      await tester.tap(find.text('human'));
      await tester.pump();

      // Should be notified again
      expect(notificationCount, greaterThan(1));

      // Still not ready (only 1 of 2 pairs matched)
      expect(handle.canCheck, false);

      // Match second pair
      await tester.tap(find.text('λόγος'));
      await tester.pump();
      await tester.tap(find.text('word'));
      await tester.pump();

      // Now all pairs matched, should be ready
      expect(handle.canCheck, true);
    });

    testWidgets('ClozeExercise enables Check button after all blanks filled',
        (WidgetTester tester) async {
      final task = ClozeTask(
        text: 'ἐν ἀρχῇ ἦν ὁ λόγος',
        sourceKind: 'daily',
        blanks: [
          Blank(idx: 0, surface: 'ἐν'),
          Blank(idx: 1, surface: 'λόγος'),
        ],
        options: ['ἐν', 'λόγος', 'ἄλλος'],
      );

      final handle = LessonExerciseHandle();
      int notificationCount = 0;
      handle.addListener(() {
        notificationCount++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClozeExercise(
              task: task,
              onOpenInReader: () {},
              ttsEnabled: false,
              handle: handle,
            ),
          ),
        ),
      );

      // Initially not ready
      expect(handle.canCheck, false);

      // Tap first option in word bank
      final firstOption = find.widgetWithText(FilterChip, 'ἐν');
      await tester.tap(firstOption);
      await tester.pump();

      // Should be notified but not ready (only 1 of 2 blanks filled)
      expect(notificationCount, greaterThan(0));
      expect(handle.canCheck, false);

      // Tap second option
      final secondOption = find.widgetWithText(FilterChip, 'λόγος');
      await tester.tap(secondOption);
      await tester.pump();

      // Now should be ready
      expect(handle.canCheck, true);
    });

    testWidgets('TranslateExercise enables Check button when text entered',
        (WidgetTester tester) async {
      final task = TranslateTask(
        direction: 'grc→en',
        text: 'ἄνθρωπος',
        rubric: 'Translate to English',
        sampleSolution: 'a human',
      );

      final handle = LessonExerciseHandle();
      bool wasNotified = false;
      handle.addListener(() {
        wasNotified = true;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranslateExercise(
              task: task,
              ttsEnabled: false,
              handle: handle,
            ),
          ),
        ),
      );

      // Initially not ready
      expect(handle.canCheck, false);

      // Enter text into the TextField
      await tester.enterText(find.byType(TextField), 'a human');
      await tester.pump();

      // Should be notified and ready
      expect(wasNotified, true);
      expect(handle.canCheck, true);
    });

    testWidgets('Lesson completion flow: Check button enables reactively',
        (WidgetTester tester) async {
      // This test simulates the full lesson flow
      final handle = LessonExerciseHandle();

      // Create a mock translate task
      final task = TranslateTask(
        direction: 'grc→en',
        text: 'λόγος',
        rubric: 'Translate to English',
        sampleSolution: 'word',
      );

      bool checkButtonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TranslateExercise(
                  task: task,
                  ttsEnabled: false,
                  handle: handle,
                ),
                ListenableBuilder(
                  listenable: handle,
                  builder: (context, child) {
                    return FilledButton(
                      onPressed: handle.canCheck
                          ? () {
                              checkButtonPressed = true;
                            }
                          : null,
                      child: const Text('Check'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Initially, Check button should be disabled
      final checkButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Check'),
      );
      expect(checkButton.onPressed, isNull);

      // Enter text
      await tester.enterText(find.byType(TextField), 'word');
      await tester.pump();

      // Now Check button should be enabled
      final enabledCheckButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Check'),
      );
      expect(enabledCheckButton.onPressed, isNotNull);

      // Tap the Check button
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pump();

      expect(checkButtonPressed, true);
    });

    testWidgets('Handle notifies on detach and attach',
        (WidgetTester tester) async {
      final handle = LessonExerciseHandle();
      int notificationCount = 0;
      handle.addListener(() {
        notificationCount++;
      });

      // Attach callbacks
      handle.attach(
        canCheck: () => true,
        check: () => const LessonCheckFeedback(correct: true),
        reset: () {},
      );

      expect(notificationCount, 1); // Should notify on attach

      // Detach callbacks
      handle.detach();

      expect(notificationCount, 2); // Should notify on detach
    });

    testWidgets('ClozeExercise notifies when clearing answers',
        (WidgetTester tester) async {
      final task = ClozeTask(
        text: 'ἐν ἀρχῇ',
        sourceKind: 'daily',
        blanks: [
          Blank(idx: 0, surface: 'ἐν'),
        ],
        options: ['ἐν', 'ὁ'],
      );

      final handle = LessonExerciseHandle();
      int notificationCount = 0;
      handle.addListener(() {
        notificationCount++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClozeExercise(
              task: task,
              onOpenInReader: () {},
              ttsEnabled: false,
              handle: handle,
            ),
          ),
        ),
      );

      // Fill a blank
      final option = find.widgetWithText(FilterChip, 'ἐν');
      await tester.tap(option);
      await tester.pump();

      final countAfterFilling = notificationCount;
      expect(handle.canCheck, true);

      // Clear the answer
      final clearButton = find.byIcon(Icons.close_rounded);
      await tester.tap(clearButton);
      await tester.pump();

      // Should have been notified
      expect(notificationCount, greaterThan(countAfterFilling));
      expect(handle.canCheck, false);
    });
  });
}
