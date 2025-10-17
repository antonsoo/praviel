import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Sound effects for enhancing user experience
/// All sounds are optional and can be disabled in settings
class SoundService {
  SoundService._() {
    _player = AudioPlayer();
    _player.setReleaseMode(ReleaseMode.stop);
  }

  static final SoundService _instance = SoundService._();
  static SoundService get instance => _instance;

  late final AudioPlayer _player;
  bool _enabled = true;
  double _volume = 0.3; // Default low volume

  /// Enable or disable sound effects
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// Set volume (0.0 to 1.0)
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _player.setVolume(_volume);
  }

  /// Play a sound file from assets
  Future<void> _playSound(String fileName) async {
    if (!_enabled) return;
    try {
      await _player.setVolume(_volume);
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // Fallback to system sound if asset not found
      debugPrint(
        '[SoundService] Error playing $fileName: $e. Using system sound.',
      );
      await _playSystemSound();
    }
  }

  /// Fallback to system sound
  Future<void> _playSystemSound() async {
    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (e) {
      debugPrint('[SoundService] Error playing system sound: $e');
    }
  }

  /// Light tap sound
  Future<void> tap() async {
    await _playSound('tap.wav');
  }

  /// Button press sound
  Future<void> button() async {
    await _playSound('button.wav');
  }

  /// Correct answer sound - pleasant chime
  Future<void> success() async {
    await _playSound('success.wav');
  }

  /// Wrong answer sound - gentle buzz
  Future<void> error() async {
    await _playSound('error.wav');
  }

  /// XP gain sound - coin sound
  Future<void> xpGain() async {
    await _playSound('xp_gain.wav');
  }

  /// Level up sound - victory fanfare
  Future<void> levelUp() async {
    await _playSound('level_up.wav');
  }

  /// Streak milestone sound - whoosh + sparkle
  Future<void> streakMilestone() async {
    await _playSound('streak_milestone.wav');
  }

  /// Card swipe sound
  Future<void> swipe() async {
    await _playSound('swipe.wav');
  }

  /// Page transition sound
  Future<void> transition() async {
    await _playSound('whoosh.wav');
  }

  /// Achievement unlocked sound
  Future<void> achievement() async {
    await _playSound('achievement.wav');
  }

  /// Celebration sound for big rewards
  Future<void> celebration() async {
    await _playSound('confetti.wav');
  }

  /// Combo sound - escalates with combo level
  Future<void> combo(int level) async {
    if (level >= 10) {
      await _playSound('combo_3.wav');
    } else if (level >= 5) {
      await _playSound('combo_2.wav');
    } else {
      await _playSound('combo_1.wav');
    }
  }

  /// Power-up activation sound - magical woosh
  Future<void> powerUpActivate() async {
    await _playSound('power_up.wav');
  }

  /// Badge unlock sound - ta-da!
  Future<void> badgeUnlock() async {
    await _playSound('badge_unlock.wav');
  }

  /// Tick sound for counters
  Future<void> tick() async {
    if (_volume < 0.1) return;
    await _playSound('tick.wav');
  }

  /// Confetti pop sound
  Future<void> confetti() async {
    await _playSound('confetti.wav');
  }

  /// Whoosh sound for fast transitions
  Future<void> whoosh() async {
    await _playSound('whoosh.wav');
  }

  /// Sparkle sound for small achievements
  Future<void> sparkle() async {
    await _playSound('sparkle.wav');
  }

  /// Lock sound - when trying locked content
  Future<void> locked() async {
    await _playSound('locked.wav');
  }

  /// Unlock sound - when unlocking content
  Future<void> unlock() async {
    await _playSound('unlock.wav');
  }

  /// Dispose audio player
  void dispose() {
    _player.dispose();
  }
}

/// Extension to easily play sounds
extension SoundExtension on BuildContext {
  SoundService get sounds => SoundService.instance;
}
