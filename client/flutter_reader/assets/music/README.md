# Background Music Directory Structure

This directory contains background music organized by language code.

## 🎵 How It Works

The music system **automatically discovers and plays all music files** in each language folder. Just drop music files into the appropriate language directory and they'll be added to the playlist!

## Directory Structure

```
music/
├── lat/              # Classical Latin
│   ├── Gloriosum_Triumphale.mp3
│   ├── Confessio_Noctis.mp3
│   └── [any other .mp3/.flac/.ogg files]
├── grc-cls/          # Classical Greek
│   ├── Sunrise_Over_Aegean.mp3
│   ├── Lament_for_a_Broken_God.mp3
│   └── [any other music files]
├── grc-koi/          # Koine Greek
│   └── [your music files here]
├── hbo/              # Biblical Hebrew
│   └── [your music files here]
└── [other language codes]/
    └── [your music files here]
```

## Adding Music Files (Super Easy!)

1. **Create a directory** for the language using its language code (e.g., `lat`, `grc-cls`, `hbo`, `san`)
2. **Drop in ANY music files** with these extensions:
   - `.mp3` (recommended - best compatibility)
   - `.flac` (high quality)
   - `.ogg` (open format)
   - `.wav` (uncompressed)
   - `.m4a` (AAC format)
3. **Name them whatever you want!**
   - ✅ `Epic_Battle_Theme.mp3`
   - ✅ `peaceful-monastery-01.mp3`
   - ✅ `track_003.mp3`
   - ✅ `My Cool Song (2025 Remaster).flac`
4. The app will **automatically detect and play them all** as a shuffled playlist!

**No configuration needed!** The `MusicService` scans the asset manifest and plays everything it finds.

## Audio Specifications

- **Format**: MP3
- **Bitrate**: 128kbps (recommended for balance of quality and file size)
- **Sample Rate**: 44.1kHz
- **Channels**: Stereo or Mono
- **Duration**: 2-5 minutes per track (will loop automatically)

## Music Style Guidelines

Each language should have culturally appropriate background music:

- **Latin**: Classical period instrumentation (lyre, flute, strings)
- **Greek**: Ancient Greek modes and instruments
- **Hebrew**: Traditional Middle Eastern instruments
- **Sanskrit**: Traditional Indian classical music

Music should be:
- Instrumental only (no vocals)
- Calming and non-distracting
- Culturally authentic when possible
- Royalty-free or properly licensed

## Current Status

Music is **disabled by default**. Users can enable it via:
- Bottom-right floating music controls
- Settings → Audio → Background Music

Directories are created and ready for music files to be added.
