# Background Music Directory Structure

This directory contains background music organized by language code.

## Directory Structure

```
music/
├── lat/              # Classical Latin
│   ├── background_1.mp3
│   ├── background_2.mp3
│   └── ...
├── grc-cls/          # Classical Greek
│   ├── background_1.mp3
│   └── ...
├── grc-koi/          # Koine Greek
│   ├── background_1.mp3
│   └── ...
├── hbo/              # Biblical Hebrew
│   ├── background_1.mp3
│   └── ...
└── [other language codes]/
    └── ...
```

## Adding Music Files

1. Create a directory for the language using its language code (e.g., `lat`, `grc-cls`, `hbo`)
2. Add MP3 files named `background_1.mp3`, `background_2.mp3`, etc.
3. The app will automatically loop through available tracks for each language
4. Files should be optimized for web/mobile (recommended: 128kbps MP3)

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
