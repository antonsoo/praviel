import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing background music and sound effects
/// Automatically discovers and plays all music files in language folders
class MusicService extends ChangeNotifier {
  static final MusicService instance = MusicService._();

  MusicService._();

  final AudioPlayer _musicPlayer = AudioPlayer();

  bool _musicEnabled = false;
  bool _sfxEnabled = true; // Sound effects enabled by default
  bool _muteAll = false;
  double _musicVolume = 0.3; // 30% volume by default
  double _sfxVolume = 0.5; // 50% volume by default
  bool _shuffle = true; // Shuffle by default

  String? _currentTrack;
  String? _currentLanguage;
  List<String> _currentPlaylist = [];
  int _currentTrackIndex = 0;
  int _failedAttempts = 0;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get muteAll => _muteAll;
  double get musicVolume => _musicVolume;
  double get sfxVolume => _sfxVolume;
  String? get currentTrack => _currentTrack;
  String? get currentLanguage => _currentLanguage;
  bool get shuffle => _shuffle;
  List<String> get playlist => List.unmodifiable(_currentPlaylist);
  int get currentTrackIndex => _currentTrackIndex;

  /// Initialize and load preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _musicEnabled = prefs.getBool('music_enabled') ?? false;
    _sfxEnabled = prefs.getBool('sfx_enabled') ?? true;
    _muteAll = prefs.getBool('mute_all') ?? false;
    _musicVolume = prefs.getDouble('music_volume') ?? 0.3;
    _sfxVolume = prefs.getDouble('sfx_volume') ?? 0.5;
    _shuffle = prefs.getBool('music_shuffle') ?? true;

    // Set up player to notify when track completes so we can play next
    _musicPlayer.onPlayerComplete.listen((_) {
      _playNextTrack();
    });

