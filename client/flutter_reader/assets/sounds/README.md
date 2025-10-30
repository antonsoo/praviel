# Sound Assets for Ancient Languages App

This directory contains all sound effects used in the app for multi-sensory feedback.

## Sound Design Philosophy

Sounds in this app are designed to be **calming, natural, and pleasant** - enhancing the learning experience without becoming distracting or annoying. We prioritize:
- Nature-inspired sounds (gentle wind, soft water, rustling leaves, bird chirps)
- Acoustic instruments (harp plucks, gentle chimes, wooden percussion)
- Organic tones that evoke ancient, peaceful study environments
- NO harsh beeps, bloops, or robotic sounds
- NO jarring bells or alarm-like tones

Think: monastery bells, scroll unfurling, ink brush on parchment, ancient harp strings.

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

### Option 1: Use Free Sound Libraries (RECOMMENDED)
**Calming, nature-inspired sounds for ancient language study**

#### Pixabay (CC0 - No attribution required)
**Website:** https://pixabay.com/sound-effects/
**License:** Pixabay Content License (free for commercial use, no attribution)

Search terms for calming sounds:
- "harp pluck" → tap/button sounds
- "wind chime" → success sounds
- "wooden knock" → gentle tap
- "bamboo chime" → success/achievement
- "water drop" → tick/counter
- "gentle bell" → notifications
- "harp glissando" → level up
- "nature chime" → sparkle/achievement

**Download steps:**
1. Search for sound effect
2. Click sound → Preview → Download MP3
3. No attribution required (but appreciated)

#### Freesound.org (CC0 recommended)
**Website:** https://freesound.org
**License:** Various CC licenses - **Filter by "Creative Commons 0" for no attribution**

**Important:** Use the license filter to select "Creative Commons 0" (CC0) for unrestricted commercial use.

Recommended search terms:
- "harp pluck cc0" → acoustic button sounds
- "soft chime cc0" → success feedback
- "bamboo wind cc0" → ambient/transition
- "wooden click cc0" → tap sounds
- "gentle bell cc0" → achievements
- "nature ambience cc0" → background

**Recommended packs:**
- Search "ambient nature soundscapes" for background
- Search "wooden percussion" for organic UI sounds
- Search "harp strings" for gentle musical tones

#### Mixkit (Free, check license)
**Website:** https://mixkit.co/free-sound-effects/nature/
**License:** Mixkit License (review for commercial mobile app use)

Great for:
- Nature ambience loops (bird songs, water, rain)
- Gentle water sounds
- Forest ambience

**Note:** Review the Mixkit License for commercial mobile app usage terms before using.

#### Zapsplat (Free with attribution)
**Website:** https://www.zapsplat.com
**License:** Free with attribution in app credits

Great for:
- Nature sounds (2,900+ effects)
- Organic UI sounds
- Water, wind, forest effects

**Attribution format:** "Sound effects from Zapsplat.com"

### Option 2: Use jsfxr (Browser-based, Free)
**⚠️ NOT RECOMMENDED for this app - creates synthetic/robotic sounds**
**Only use for quick prototyping before replacing with natural sounds**

Visit: https://sfxr.me/

#### Presets for Each Sound (if needed for testing):

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
