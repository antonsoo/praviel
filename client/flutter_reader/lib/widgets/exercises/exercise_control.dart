import 'package:flutter/material.dart';

class LessonCheckFeedback {
  const LessonCheckFeedback({this.correct, this.message});

  final bool? correct;
  final String? message;
}

class LessonExerciseHandle {
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
  }

  void detach() {
    _canCheck = null;
    _check = null;
    _reset = null;
  }
}
