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
      debugPrint('[SoundService] Error playing $fileName: $e. Using system sound.');
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
    await _playSound('tap.mp3');
  }

  /// Button press sound
  Future<void> button() async {
    await _playSound('button.mp3');
  }

  /// Correct answer sound - pleasant chime
  Future<void> success() async {
    await _playSound('success.mp3');
  }

  /// Wrong answer sound - gentle buzz
  Future<void> error() async {
    await _playSound('error.mp3');
  }

  /// XP gain sound - coin sound
  Future<void> xpGain() async {
    await _playSound('xp_gain.mp3');
  }

  /// Level up sound - victory fanfare
  Future<void> levelUp() async {
    await _playSound('level_up.mp3');
  }

  /// Streak milestone sound - whoosh + sparkle
  Future<void> streakMilestone() async {
    await _playSound('streak_milestone.mp3');
  }

  /// Card swipe sound
  Future<void> swipe() async {
    await _playSound('swipe.mp3');
  }

  /// Page transition sound
  Future<void> transition() async {
    await _playSound('whoosh.mp3');
  }

  /// Achievement unlocked sound
  Future<void> achievement() async {
    await _playSound('achievement.mp3');
  }

  /// Celebration sound for big rewards
  Future<void> celebration() async {
    await _playSound('celebration.mp3');
  }

  /// Combo sound - escalates with combo level
  Future<void> combo(int level) async {
    if (level >= 10) {
      await _playSound('combo_3.mp3');
    } else if (level >= 5) {
      await _playSound('combo_2.mp3');
    } else {
      await _playSound('combo_1.mp3');
    }
  }

  /// Power-up activation sound - magical woosh
  Future<void> powerUpActivate() async {
    await _playSound('power_up.mp3');
  }

  /// Badge unlock sound - ta-da!
  Future<void> badgeUnlock() async {
    await _playSound('badge_unlock.mp3');
  }

  /// Tick sound for counters
  Future<void> tick() async {
    if (_volume < 0.1) return;
    await _playSound('tick.mp3');
  }

  /// Confetti pop sound
  Future<void> confetti() async {
    await _playSound('confetti.mp3');
  }

  /// Whoosh sound for fast transitions
  Future<void> whoosh() async {
    await _playSound('whoosh.mp3');
  }

  /// Sparkle sound for small achievements
  Future<void> sparkle() async {
    await _playSound('sparkle.mp3');
  }

  /// Lock sound - when trying locked content
  Future<void> locked() async {
    await _playSound('locked.mp3');
  }

  /// Unlock sound - when unlocking content
  Future<void> unlock() async {
    await _playSound('unlock.mp3');
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
