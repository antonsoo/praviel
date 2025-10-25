import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service for playing background music during reading sessions
class BackgroundMusicService {
  BackgroundMusicService() {
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(0.3); // Default: 30% volume
  }

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentTrack;

  /// Available background music tracks
  /// Add royalty-free music files to assets/audio/music/
  static const List<String> tracks = [
    'assets/audio/music/ambient_classical_1.mp3',
    'assets/audio/music/ambient_classical_2.mp3',
    'assets/audio/music/ambient_classical_3.mp3',
  ];

  /// Whether music is currently playing
  bool get isPlaying => _isPlaying;

  /// Current track being played
  String? get currentTrack => _currentTrack;

  /// Play background music
  /// [trackPath] - Asset path to music file (defaults to first track)
  /// [volume] - Volume level (0.0 to 1.0, default: 0.3)
  Future<void> play({String? trackPath, double volume = 0.3}) async {
    try {
      final track = trackPath ?? tracks.first;

      // Stop current playback if any
      if (_isPlaying) {
        await stop();
      }

      // Set volume and play
      await _player.setVolume(volume);
      await _player.play(AssetSource(track));

      _isPlaying = true;
      _currentTrack = track;

      if (kDebugMode) {
        print('Background music started: $track at ${(volume * 100).toInt()}% volume');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play background music: $e');
      }
      _isPlaying = false;
      _currentTrack = null;
    }
  }

  /// Stop background music
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentTrack = null;

      if (kDebugMode) {
        print('Background music stopped');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to stop background music: $e');
      }
    }
  }

  /// Pause background music
  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;

      if (kDebugMode) {
        print('Background music paused');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to pause background music: $e');
      }
    }
  }

  /// Resume paused music
  Future<void> resume() async {
    try {
      await _player.resume();
      _isPlaying = true;

      if (kDebugMode) {
        print('Background music resumed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to resume background music: $e');
      }
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _player.setVolume(volume.clamp(0.0, 1.0));

      if (kDebugMode) {
        print('Background music volume: ${(volume * 100).toInt()}%');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to set volume: $e');
      }
    }
  }

  /// Clean up resources
  void dispose() {
    _player.dispose();
  }
}
