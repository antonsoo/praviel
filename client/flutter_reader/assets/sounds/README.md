# Sound Assets for Ancient Languages App

This directory contains all sound effects used in the app for multi-sensory feedback.

## Sound Files Required

### Interaction Sounds
- `tap.mp3` - Light tap/click sound (50-100ms, subtle)
- `button.mp3` - Button press sound (100-150ms, satisfying click)
- `swipe.mp3` - Swipe/drag sound (200ms, whoosh)

### Feedback Sounds
- `success.mp3` - Correct answer chime (300-500ms, pleasant bell/chime)
- `error.mp3` - Wrong answer buzz (200-300ms, gentle negative tone, NOT harsh)
- `tick.mp3` - Counter tick sound (30ms, very subtle)

### Achievement Sounds
- `xp_gain.mp3` - XP reward sound (500ms, coin clink or sparkle)
- `level_up.mp3` - Level up fanfare (1-2s, triumphant)
- `achievement.mp3` - Badge unlock sound (800ms, ta-da!)
- `streak_milestone.mp3` - Streak achievement (600ms, whoosh + sparkle)

### Combo Sounds
- `combo_1.mp3` - Combo tier 1 (200ms, base pitch)
- `combo_2.mp3` - Combo tier 2 (200ms, higher pitch)
- `combo_3.mp3` - Combo tier 3 (200ms, highest pitch, most energetic)

### Special Effects
- `confetti.mp3` - Confetti pop (400ms, celebration)
- `whoosh.mp3` - Fast transition (300ms, air movement)
- `sparkle.mp3` - Small sparkle (200ms, gentle chime)
- `locked.mp3` - Locked content tap (200ms, gentle negative)
- `unlock.mp3` - Content unlock (400ms, satisfying click + chime)
- `power_up.mp3` - Power-up activation (600ms, magical woosh)
- `badge_unlock.mp3` - Badge reveal (800ms, triumphant reveal)

## How to Generate Sound Files

### Option 1: Use Free Sound Libraries
**Recommended for production quality**

1. **freesound.org** - Search for:
   - "ui click" for tap/button sounds
   - "success chime" for correct answers
   - "error buzz" for wrong answers
   - "coin drop" for XP gain
   - "level up fanfare" for level up
   - "achievement unlock" for badges

2. **zapsplat.com** - Great for:
   - UI sounds (free with attribution)
   - Game achievement sounds

3. **pixabay.com** - Royalty-free sound effects:
   - Search "game ui sounds"
   - Download MP3 format

### Option 2: Use jsfxr (Browser-based, Free)
**Great for quick prototyping**

Visit: https://sfxr.me/

#### Presets for Each Sound:

**tap.mp3:**
```
Wave: square
Attack: 0.01, Sustain: 0.05, Decay: 0.1
Frequency: 800 Hz, Frequency Sweep: -200
Volume: 0.3
```

**success.mp3:**
```
Wave: sine
Attack: 0.01, Sustain: 0.2, Decay: 0.3
Frequency: 600 Hz, Frequency Sweep: +400
Volume: 0.4
```

**error.mp3:**
```
Wave: square
Attack: 0.01, Sustain: 0.1, Decay: 0.15
Frequency: 200 Hz, Frequency Sweep: -100
Volume: 0.3
```

**xp_gain.mp3:**
```
Wave: sine
Attack: 0.01, Sustain: 0.1, Decay: 0.4
Frequency: 800 Hz, Frequency Sweep: +200
Add harmonics at 1600 Hz
Volume: 0.4
```

**level_up.mp3:**
```
Wave: sawtooth
Attack: 0.02, Sustain: 0.3, Decay: 0.7
Frequency: 400 Hz → 600 Hz → 800 Hz (3 notes)
Volume: 0.5
```

### Option 3: Use AI Sound Generation
**For unique, custom sounds**

1. **ElevenLabs Sound Effects** (https://elevenlabs.io/sound-effects)
   - Free tier available
   - Describe the sound: "light UI tap sound, 100ms"

2. **AudioCraft by Meta** (https://audiocraft.metademolab.com/)
   - Open source, run locally
   - Generate custom game UI sounds

## File Specifications

**Format:** MP3 (best compatibility) or WAV (higher quality)
**Sample Rate:** 44.1 kHz
**Bit Rate:** 128 kbps (MP3) or 16-bit (WAV)
**Channels:** Mono (smaller file size, sufficient for UI sounds)
**Volume:** Normalized to -3 dB to -6 dB (prevents clipping)

## Adding Sounds to the App

1. Place all MP3/WAV files in `client/flutter_reader/assets/sounds/`

2. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/sounds/
```

3. Run `flutter pub get`

4. Sounds are automatically loaded by `SoundService`

## Testing Sounds

After adding files:

```dart
// Test in Flutter
SoundService.instance.success();  // Should play success.mp3
SoundService.instance.tap();      // Should play tap.mp3
```

## Copyright & Attribution

**Important:** Ensure all sound files are:
- Royalty-free OR
- Creative Commons licensed OR
- Properly attributed (add attribution in app credits if required)

For freesound.org files, check individual licenses (CC0, CC BY, CC BY-NC).

## Fallback Behavior

If sound files are missing, `SoundService` falls back to `SystemSound.click` (native system sound). This ensures the app never crashes due to missing audio files.

## Volume Guidelines

Default volume is 30% (`_volume = 0.3`) to avoid startling users. Users can adjust in Settings.

**Recommended volumes per sound type:**
- Tap/Button: 20-30%
- Success/Error: 30-40%
- XP/Achievements: 40-50%
- Level Up: 50-60% (celebratory)
- Background/Ambient: 10-20%
