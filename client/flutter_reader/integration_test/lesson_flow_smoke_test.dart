import 'package:web/web.dart' as web;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_reader/localization/strings_lessons_en.dart';
import 'package:flutter_reader/main.dart' as app;
import 'package:flutter_reader/widgets/exercises/alphabet_exercise.dart';
import 'package:flutter_reader/widgets/exercises/cloze_exercise.dart';
import 'package:flutter_reader/widgets/exercises/match_exercise.dart';
import 'package:flutter_reader/widgets/exercises/translate_exercise.dart';

class _TaskPosition {
  const _TaskPosition({required this.current, required this.total});

  final int current;
  final int total;
}

void _configureInitialUrl() {
  web.window.history.replaceState(null, 'Ancient Languages', '/app/?tab=lessons&autogen=1&match=0&translate=0&cloze=0&canon=0&alphabet=1');
}

final List<String> _logBuffer = <String>[];

void _log(String message) {
  _logBuffer.add(message);
  const flag = String.fromEnvironment('INTEGRATION_TEST_VERBOSE');
  if (flag != 'true' && flag != '1') {
    return;
  }
  // ignore: avoid_print
  print('[integration] $message');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 3));
  final previousFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    _log('[FLUTTER ERROR] ${details.exceptionAsString()}');
    final stack = details.stack;
    _log('[FLUTTER STACK]\n$stack');
    previousFlutterError?.call(details);
  };
  final previousReporter = reportTestException;
  reportTestException = (details, testDescription) {
    _log('[EXCEPTION] $testDescription -> ${details.exceptionAsString()}');
    final stack = details.stack;
    _log('[STACK]\n$stack');
    previousReporter(details, testDescription);
  };
  binding.platformDispatcher.onError = (error, stack) {
    _log('[ZONE ERROR] ${error.toString()}');
    _log('[ZONE STACK]\n$stack');
    return false;
  };
  tearDownAll(() {
    final failures = binding.failureMethodsDetails;
    final report = <String, Object?>{};
    if (_logBuffer.isNotEmpty) {
      report['logs'] = List<String>.from(_logBuffer);
    }
    if (failures.isNotEmpty) {
      report['failures'] = failures
          .map((failure) => <String, Object?>{
                'method': failure.methodName,
                'details': failure.details,
              })
          .toList();
    }
    if (report.isNotEmpty) {
      binding.reportData = report;
    }
    for (final failure in failures) {
      final details = failure.details;
      if (details != null && details.isNotEmpty) {
        _log('[FAILURE_DETAIL] $details');
      }
    }
  });
  _log('binding initialized');
  if (kIsWeb) {
    _configureInitialUrl();
  }

  testWidgets('lesson flow smoke test', (tester) async {
    _log('starting app');
    await app.main();
    await tester.pumpAndSettle();
    _log('initial pump complete');

    if (kIsWeb) {
      await binding.convertFlutterSurfaceToImage();
    }
    _log('snapshot demo_home');
    await binding.takeScreenshot('demo_home');

    await _openLessonsTab(tester);
    await _triggerGeneration(tester);
    await _runLessonFlow(tester);
    await tester.pumpAndSettle();
    _log('snapshot demo_lesson');
    await binding.takeScreenshot('demo_lesson');
  });
}

Future<void> _openLessonsTab(WidgetTester tester) async {
  final lessonsLabel = find.text(L10nLessons.tabTitle);
  if (lessonsLabel.evaluate().isNotEmpty) {
    await tester.ensureVisible(lessonsLabel.last);
    await tester.tap(lessonsLabel.last);
    await tester.pumpAndSettle();
  } else {
    await tester.pumpAndSettle();
  }
}

Future<void> _triggerGeneration(WidgetTester tester) async {
  final taskFinder = find.textContaining('Task ');
  if (taskFinder.evaluate().isNotEmpty) {
    return;
  }
  final buttonFinder = find.widgetWithText(FilledButton, L10nLessons.generate);
  if (buttonFinder.evaluate().isNotEmpty) {
    await tester.tap(buttonFinder);
    await tester.pump();
  }
  await _pumpUntil(tester, taskFinder);
}

Future<void> _runLessonFlow(WidgetTester tester) async {
  final taskPattern = RegExp(r'^Task\s+(\d+)\s+of\s+(\d+)');
  var loopCount = 0;
  while (true) {
    loopCount += 1;
    await tester.pumpAndSettle();
    final position = _currentTaskPosition(tester, taskPattern);
    _log('task loop $loopCount -> ${position.current}/${position.total}');

    await _prepareCurrentExercise(tester);
    await _tapCheck(tester);

    final isLast = position.current >= position.total;
    final nextLabel = isLast ? L10nLessons.finish : L10nLessons.next;
    final nextFinder = find.widgetWithText(OutlinedButton, nextLabel);
    expect(nextFinder, findsOneWidget);
    _log('tap $nextLabel');
    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    if (isLast) {
      break;
    }
  }
}

