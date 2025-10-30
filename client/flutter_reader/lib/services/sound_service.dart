import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Sound effects for enhancing user experience.
/// All sounds are optional and can be disabled in settings.
class SoundService {
  SoundService._() {
    _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  }

  static final SoundService _instance = SoundService._();
  static SoundService get instance => _instance;

  late final AudioPlayer _player;
  bool _enabled = true;
  double _volume = 0.3; // Default low volume

  static const Map<String, String> _soundPalette = {
    'tap': 'tap.wav',
    'button': 'tap.wav',
    'success': 'success.wav',
    'error': 'error.wav',
    'xp_gain': 'success.wav',
    'level_up': 'success.wav',
    'streak_milestone': 'whoosh.wav',
    'swipe': 'whoosh.wav',
    'transition': 'whoosh.wav',
    'achievement': 'success.wav',
    'celebration': 'success.wav',
    'combo_low': 'tap.wav',
    'combo_mid': 'success.wav',
    'combo_high': 'whoosh.wav',
    'power_up': 'whoosh.wav',
    'badge_unlock': 'success.wav',
    'tick': 'tap.wav',
    'confetti': 'success.wav',
    'sparkle': 'whoosh.wav',
    'locked': 'error.wav',
    'unlock': 'success.wav',
  };

  /// Enable or disable sound effects.
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _player.setVolume(_volume);
  }

  Future<void> _playMapped(String key) async {
    final fileName = _soundPalette[key];
    if (fileName == null) {
      debugPrint('[SoundService] No mapping for sound "$key"');
      return;
    }
    await _playSound(fileName);
  }

  /// Play a sound file from assets
  Future<void> _playSound(String fileName) async {
    if (!_enabled) return;
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      debugPrint('[SoundService] Error playing $fileName: $e');
      await _playSystemSound();
    }
  }

  Future<void> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('[SoundService] Error playing system sound: $e');
    }
  }

  Future<void> tap() async => _playMapped('tap');
  Future<void> button() async => _playMapped('button');
  Future<void> success() async => _playMapped('success');
  Future<void> error() async => _playMapped('error');
  Future<void> xpGain() async => _playMapped('xp_gain');
  Future<void> levelUp() async => _playMapped('level_up');
  Future<void> streakMilestone() async => _playMapped('streak_milestone');
  Future<void> swipe() async => _playMapped('swipe');
  Future<void> transition() async => _playMapped('transition');
  Future<void> achievement() async => _playMapped('achievement');
  Future<void> celebration() async => _playMapped('celebration');

  Future<void> combo(int level) async {
    if (level >= 10) {
      await _playMapped('combo_high');
    } else if (level >= 5) {
      await _playMapped('combo_mid');
    } else {
      await _playMapped('combo_low');
    }
  }

  Future<void> powerUpActivate() async => _playMapped('power_up');
  Future<void> badgeUnlock() async => _playMapped('badge_unlock');

  Future<void> tick() async {
    if (_volume < 0.05) return;
    await _playMapped('tick');
  }

  Future<void> confetti() async => _playMapped('confetti');
  Future<void> whoosh() async => _playSound('whoosh.wav');
  Future<void> sparkle() async => _playMapped('sparkle');
  Future<void> locked() async => _playMapped('locked');
  Future<void> unlock() async => _playMapped('unlock');

  void dispose() {
    _player.dispose();
  }
}

extension SoundExtension on BuildContext {
  SoundService get sounds => SoundService.instance;
}
