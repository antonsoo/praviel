# 🎵 Sound Assets Guide

## Overview

The app has a comprehensive sound system built-in via `SoundService`. To enable sounds, you need to provide MP3 files in the `assets/sounds/` directory.

---

## 📁 Required Directory Structure

```
client/flutter_reader/
└── assets/
    └── sounds/
        ├── tap.mp3
        ├── button.mp3
        ├── success.mp3
        ├── error.mp3
        ├── xp_gain.mp3
        ├── level_up.mp3
        ├── streak_milestone.mp3
        ├── achievement.mp3
        ├── confetti.mp3
        ├── combo_1.mp3
        ├── combo_2.mp3
        ├── combo_3.mp3
        ├── power_up.mp3
        ├── badge_unlock.mp3
        ├── tick.mp3
        ├── whoosh.mp3
        ├── sparkle.mp3
        ├── locked.mp3
        └── unlock.mp3
```

---

## 🎼 Sound Descriptions & Recommendations

### UI Interaction Sounds

| File | Usage | Recommended Sound | Duration |
|------|-------|-------------------|----------|
| `tap.mp3` | Light UI taps | Subtle click, soft tap | 50-100ms |
| `button.mp3` | Button presses | Deeper click, satisfying press | 100-200ms |
| `swipe.mp3` | Card swipes | Swoosh, gentle whoosh | 200-300ms |
| `whoosh.mp3` | Page transitions | Fast whoosh, wind sound | 300-500ms |

