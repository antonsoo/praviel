# Background Music Assets

This directory contains royalty-free background music for the Reader feature.

## Required Music Files

Place the following files in this directory:

- `ambient_classical_1.mp3` - Primary ambient classical track
- `ambient_classical_2.mp3` - Secondary ambient classical track
- `ambient_classical_3.mp3` - Tertiary ambient classical track

## Recommended Music Sources (Royalty-Free)

### 1. **Free Music Archive** (CC-licensed)
- URL: https://freemusicarchive.org/
- License: Various Creative Commons licenses
- Best for: Classical, ambient, world music
- **Recommended searches:**
  - "ambient classical"
  - "greek music ambient"
  - "lyre ambient"
  - "ancient music"

### 2. **Incompetech** by Kevin MacLeod
- URL: https://incompetech.com/music/
- License: CC BY 4.0
- Best for: Royalty-free music with proper attribution
- **Recommended tracks:**
  - "Ancient Rite"
  - "Frost Waltz"
  - "Meditation Impromptu 01"

### 3. **Musopen** (Public Domain Classical)
- URL: https://musopen.org/
- License: Public Domain
- Best for: Classical music recordings
- **Recommended:**
  - Debussy - Claire de Lune
  - Erik Satie - Gymnopédies
  - Bach - Air on G String

### 4. **YouTube Audio Library**
- URL: https://studio.youtube.com/channel/UC.../music
- License: Free to use (requires YouTube login)
- Best for: High-quality ambient tracks
- **Recommended genres:**
  - Ambient
  - Classical
  - World

### 5. **Bensound**
- URL: https://www.bensound.com/
- License: Free with attribution
- Best for: Modern cinematic ambient
- **Recommended tracks:**
  - "Memories"
  - "Inspire"
  - "The Lounge"

## Music Specifications

### Technical Requirements
- **Format:** MP3 (preferred for cross-platform compatibility)
- **Bitrate:** 128-192 kbps (balance quality vs file size)
- **Length:** 2-5 minutes (will loop seamlessly)
- **Volume:** Normalized to -14 LUFS (consistent volume)

### Style Guidelines
- **Tempo:** Slow to medium (60-90 BPM)
- **Mood:** Calm, contemplative, scholarly
- **Instruments:** Prefer:
  - Classical: strings, piano, harp
  - Ancient: lyre, flute, oud
  - Ambient: pads, drones
- **Avoid:** Vocals, percussion, modern instruments

## Adding Music Files

1. **Download** tracks from recommended sources
2. **Rename** to match required filenames above
3. **Convert** to MP3 if needed (use FFmpeg):
   ```bash
   ffmpeg -i input.wav -codec:a libmp3lame -b:a 192k output.mp3
   ```
4. **Normalize** volume:
   ```bash
   ffmpeg -i input.mp3 -filter:a loudnorm=I=-14:TP=-1:LRA=11 output_normalized.mp3
   ```
5. **Place** in this directory
6. **Update** `pubspec.yaml` if not already included:
   ```yaml
   assets:
     - assets/audio/music/
   ```

## Attribution

If using CC-licensed music, add attribution to `lib/pages/settings/about_page.dart`:

```dart
Text('Background music: "Track Name" by Artist Name (freemusicarchive.org)'),
```

## Testing

Test music playback:

1. Enable background music in Settings
2. Open any Reader text
3. Music should loop smoothly
4. Volume should be ~30% by default
5. Music should stop when exiting Reader

## Current Status

**Status:** ⚠️ Music files not yet added (awaiting royalty-free selection)

**Next Steps:**
1. Download 3 tracks from recommended sources
2. Process with FFmpeg (normalize, convert)
3. Add to this directory
4. Test in dev environment
5. Add attributions if required

---

**Note:** Do NOT commit copyrighted music to the repository. Only use royalty-free or Creative Commons licensed music with proper attribution.
