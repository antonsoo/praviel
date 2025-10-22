import 'package:flutter/material.dart';

class LessonCheckFeedback {
  const LessonCheckFeedback({this.correct, this.message, this.hint});

  final bool? correct;
  final String? message;
  final String? hint;
}

class LessonExerciseHandle extends ChangeNotifier {
  LessonExerciseHandle();

  bool Function()? _canCheck;
  LessonCheckFeedback Function()? _check;
  VoidCallback? _reset;

  void attach({
    required bool Function() canCheck,
    required LessonCheckFeedback Function() check,
    required VoidCallback reset,
  }) {
    _canCheck = canCheck;
    _check = check;
    _reset = reset;
    notifyListeners();
  }

  bool get canCheck => _canCheck?.call() ?? false;

  LessonCheckFeedback check() {
    return _check?.call() ??
        const LessonCheckFeedback(
          correct: null,
          message: 'Complete the exercise first.',
        );
  }

  void reset() {
    _reset?.call();
    notifyListeners();
  }

  void detach() {
    _canCheck = null;
    _check = null;
    _reset = null;
    notifyListeners();
  }

  /// Notify listeners that the exercise state has changed.
  /// Should be called by exercises when their state changes in a way that affects canCheck.
  void notify() {
    notifyListeners();
  }
}