**Suggested Tools:**
- [Zapsplat](https://www.zapsplat.com/) - UI sounds category
- [Freesound](https://freesound.org/) - Search "UI click"
- [Mixkit](https://mixkit.co/free-sound-effects/click/) - Free UI sounds

### Feedback Sounds

| File | Usage | Recommended Sound | Duration |
|------|-------|-------------------|----------|
| `success.mp3` | Correct answer | Pleasant chime, bell, ding | 200-400ms |
| `error.mp3` | Wrong answer | Gentle buzz, soft error tone | 200-400ms |
| `xp_gain.mp3` | XP earned | Coin sound, bling, cash register | 300-500ms |

**Character:**
- **Success**: Uplifting, positive, musical (C major chord works well)
- **Error**: Not harsh, gentle reminder (avoid scary/harsh sounds)
- **XP Gain**: Satisfying, rewarding (metal ding, coin drop)

**Suggested Tools:**
- [Pixabay](https://pixabay.com/sound-effects/) - Success/error sounds
- [BBC Sound Effects](https://sound-effects.bbcrewind.co.uk/) - Professional library

### Achievement Sounds

| File | Usage | Recommended Sound | Duration |
|------|-------|-------------------|----------|
| `level_up.mp3` | Level advancement | Victory fanfare, triumphant | 1-2s |
| `streak_milestone.mp3` | Streak achievements | Whoosh + sparkle combo | 1-1.5s |
| `achievement.mp3` | Badge unlocked | Ta-da, fanfare | 1-2s |
| `badge_unlock.mp3` | Badge earned | Unlock sound, achievement ding | 500ms-1s |
| `confetti.mp3` | Celebration pops | Popping, party blower | 500ms-1s |

**Character:**
- **Level Up**: Epic, triumphant (use orchestra or synth)
- **Streak**: Magical, mystical (chimes + whoosh)
- **Achievement**: Joyful, celebratory (brass instruments)

**Suggested Tools:**
- [Epidemic Sound](https://www.epidemicsound.com/) - Fanfares (subscription)
- [Motion Array](https://motionarray.com/sound-effects/) - Achievement sounds

### Gamification Sounds

| File | Usage | Recommended Sound | Duration |
|------|-------|-------------------|----------|
| `combo_1.mp3` | Combo 2-4 | Small ding | 200-300ms |
| `combo_2.mp3` | Combo 5-9 | Medium ding with echo | 300-500ms |
| `combo_3.mp3` | Combo 10+ | Epic ding with reverb | 500ms-1s |
| `power_up.mp3` | Power-up activated | Magical woosh, energy sound | 500ms-1s |

**Character:**
- **Combo 1**: Simple, light
- **Combo 2**: More intense, echo/reverb
- **Combo 3**: Epic, powerful, rewarding
- **Power-Up**: Magical, energetic (think Mario star power)

### Utility Sounds

| File | Usage | Recommended Sound | Duration |
|------|-------|-------------------|----------|
| `tick.mp3` | Counter increments | Soft tick, clock sound | 50-100ms |
| `sparkle.mp3` | Small achievements | Twinkle, glitter sound | 200-400ms |
| `locked.mp3` | Trying locked content | Denied, lock sound | 200-400ms |
| `unlock.mp3` | Unlocking content | Key turn, unlock click | 300-500ms |

---

## 🔧 How to Add Sounds

### Step 1: Create Directory
```powershell
# From project root
mkdir -p client/flutter_reader/assets/sounds
```

### Step 2: Add Sound Files
Place all MP3 files in the `assets/sounds/` directory.

### Step 3: Verify pubspec.yaml
The `pubspec.yaml` already includes:
```yaml
flutter:
  assets:
    - assets/sounds/
```

### Step 4: Run Flutter
```powershell
flutter pub get
flutter run
```

---

## 🎨 Sound Design Tips

### 1. **Volume Consistency**
All sounds should have similar volume levels:
```bash
# Use ffmpeg to normalize volume
ffmpeg -i input.mp3 -filter:a "volume=0.5" output.mp3
```

### 2. **File Size Optimization**
Keep sounds small for fast loading:
- **Target**: < 50KB per file
- **Bitrate**: 64-128 kbps is sufficient
- **Sample Rate**: 44.1kHz

```bash
# Compress with ffmpeg
ffmpeg -i input.mp3 -b:a 96k -ar 44100 output.mp3
```

### 3. **Format Compatibility**
- **Primary**: MP3 (best compatibility)
- **Alternative**: OGG (smaller size)
- **Avoid**: WAV (too large)

### 4. **Duration Guidelines**
- **UI Sounds**: 50-200ms (snappy)
- **Feedback Sounds**: 200-500ms (satisfying)
- **Celebrations**: 1-2s (epic)
- **Never**: > 3s (too long)

---

## 🆓 Free Sound Resources

### High-Quality Free Libraries
1. **[Zapsplat](https://www.zapsplat.com/)**
   - 100,000+ free sounds
   - UI, game, achievement categories
   - Free for personal/commercial use

2. **[Freesound](https://freesound.org/)**
   - Community-uploaded sounds
   - Creative Commons licensed
   - Search by tags

3. **[Mixkit](https://mixkit.co/free-sound-effects/)**
   - Curated sound effects
   - Free for commercial use
   - Game UI category

4. **[Pixabay](https://pixabay.com/sound-effects/)**
   - Royalty-free sounds
   - No attribution required
   - Success/error sounds

5. **[BBC Sound Effects](https://sound-effects.bbcrewind.co.uk/)**
   - 33,000+ professional sounds
   - Free for personal use
   - High quality

### Paid Options (Premium Quality)
1. **[Epidemic Sound](https://www.epidemicsound.com/)** - $15/month
2. **[AudioJungle](https://audiojungle.net/)** - Pay per sound
3. **[Motion Array](https://motionarray.com/)** - $29/month

---

## 🎯 Sound Mapping Reference

### In-App Triggers

| User Action | Sound File | Haptic |
|-------------|-----------|--------|
| Tap anywhere | `tap.mp3` | Light |
| Press button | `button.mp3` | Light |
| Correct answer | `success.mp3` | Medium |
| Wrong answer | `error.mp3` | Heavy |
| Gain XP | `xp_gain.mp3` | Light |
| Level up | `level_up.mp3` | Heavy |
| Complete lesson | `confetti.mp3` | Medium |
| Unlock achievement | `achievement.mp3` | Medium |
| Start combo | `combo_1.mp3` | Light |
| Build combo | `combo_2.mp3` | Medium |
| Epic combo | `combo_3.mp3` | Heavy |
| Activate power-up | `power_up.mp3` | Medium |
| Unlock badge | `badge_unlock.mp3` | Medium |
| Page transition | `whoosh.mp3` | None |
| Sparkle effect | `sparkle.mp3` | None |
| Try locked item | `locked.mp3` | Light |
| Unlock item | `unlock.mp3` | Medium |

---

## 🧪 Testing Sounds

### Test Each Sound Manually
```dart
import 'package:flutter_reader/services/sound_service.dart';

// In your test widget:
ElevatedButton(
  onPressed: () => SoundService.instance.success(),
  child: Text('Test Success Sound'),
),
```

### Test All Sounds
```dart
final sounds = [
  'tap', 'button', 'success', 'error', 'xp_gain',
  'level_up', 'streak_milestone', 'achievement', 'confetti',
  'combo_1', 'combo_2', 'combo_3', 'power_up', 'badge_unlock',
  'tick', 'whoosh', 'sparkle', 'locked', 'unlock',
];

for (var sound in sounds) {
  await Future.delayed(Duration(seconds: 1));
  await SoundService.instance._playSound('$sound.mp3');
}
```

---

## 🔇 Fallback Behavior

If sound files are missing:
1. App continues working (no crashes)
2. System sounds play as fallback
3. Console shows debug message: `[SoundService] Error playing X.mp3`

This is **intentional** - the app degrades gracefully without sounds.

---

## 🎼 Creating Your Own Sounds

### Option 1: Record & Edit
1. **Record**: Use Audacity (free) or Adobe Audition
2. **Edit**: Trim, normalize, add effects
3. **Export**: MP3, 96kbps, 44.1kHz

### Option 2: Synthesize
1. **[Bfxr](https://www.bfxr.net/)**: Browser-based game sound generator
2. **[SFXR](http://www.drpetter.se/project_sfxr.html)**: Desktop sound effect generator
3. **[ChipTone](https://sfbgames.itch.io/chiptone)**: Retro game sounds

### Option 3: Hire
- **Fiverr**: $5-50 for custom sound packs
- **Upwork**: Professional sound designers
- **SoundCloud**: Find indie sound artists

---

## 📋 Quick Checklist

Before launching:
- [ ] All 19 sound files present in `assets/sounds/`
- [ ] All files are MP3 format
- [ ] All files < 100KB (preferably < 50KB)
- [ ] All files have similar volume levels
- [ ] Tested each sound in-app
- [ ] Verified sounds work on iOS and Android
- [ ] Checked licenses (commercial use allowed)
- [ ] Added attribution if required by license

---

## 🚀 Quick Start

**Don't want to search for sounds?** Here's a 10-minute setup:

1. Go to [Zapsplat](https://www.zapsplat.com/)
2. Create free account
3. Search for each sound type:
   - "UI click" → `tap.mp3`, `button.mp3`
   - "success bell" → `success.mp3`
   - "error buzz" → `error.mp3`
   - "coin" → `xp_gain.mp3`
   - "fanfare" → `level_up.mp3`, `achievement.mp3`
   - "whoosh" → `whoosh.mp3`, `streak_milestone.mp3`
   - "pop" → `confetti.mp3`
   - "ding" → `combo_1.mp3`, `combo_2.mp3`, `combo_3.mp3`
   - "magical" → `power_up.mp3`, `sparkle.mp3`
   - "unlock" → `unlock.mp3`, `badge_unlock.mp3`
   - "lock" → `locked.mp3`
   - "tick" → `tick.mp3`

4. Download all sounds
5. Rename to match the filenames above
6. Place in `assets/sounds/` folder
7. Run `flutter pub get`
8. Test!

---

**Total time: 10-15 minutes for a complete sound experience!** 🎵
