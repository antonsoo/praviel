import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/models/lesson.dart';
import 'package:flutter_reader/widgets/exercises/match_exercise.dart';
import 'package:flutter_reader/widgets/exercises/exercise_control.dart';

/// This test simulates the EXACT user flow from the bug report:
/// User fills in exercise → Check button should enable → User clicks Check
/// → Task result is set → Finish button should enable → User can finish lesson
void main() {
  testWidgets('Complete lesson flow: Match exercise with shuffle/clear', (
    WidgetTester tester,
  ) async {
    final task = MatchTask(
      pairs: [
        MatchPair(grc: 'ἄνθρωπος', en: 'human'),
        MatchPair(grc: 'λόγος', en: 'word'),
      ],
    );

    final handle = LessonExerciseHandle();

    // Simulate parent widget that uses the handle
    bool checkButtonEnabled = false;
    bool finishButtonEnabled = false;
    bool? taskResult;

    Widget buildUI() {
      return MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Expanded(
                child: MatchExercise(task: task, handle: handle),
              ),
              // Check button (like in LessonsPage)
              ListenableBuilder(
                listenable: handle,
                builder: (context, child) {
                  checkButtonEnabled = handle.canCheck;
                  return FilledButton(
                    onPressed: checkButtonEnabled
                        ? () {
                            final feedback = handle.check();
                            if (feedback.correct != null) {
                              taskResult = feedback.correct;
                              // After check, finish button should enable
                            }
                          }
                        : null,
                    child: const Text('Check'),
                  );
                },
              ),
              // Finish button (only enables after task result is set)
              Builder(
                builder: (context) {
                  finishButtonEnabled = taskResult != null;
                  return OutlinedButton(
                    onPressed: finishButtonEnabled ? () {} : null,
                    child: const Text('Finish'),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(buildUI());

    // 1. Initially, Check button should be disabled
    expect(checkButtonEnabled, false);
    expect(finishButtonEnabled, false);

    // 2. User matches first pair
    await tester.tap(find.text('ἄνθρωπος'));
    await tester.pumpAndSettle();
    expect(checkButtonEnabled, false); // Still disabled (only 1/2 pairs)

    await tester.tap(find.text('human'));
    await tester.pumpAndSettle();
    expect(checkButtonEnabled, false); // Still disabled (only 1/2 pairs)

    // 3. User matches second pair
    await tester.tap(find.text('λόγος'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('word'));
    await tester.pumpAndSettle();

    // 4. Now Check button should be enabled!
    expect(checkButtonEnabled, true);
    expect(finishButtonEnabled, false);

    // 5. User clicks "Shuffle" button to reset
    await tester.tap(find.byIcon(Icons.shuffle));
    await tester.pumpAndSettle();

    // 6. Check button should be disabled again (pairs cleared)
    expect(checkButtonEnabled, false);

    // 7. User re-matches all pairs
    await tester.tap(find.text('ἄνθρωπος'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('human'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('λόγος'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('word'));
    await tester.pumpAndSettle();

    // 8. Check button enabled again
    expect(checkButtonEnabled, true);

    // 9. User clicks Check
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();

    // 10. Task result should be set
    expect(taskResult, isNotNull);

    // 11. Rebuild to update finish button state
    await tester.pumpWidget(buildUI());
    await tester.pumpAndSettle();

    // 12. Finish button should now be enabled!
    expect(finishButtonEnabled, true);

    // ✅ Complete lesson flow test passed!
    //    - Check button enables when exercise ready
    //    - Check button disables after shuffle/reset
    //    - Check button re-enables when re-completed
    //    - Finish button enables after checking
  });
}
