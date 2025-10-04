import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeControllerProvider =
    AsyncNotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

class ThemeController extends AsyncNotifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  @override
  Future<ThemeMode> build() async {
    final stored = await _storage.read(key: _key);
    if (stored != null) {
      switch (stored) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
          return ThemeMode.system;
      }
    }
    return ThemeMode.light;
  }

  Future<void> setTheme(ThemeMode mode) async {
    await _storage.write(key: _key, value: mode.name);
    state = AsyncValue.data(mode);
  }

  Future<void> toggleTheme() async {
    final currentMode = state.value ?? ThemeMode.light;
    final newMode = currentMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setTheme(newMode);
  }
}
