import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ancient_languages_app/models/lesson.dart';
import 'package:ancient_languages_app/widgets/exercises/translate_exercise.dart';
import 'package:ancient_languages_app/widgets/exercises/match_exercise.dart';
import 'package:ancient_languages_app/widgets/exercises/alphabet_exercise.dart';
import 'package:ancient_languages_app/widgets/exercises/cloze_exercise.dart';
import 'package:ancient_languages_app/widgets/exercises/exercise_control.dart';

void main() {
  group('Reset Button Tests', () {
    testWidgets('TranslateExercise Clear button notifies handle', (
      WidgetTester tester,
    ) async {
      final task = TranslateTask(
        direction: 'grc→en',
        text: 'λόγος',
        rubric: 'Translate to English',
        sampleSolution: 'word',
      );

      final handle = LessonExerciseHandle();
      int notificationCount = 0;
      handle.addListener(() {
        notificationCount++;
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

      // Enter text - this should notify
      await tester.enterText(find.byType(TextField), 'word');
      await tester.pump();

      expect(handle.canCheck, true);
      final notificationsAfterTyping = notificationCount;
      expect(notificationsAfterTyping, greaterThan(0));

      // Click Clear button - this should notify too
      await tester.tap(find.text('Clear'));
      await tester.pump();

      // Should have been notified again
      expect(notificationCount, greaterThan(notificationsAfterTyping));
      // canCheck should now be false
      expect(handle.canCheck, false);
    });

    testWidgets('MatchExercise Shuffle button should notify handle', (
      WidgetTester tester,
    ) async {
      final task = MatchTask(
        pairs: [
          MatchPair(native: 'ἄνθρωπος', en: 'human'),
          MatchPair(native: 'λόγος', en: 'word'),
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
            body: MatchExercise(task: task, handle: handle),
          ),
        ),
      );

      // Match all pairs
      await tester.tap(find.text('ἄνθρωπος'));
      await tester.pump();
      await tester.tap(find.text('human'));
      await tester.pump();
      await tester.tap(find.text('λόγος'));
      await tester.pump();
      await tester.tap(find.text('word'));
      await tester.pump();

      expect(handle.canCheck, true);
      final notificationsBeforeShuffle = notificationCount;

      // Click Shuffle button - this should notify
      final shuffleButton = find.byIcon(Icons.shuffle);
      await tester.tap(shuffleButton);
      await tester.pump();

      // Should have been notified
      expect(notificationCount, greaterThan(notificationsBeforeShuffle));
      // canCheck should now be false (all pairs cleared)
      expect(handle.canCheck, false);
    });

    testWidgets('AlphabetExercise reset() should notify handle', (
      WidgetTester tester,
    ) async {
      final task = AlphabetTask(
        prompt: 'Select the sound for α (alpha)',
        answer: 'a',
        options: ['a', 'e', 'o'],
      );

      final handle = LessonExerciseHandle();
      int notificationCount = 0;
      handle.addListener(() {
        notificationCount++;
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

      // Select an option
      await tester.tap(find.text('a'));
      await tester.pump();

      expect(handle.canCheck, true);
      final notificationsAfterSelection = notificationCount;
      expect(notificationsAfterSelection, greaterThan(0));

      // Call reset() - this should notify
      handle.reset();
      await tester.pump();

      // Should have been notified
      expect(notificationCount, greaterThan(notificationsAfterSelection));
      // canCheck should now be false (no selection)
      expect(handle.canCheck, false);
    });

    testWidgets('ClozeExercise reset() should notify handle', (
      WidgetTester tester,
    ) async {
      final task = ClozeTask(
        sourceKind: 'lesson',
        text: 'The __0__ is bright.',
        blanks: [Blank(idx: 0, surface: 'sun')],
        options: ['sun', 'moon', 'star'],
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
              ttsEnabled: false,
              onOpenInReader: () {},
              handle: handle,
            ),
          ),
        ),
      );

      // Select an option to fill the blank
      await tester.tap(find.text('sun'));
      await tester.pump();

      expect(handle.canCheck, true);
      final notificationsAfterFilling = notificationCount;
      expect(notificationsAfterFilling, greaterThan(0));

      // Call reset() - this should notify
      handle.reset();
      await tester.pump();

      // Should have been notified
      expect(notificationCount, greaterThan(notificationsAfterFilling));
      // canCheck should now be false (all answers cleared)
      expect(handle.canCheck, false);
    });
  });
}
