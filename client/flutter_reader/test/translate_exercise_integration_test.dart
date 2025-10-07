import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/models/lesson.dart';
import 'package:flutter_reader/widgets/exercises/translate_exercise.dart';
import 'package:flutter_reader/widgets/exercises/exercise_control.dart';

/// Integration test that simulates the exact flow from LessonsPage
void main() {
  group('TranslateExercise integration test (simulates LessonsPage)', () {
    testWidgets('Full user flow: type answer, check, see feedback', (
      WidgetTester tester,
    ) async {
      final task = TranslateTask(
        direction: 'grc→en',
        text: 'ὕδωρ',
        rubric: 'Translate to English',
        sampleSolution: 'water',
      );

      final handle = LessonExerciseHandle();

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

      // Initially canCheck should be false
      expect(handle.canCheck, false);

      // User types "water"
      await tester.enterText(find.byType(TextField), 'water');
      await tester.pump();

      // Now canCheck should be true
      expect(handle.canCheck, true);

      // User clicks Check (simulated)
      final feedback = handle.check();

      // Verify feedback
      expect(feedback.correct, true);
      expect(feedback.message, contains('Nice work'));
      expect(feedback.message, contains('Show solution'));
    });

    testWidgets('User flow: click Check without typing (empty field)', (
      WidgetTester tester,
    ) async {
      final task = TranslateTask(
        direction: 'grc→en',
        text: 'ὕδωρ',
        rubric: 'Translate to English',
        sampleSolution: 'water',
      );

      final handle = LessonExerciseHandle();

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

      // Initially canCheck should be false
      expect(handle.canCheck, false);

      // Calling check() should return null feedback
      final feedback = handle.check();
      expect(feedback.correct, isNull);
      expect(feedback.message, 'Write a draft translation first.');
    });

    testWidgets('Check button behavior matches other exercises', (
      WidgetTester tester,
    ) async {
      final task = TranslateTask(
        direction: 'grc→en',
        text: 'ὕδωρ',
        rubric: 'Translate to English',
        sampleSolution: 'water',
      );

      final handle = LessonExerciseHandle();
      int notifyCount = 0;

      handle.addListener(() {
        notifyCount++;
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

      // Verify initial state
      expect(handle.canCheck, false);

      // Type text - should notify
      await tester.enterText(find.byType(TextField), 'w');
      await tester.pump();

      expect(notifyCount, greaterThan(0));
      expect(handle.canCheck, true);

      // Check returns success
      final feedback = handle.check();
      expect(feedback.correct, true);

      // Clear should reset
      final resetCount = notifyCount;
      handle.reset();
      await tester.pump();

      expect(notifyCount, greaterThan(resetCount));
      expect(handle.canCheck, false);
    });
  });
}
