import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing audio settings: background music, sound effects, mute all
class AudioSettingsService extends ChangeNotifier {
  AudioSettingsService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const String _keyBackgroundMusic = 'audio_background_music';
  static const String _keySoundEffects = 'audio_sound_effects';
  static const String _keyMuteAll = 'audio_mute_all';

  bool _backgroundMusicEnabled = false;
  bool _soundEffectsEnabled = true;
  bool _muteAll = false;
  bool _isInitialized = false;

  /// Whether background music is enabled
  bool get backgroundMusicEnabled => _backgroundMusicEnabled && !_muteAll;

  /// Whether sound effects are enabled
  bool get soundEffectsEnabled => _soundEffectsEnabled && !_muteAll;

  /// Whether all audio is muted
  bool get muteAll => _muteAll;

  /// Whether service has loaded from storage
  bool get isInitialized => _isInitialized;

  /// Initialize from SharedPreferences
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Use local variable to avoid Flutter 3.35+ null check compiler bug (Issue #175116)
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _backgroundMusicEnabled = prefs.getBool(_keyBackgroundMusic) ?? false;
    _soundEffectsEnabled = prefs.getBool(_keySoundEffects) ?? true;
    _muteAll = prefs.getBool(_keyMuteAll) ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  /// Toggle background music on/off
  Future<void> setBackgroundMusic(bool enabled) async {
    _backgroundMusicEnabled = enabled;
    await _prefs?.setBool(_keyBackgroundMusic, enabled);
    notifyListeners();
  }

  /// Toggle sound effects on/off
  Future<void> setSoundEffects(bool enabled) async {
    _soundEffectsEnabled = enabled;
    await _prefs?.setBool(_keySoundEffects, enabled);
    notifyListeners();
  }

  /// Toggle mute all on/off
  Future<void> setMuteAll(bool muted) async {
    _muteAll = muted;
    await _prefs?.setBool(_keyMuteAll, muted);
    notifyListeners();
  }
}

/// Provider for audio settings service
final audioSettingsServiceProvider = Provider<AudioSettingsService>((ref) {
  return AudioSettingsService();
});

/// Provider for background music enabled state (reactive)
final backgroundMusicEnabledProvider = Provider<bool>((ref) {
  final service = ref.watch(audioSettingsServiceProvider);
  return service.backgroundMusicEnabled;
});

/// Provider for sound effects enabled state (reactive)
final soundEffectsEnabledProvider = Provider<bool>((ref) {
  final service = ref.watch(audioSettingsServiceProvider);
  return service.soundEffectsEnabled;
});

/// Provider for mute all state (reactive)
final muteAllProvider = Provider<bool>((ref) {
  final service = ref.watch(audioSettingsServiceProvider);
  return service.muteAll;
});
