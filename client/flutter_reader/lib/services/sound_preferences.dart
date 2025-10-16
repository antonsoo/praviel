import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sound_service.dart';

final soundPreferencesProvider =
    AsyncNotifierProvider<SoundPreferences, SoundPreferencesState>(
  SoundPreferences.new,
);

class SoundPreferencesState {
  const SoundPreferencesState({
    this.enabled = true,
    this.volume = 0.3,
  });

  final bool enabled;
  final double volume;

  SoundPreferencesState copyWith({
    bool? enabled,
    double? volume,
  }) {
    return SoundPreferencesState(
      enabled: enabled ?? this.enabled,
      volume: volume ?? this.volume,
    );
  }
}

class SoundPreferences extends AsyncNotifier<SoundPreferencesState> {
  static const _enabledKey = 'sound_effects_enabled';
  static const _volumeKey = 'sound_effects_volume';

  @override
  Future<SoundPreferencesState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? true;
    final volume = prefs.getDouble(_volumeKey) ?? 0.3;

    // Apply preferences to SoundService
    SoundService.instance.setEnabled(enabled);
    SoundService.instance.setVolume(volume);

    return SoundPreferencesState(
      enabled: enabled,
      volume: volume,
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    // Update SoundService
    SoundService.instance.setEnabled(enabled);

    state = AsyncValue.data(
      (state.value ?? const SoundPreferencesState()).copyWith(
        enabled: enabled,
      ),
    );
  }

  Future<void> setVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, clampedVolume);

    // Update SoundService
    SoundService.instance.setVolume(clampedVolume);

    state = AsyncValue.data(
      (state.value ?? const SoundPreferencesState()).copyWith(
        volume: clampedVolume,
      ),
    );
  }

  Future<void> toggleEnabled() async {
    final currentEnabled = state.value?.enabled ?? true;
    await setEnabled(!currentEnabled);
  }
}