    notifyListeners();
  }

  /// Toggle background music on/off
  Future<void> toggleMusic() async {
    _musicEnabled = !_musicEnabled;
    if (_musicEnabled) {
      _failedAttempts = 0;
    }

    if (_musicEnabled && _currentLanguage != null) {
      // Restart music for current language
      await playMusicForLanguage(languageCode: _currentLanguage!);
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
      await _musicPlayer.setVolume(0);
    } else {
      await _musicPlayer.setVolume(_musicVolume);
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

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_shuffle', _shuffle);

    // If shuffle was just enabled and we have a playlist, reshuffle it
    if (_shuffle && _currentPlaylist.isNotEmpty) {
      final currentTrack = _currentPlaylist[_currentTrackIndex];
      _currentPlaylist.shuffle(math.Random());
      // Keep current track at current position
      _currentTrackIndex = _currentPlaylist.indexOf(currentTrack);
    }

    notifyListeners();
  }

  /// Discover all music files in a language directory
  /// Scans the asset manifest for music files (mp3, flac, ogg, wav, m4a)
  Future<List<String>> _discoverMusicFiles(String languageCode) async {
    try {
      // Load the asset manifest
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifest = json.decode(manifestJson);

      // Filter for music files in the language directory
      final musicPrefix = 'assets/music/$languageCode/';
      final musicExtensions = ['.mp3', '.flac', '.ogg', '.wav', '.m4a'];

      final tracks = manifest.keys
          .where((key) => key.startsWith(musicPrefix))
          .where(
            (key) =>
                musicExtensions.any((ext) => key.toLowerCase().endsWith(ext)),
          )
          .map(
            (key) => key.replaceFirst('assets/', ''),
          ) // Remove 'assets/' prefix for AssetSource
          .toList();

      debugPrint(
        '📀 Discovered ${tracks.length} music tracks for $languageCode',
      );
      if (tracks.isNotEmpty) {
        debugPrint(
          '   Tracks: ${tracks.map((t) => t.split('/').last).join(', ')}',
        );
      }

      return tracks;
    } catch (e) {
      debugPrint('❌ Error discovering music files for $languageCode: $e');
      return [];
    }
  }

  /// Play background music for a specific language
  /// Automatically discovers and plays all music files in the language folder as a playlist
  Future<void> playMusicForLanguage({required String languageCode}) async {
    // Always remember the active language so we can resume when music is toggled on.
    _currentLanguage = languageCode;

    if (_muteAll || !_musicEnabled) {
      debugPrint('🔇 Music is disabled or muted');
      return;
    }

    // If already playing this language with a valid playlist, don't restart
    if (_currentLanguage == languageCode &&
        _musicPlayer.state == PlayerState.playing &&
        _currentPlaylist.isNotEmpty) {
      debugPrint('🎵 Already playing music for $languageCode');
      return;
    }

    debugPrint('🎼 Loading music for language: $languageCode');

    // Discover music files for this language
    _currentPlaylist = await _discoverMusicFiles(languageCode);

    if (_currentPlaylist.isEmpty) {
      debugPrint('⚠️  No music files found for language: $languageCode');
      debugPrint('   📁 Expected location: assets/music/$languageCode/');
      debugPrint('   📝 Supported formats: .mp3, .flac, .ogg, .wav, .m4a');
      _currentTrack = null;
      notifyListeners();
      return;
    }

    debugPrint('✅ Found ${_currentPlaylist.length} track(s) for $languageCode');

    // Shuffle playlist if enabled
    if (_shuffle) {
      _currentPlaylist.shuffle(math.Random());
      debugPrint('🔀 Shuffled playlist');
    }

    _failedAttempts = 0;

    // Start playing first track
    _currentTrackIndex = 0;
    await _playTrackAtIndex(_currentTrackIndex);
  }

  /// Play a specific track from the current playlist
  Future<void> _playTrackAtIndex(int index) async {
    if (index < 0 || index >= _currentPlaylist.length) {
      debugPrint('❌ Invalid track index: $index');
      return;
    }

    _currentTrackIndex = index;
    final trackPath = _currentPlaylist[index];

    try {
      await _musicPlayer.stop();
      await _musicPlayer.setSource(AssetSource(trackPath));
      await _musicPlayer.setVolume(_muteAll ? 0 : _musicVolume);
      await _musicPlayer.resume();

      _currentTrack = trackPath;
      _failedAttempts = 0;
      notifyListeners();

      final trackName = trackPath.split('/').last;
      debugPrint(
        '🎵 Now playing [$_currentTrackIndex/${_currentPlaylist.length}]: $trackName',
      );
    } catch (e) {
      debugPrint('❌ Failed to play track $trackPath: $e');
      if (await _handlePlaybackFailure(e)) {
        return;
      }

      // Try next track if this one fails
      await _playNextTrack();
    }
  }

  /// Play next track in playlist
  Future<void> _playNextTrack() async {
    if (_currentPlaylist.isEmpty) return;

    _currentTrackIndex = (_currentTrackIndex + 1) % _currentPlaylist.length;

    // If we've looped back to the beginning and shuffle is on, reshuffle
    if (_currentTrackIndex == 0 && _shuffle && _currentPlaylist.length > 1) {
      final firstTrack =
          _currentPlaylist[0]; // Remember first track to avoid repeat
      _currentPlaylist.shuffle(math.Random());
      // Make sure we don't immediately replay the same track
      if (_currentPlaylist[0] == firstTrack && _currentPlaylist.length > 1) {
        _currentPlaylist.removeAt(0);
        _currentPlaylist.add(firstTrack);
      }
      debugPrint('🔀 Reshuffled playlist for next loop');
    }

    await _playTrackAtIndex(_currentTrackIndex);
  }

  /// Skip to next track manually
  Future<void> skipToNextTrack() async {
    if (_currentPlaylist.isEmpty) {
      debugPrint('⚠️  No playlist to skip');
      return;
    }
    debugPrint('⏭️  Skipping to next track');
    _failedAttempts = 0;
    await _playNextTrack();
  }

  /// Skip to previous track manually
  Future<void> skipToPreviousTrack() async {
    if (_currentPlaylist.isEmpty) {
      debugPrint('⚠️  No playlist to skip');
      return;
    }

    _currentTrackIndex = (_currentTrackIndex - 1);
    if (_currentTrackIndex < 0) {
      _currentTrackIndex = _currentPlaylist.length - 1;
    }

    debugPrint('⏮️  Skipping to previous track');
    _failedAttempts = 0;
    await _playTrackAtIndex(_currentTrackIndex);
  }

  /// Stop background music
  Future<void> stopMusic() async {
    debugPrint('⏹️  Stopping music');
    await _musicPlayer.stop();
    _currentTrack = null;
    _currentLanguage = null;
    _currentPlaylist = [];
    _currentTrackIndex = 0;
    _failedAttempts = 0;
    notifyListeners();
  }

  Future<void> _pauseMusic() async {
    await _musicPlayer.pause();
  }

  /// Get friendly track name (without path and extension)
  String? get currentTrackName {
    if (_currentTrack == null) return null;
    final fileName = _currentTrack!.split('/').last;
    return fileName.replaceAll(RegExp(r'\.(mp3|flac|ogg|wav|m4a)$'), '');
  }

  /// Clean up resources
  @override
  void dispose() {
    unawaited(_musicPlayer.dispose());
    super.dispose();
  }

  Future<bool> _handlePlaybackFailure(Object error) async {
    if (_isAutoplayRestriction(error)) {
      debugPrint(
        '🔒 Browser blocked autoplay for background music. Disabling until the user re-enables music.',
      );
      _musicEnabled = false;
      _failedAttempts = 0;
      await _persistMusicEnabled(false);
      await _musicPlayer.stop();
      _currentTrack = null;
      notifyListeners();
      return true;
    }

    _failedAttempts++;
    if (_failedAttempts >=
        (_currentPlaylist.isEmpty ? 1 : _currentPlaylist.length)) {
      debugPrint(
        '⚠️  All tracks failed to play. Stopping background music to avoid repeated retries.',
      );
      await _musicPlayer.stop();
      _currentTrack = null;
      notifyListeners();
      return true;
    }

    return false;
  }

  bool _isAutoplayRestriction(Object error) {
    if (!kIsWeb) {
      return false;
    }
    final message = error.toString().toLowerCase();
    return message.contains('notallowed') ||
        message.contains('not allowed') ||
        message.contains('without user interaction') ||
        message.contains('user gesture') ||
        message.contains('interact with the document first');
  }

  Future<void> _persistMusicEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('music_enabled', value);
    } catch (e) {
      debugPrint('⚠️  Failed to persist music enabled state: $e');
    }
  }
}