_TaskPosition _currentTaskPosition(WidgetTester tester, RegExp pattern) {
  for (final element in find.byType(Text).evaluate()) {
    final widget = element.widget as Text;
    final data = widget.data;
    if (data == null) {
      continue;
    }
    final match = pattern.firstMatch(data);
    if (match != null) {
      return _TaskPosition(
        current: int.parse(match.group(1)! ),
        total: int.parse(match.group(2)! ),
      );
    }
  }
  fail('Task header not found');
}

Future<void> _prepareCurrentExercise(WidgetTester tester) async {
  final alphabet = find.byType(AlphabetExercise);
  if (alphabet.evaluate().isNotEmpty) {
    await _completeAlphabetExercise(tester, alphabet);
    return;
  }
  final match = find.byType(MatchExercise);
  if (match.evaluate().isNotEmpty) {
    await _completeMatchExercise(tester, match);
    return;
  }
  final cloze = find.byType(ClozeExercise);
  if (cloze.evaluate().isNotEmpty) {
    await _completeClozeExercise(tester, cloze);
    return;
  }
  final translate = find.byType(TranslateExercise);
  if (translate.evaluate().isNotEmpty) {
    await _completeTranslateExercise(tester, translate);
    return;
  }
  fail('Unsupported exercise encountered in smoke test');
}

Future<void> _completeAlphabetExercise(WidgetTester tester, Finder exercise) async {
  final choiceFinder = find.descendant(of: exercise, matching: find.byType(ChoiceChip)).first;
  await tester.tap(choiceFinder);
  await tester.pumpAndSettle();
}

Future<void> _completeMatchExercise(WidgetTester tester, Finder exercise) async {
  final listViews = find.descendant(of: exercise, matching: find.byType(ListView));
  final listCount = listViews.evaluate().length;
  expect(listCount, greaterThanOrEqualTo(2));
  final leftList = listViews.at(0);
  final rightList = listViews.at(1);

  final leftTiles = find.descendant(of: leftList, matching: find.byType(ListTile));
  final rightTiles = find.descendant(of: rightList, matching: find.byType(ListTile));
  final pairCount = leftTiles.evaluate().length;
  expect(pairCount, greaterThan(0));

  final usedRight = <int>{};
  for (var leftIndex = 0; leftIndex < pairCount; leftIndex++) {
    final leftTile = leftTiles.at(leftIndex);
    await tester.tap(leftTile);
    await tester.pumpAndSettle();

    final rightTotal = rightTiles.evaluate().length;
    var paired = false;
    for (var rightIndex = 0; rightIndex < rightTotal; rightIndex++) {
      if (usedRight.contains(rightIndex)) {
        continue;
      }
      final candidate = rightTiles.at(rightIndex);
      final tile = tester.widget<ListTile>(candidate);
      if (tile.onTap == null) {
        continue;
      }
      await tester.tap(candidate);
      await tester.pumpAndSettle();
      usedRight.add(rightIndex);
      paired = true;
      break;
    }
    if (!paired) {
      final fallback = rightTiles.first;
      await tester.tap(fallback);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _completeClozeExercise(WidgetTester tester, Finder exercise) async {
  final blankFinder = find.descendant(of: exercise, matching: find.byType(InputChip));
  final optionFinder = find.descendant(of: exercise, matching: find.byType(FilterChip));
  final blankCount = blankFinder.evaluate().length;
  expect(blankCount, greaterThan(0));
  final usedOptions = <String>{};

  for (var index = 0; index < blankCount; index++) {
    final blank = blankFinder.at(index);
    await tester.tap(blank);
    await tester.pumpAndSettle();

    final optionElements = optionFinder.evaluate().toList();
    String? selected;
    Finder? selectedFinder;
    for (var optionIndex = 0; optionIndex < optionElements.length; optionIndex++) {
      final candidate = optionFinder.at(optionIndex);
      final chip = tester.widget<FilterChip>(candidate);
      final labelWidget = chip.label;
      if (labelWidget is! Text) {
        continue;
      }
      final label = labelWidget.data ?? '';
      if (usedOptions.contains(label)) {
        continue;
      }
      selected = label;
      selectedFinder = candidate;
      break;
    }
    selectedFinder ??= optionFinder.first;
    await tester.tap(selectedFinder);
    await tester.pumpAndSettle();
    if (selected != null) {
      usedOptions.add(selected);
    }
  }
}

Future<void> _completeTranslateExercise(WidgetTester tester, Finder exercise) async {
  final fieldFinder = find.descendant(of: exercise, matching: find.byType(TextField)).first;
  await tester.enterText(fieldFinder, 'Integration smoke translation');
  await tester.pumpAndSettle();
}

Future<void> _tapCheck(WidgetTester tester) async {
  final checkFinder = find.widgetWithText(FilledButton, L10nLessons.check);
  expect(checkFinder, findsOneWidget);
  await tester.tap(checkFinder);
  await tester.pumpAndSettle();
}

Future<void> _pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
  final endTime = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for ${finder.toString()}');
}
