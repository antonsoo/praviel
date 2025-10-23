import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing background music and sound effects
class MusicService extends ChangeNotifier {
  static final MusicService instance = MusicService._();

  MusicService._();

  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _musicEnabled = false;
  bool _sfxEnabled = true; // Sound effects enabled by default
  bool _muteAll = false;
  double _musicVolume = 0.3; // 30% volume by default
  double _sfxVolume = 0.5; // 50% volume by default

  String? _currentTrack;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get muteAll => _muteAll;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  String? get currentTrack => _currentTrack;

  /// Initialize and load preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _musicEnabled = prefs.getBool('music_enabled') ?? false;
    _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    _muteAll = prefs.getBool('mute_all') ?? false;
    _musicVolume = prefs.getDouble('music_volume') ?? 0.3;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.5;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    notifyListeners();
  }

  /// Toggle background music on/off
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;

    if (_musicEnabled && _currentTrack != null) {
      await _resumeMusic();
    } else {
      await _pauseMusic();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _musicEnabled);
    notifyListeners();
  }

  /// Toggle sound effects on/off
  Future<void> toggleSfx() async {
    _sfxEnabled = !_sfxEnabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_enabled', _sfxEnabled);
    notifyListeners();
  }

  /// Toggle mute all sounds
  Future<void> toggleMuteAll() async {
    _muteAll = !_muteAll;

    if (_muteAll) {
      await _pauseMusic();
    } else if (_musicEnabled && _currentTrack != null) {
      await _resumeMusic();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('mute_all', _muteAll);
    notifyListeners();
  }

  /// Set music volume (0.0 to 1.0)
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);

    if (!_muteAll) {
      await _musicPlayer.setVolume(_musicVolume);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _musicVolume);
    notifyListeners();
  }

  /// Set sound effects volume (0.0 to 1.0)
  Future<void> setSfxVolume(double volume) async {
    _sfxVolume = volume.clamp(0.0, 1.0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sfx_volume', _sfxVolume);
    notifyListeners();
  }

  /// Play background music for a specific language
  /// Track will be loaded from assets/music/{languageCode}/{trackName}.mp3
  Future<void> playMusicForLanguage({
    required String languageCode,
    String trackName = 'background_1',
  }) async {
    if (_muteAll || !_musicEnabled) return;

    final newTrack = 'music/$languageCode/$trackName.mp3';

    // Don't restart if already playing this track
    if (_currentTrack == newTrack && _musicPlayer.state == PlayerState.playing) {
      return;
    }

    _currentTrack = newTrack;

    try {
      await _musicPlayer.stop();
      await _musicPlayer.setSource(AssetSource(_currentTrack!));
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.resume();
      notifyListeners();
    } catch (e) {
      // Music file doesn't exist yet - that's okay, user will add them later
      debugPrint('Background music not found: $_currentTrack');
    }
  }

  /// Stop background music
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
    _currentTrack = null;
    notifyListeners();
  }

  Future<void> _pauseMusic() async {
    await _musicPlayer.pause();
  }

  Future<void> _resumeMusic() async {
    if (!_muteAll && _currentTrack != null) {
      await _musicPlayer.resume();
    }
  }

  /// Clean up resources
  @override
  Future<void> dispose() async {
    await _musicPlayer.dispose();
    super.dispose();
  }
}
