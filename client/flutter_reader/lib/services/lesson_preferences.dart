import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final lessonPreferencesProvider =
    AsyncNotifierProvider<LessonPreferences, LessonPreferencesState>(
      LessonPreferences.new,
    );

class LessonPreferencesState {
  const LessonPreferencesState({this.register = 'literary'});

  final String register;

  LessonPreferencesState copyWith({String? register}) {
    return LessonPreferencesState(register: register ?? this.register);
  }
}

class LessonPreferences extends AsyncNotifier<LessonPreferencesState> {
  static const _registerKey = 'lesson_register';

  @override
  Future<LessonPreferencesState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final register = prefs.getString(_registerKey) ?? 'literary';
    return LessonPreferencesState(register: register);
  }

  Future<void> setRegister(String register) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registerKey, register);
    state = AsyncValue.data(
      (state.value ?? const LessonPreferencesState()).copyWith(
        register: register,
      ),
    );
  }
}
