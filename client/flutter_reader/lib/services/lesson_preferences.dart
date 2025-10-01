import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final lessonPreferencesProvider =
    AsyncNotifierProvider<LessonPreferences, LessonPreferencesState>(
  LessonPreferences.new,
);

class LessonPreferencesState {
  const LessonPreferencesState({
    this.register = 'literary',
  });

  final String register;

  LessonPreferencesState copyWith({String? register}) {
    return LessonPreferencesState(
      register: register ?? this.register,
    );
  }
}

class LessonPreferences extends AsyncNotifier<LessonPreferencesState> {
  static const _storage = FlutterSecureStorage();
  static const _registerKey = 'lesson_register';

  @override
  Future<LessonPreferencesState> build() async {
    final register = await _storage.read(key: _registerKey) ?? 'literary';
    return LessonPreferencesState(register: register);
  }

  Future<void> setRegister(String register) async {
    await _storage.write(key: _registerKey, value: register);
    state = AsyncValue.data(
      (state.value ?? const LessonPreferencesState()).copyWith(register: register),
    );
  }
}
