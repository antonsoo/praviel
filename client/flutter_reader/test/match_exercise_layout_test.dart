import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/models/lesson.dart';
import 'package:flutter_reader/widgets/exercises/match_exercise.dart';
import 'package:flutter_reader/widgets/exercises/exercise_control.dart';

void main() {
  testWidgets('MatchExercise displays two columns side-by-side',
      (WidgetTester tester) async {
    // Create a simple match task with 3 pairs
    final task = MatchTask(
      pairs: [
        MatchPair(grc: 'νῦν', en: 'now'),
        MatchPair(grc: 'εὐχαριστῶ', en: 'thank you'),
        MatchPair(grc: 'ὕδωρ', en: 'water'),
      ],
    );

    final handle = LessonExerciseHandle();

    // Build the widget
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

    // Verify the widget builds without errors
    expect(find.byType(MatchExercise), findsOneWidget);

    // Verify title is shown
    expect(find.text('Match the pairs'), findsOneWidget);

    // Verify instructions are shown
    expect(find.text('Tap a Greek term, then its English partner.'),
        findsOneWidget);

    // Verify all Greek words are present
    expect(find.text('νῦν'), findsOneWidget);
    expect(find.text('εὐχαριστῶ'), findsOneWidget);
    expect(find.text('ὕδωρ'), findsOneWidget);

    // Verify all English words are present
    expect(find.text('now'), findsOneWidget);
    expect(find.text('thank you'), findsOneWidget);
    expect(find.text('water'), findsOneWidget);

    // Verify pair counter
    expect(find.textContaining('Pairs: 0/3'), findsOneWidget);

    // Verify shuffle button
    expect(find.text('Shuffle'), findsOneWidget);
  });

  testWidgets('MatchExercise allows pairing words', (WidgetTester tester) async {
    final task = MatchTask(
      pairs: [
        MatchPair(grc: 'νῦν', en: 'now'),
        MatchPair(grc: 'ὕδωρ', en: 'water'),
      ],
    );

    final handle = LessonExerciseHandle();

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

    // Tap the first Greek word
    await tester.tap(find.text('νῦν'));
    await tester.pump();

    // Tap the corresponding English word
    await tester.tap(find.text('now'));
    await tester.pump();

    // Verify pair counter updated
    expect(find.textContaining('Pairs: 1/2'), findsOneWidget);
  });

  testWidgets('MatchExercise uses Column layout (not GridView)',
      (WidgetTester tester) async {
    final task = MatchTask(
      pairs: [
        MatchPair(grc: 'α', en: 'a'),
        MatchPair(grc: 'β', en: 'b'),
        MatchPair(grc: 'γ', en: 'c'),
      ],
    );

    final handle = LessonExerciseHandle();

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

    // Verify no GridView is present
    expect(find.byType(GridView), findsNothing);

    // Verify Column widgets are present
    // (There should be multiple Column widgets in the tree)
    expect(find.byType(Column), findsWidgets);

    // Verify Row is present (for side-by-side layout)
    expect(find.byType(Row), findsWidgets);
  });
}
