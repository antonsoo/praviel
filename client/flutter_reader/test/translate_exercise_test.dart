import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/models/lesson.dart';
import 'package:flutter_reader/widgets/exercises/translate_exercise.dart';
import 'package:flutter_reader/widgets/exercises/exercise_control.dart';

void main() {
  group('TranslateExercise comprehensive tests', () {
    testWidgets('Check returns null when text field is empty', (
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

      // Check without entering text
      final feedback = handle.check();

      expect(feedback.correct, isNull);
      expect(feedback.message, 'Write a draft translation first.');
    });

    testWidgets('Check returns correct:true when text is entered', (
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

      // Enter text
      await tester.enterText(find.byType(TextField), 'water');
      await tester.pump();

      // Check
      final feedback = handle.check();

      expect(feedback.correct, true);
      expect(feedback.message, contains('Nice work'));
      expect(feedback.message, contains('Show solution'));
    });

    testWidgets('Check returns correct message when no sample exists', (
      WidgetTester tester,
    ) async {
      final task = TranslateTask(
        direction: 'grc→en',
        text: 'ὕδωρ',
        rubric: 'Translate to English',
        sampleSolution: null, // No sample
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

      // Enter text
      await tester.enterText(find.byType(TextField), 'water');
      await tester.pump();

      // Check
      final feedback = handle.check();

      expect(feedback.correct, true);
      expect(feedback.message, 'Nice work—reflect on tone and accuracy.');
    });

    testWidgets('Show solution button toggles visibility', (
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

      // Show solution button should be visible initially
      expect(find.text('Show solution'), findsOneWidget);
      expect(find.text('water'), findsNothing);

      // Tap Show solution button
      await tester.tap(find.text('Show solution'));
      await tester.pump();

      // Solution should now be visible
      expect(find.text('Hide solution'), findsOneWidget);
      expect(find.text('water'), findsOneWidget);

      // Tap Hide solution button
      await tester.tap(find.text('Hide solution'));
      await tester.pump();

      // Solution should be hidden again
      expect(find.text('Show solution'), findsOneWidget);
      expect(find.text('water'), findsNothing);
    });

    testWidgets('Clear button resets the exercise', (
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

      // Enter text and show solution
      await tester.enterText(find.byType(TextField), 'my answer');
      await tester.pump();
      await tester.tap(find.text('Show solution'));
      await tester.pump();

      expect(find.text('my answer'), findsOneWidget);
      expect(find.text('water'), findsOneWidget);
      expect(handle.canCheck, true);

      // Tap Clear button
      await tester.tap(find.text('Clear'));
      await tester.pump();

      // Text should be cleared
      expect(find.text('my answer'), findsNothing);
      expect(find.text('water'), findsNothing); // Solution hidden
      expect(handle.canCheck, false);
    });

    testWidgets('canCheck is false when text is empty', (
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

      expect(handle.canCheck, false);

      await tester.enterText(find.byType(TextField), 'water');
      await tester.pump();

      expect(handle.canCheck, true);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(handle.canCheck, false);
    });
  });
}
