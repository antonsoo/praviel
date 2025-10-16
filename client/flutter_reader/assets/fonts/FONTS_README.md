# Ancient Language Fonts Guide

This directory contains font files for historically accurate rendering of ancient scripts.

## Quick Start

### Option 1: System Fonts (Easiest)
Modern operating systems (Windows 10+, macOS, Linux, Android, iOS) already include many Noto fonts. The app will use system fonts as fallbacks automatically.

### Option 2: Bundle Fonts (Best Quality)
For guaranteed rendering across all platforms, download and bundle specific Noto fonts.

## Required Fonts by Language

### Currently Available Languages (Priority 1)
- **Classical Greek**: System fonts work (no download needed)
- **Classical Latin**: System fonts work (no download needed)
- **Biblical Hebrew**: `Noto Sans Hebrew`
- **Classical Sanskrit**: `Noto Sans Devanagari`

### Planned Languages (Priority 2)
- **Pali**: `Noto Sans Brahmi`
- **Proto-Germanic**: `Noto Sans Runic`
- **Proto-Norse**: `Noto Sans Runic`
- **Paleo-Hebrew**: `Noto Sans Phoenician`
- **Old Church Slavonic**: `Noto Sans Glagolitic`, `Noto Serif Glagolitic`
- **Avestan**: `Noto Sans Avestan`
- **Ancient Aramaic**: `Noto Sans Imperial Aramaic`
- **Old Persian**: `Noto Sans Old Persian`
- **Akkadian & Sumerian**: `Noto Sans Cuneiform`
- **Old Egyptian**: `Noto Sans Egyptian Hieroglyphs`

## How to Download Fonts

### Method 1: Google Fonts (Recommended)
Visit [Google Fonts Noto Collection](https://fonts.google.com/noto) and search for each font:

1. Search for font name (e.g., "Noto Sans Runic")
2. Click "Get font"
3. Click "Download all"
4. Extract the `.ttf` file from the zip
5. Place in this directory (`assets/fonts/`)

### Method 2: GitHub (All fonts at once)
Clone the entire Noto fonts repository:
```bash
git clone https://github.com/notofonts/notofonts.github.io.git
```

Then copy needed `.ttf` files to this directory.

## Font File Naming Convention

Use these exact filenames for the app to find them:

```
NotoSerifGreek-Regular.ttf
NotoSansDevanagari-Regular.ttf
NotoSansBrahmi-Regular.ttf
NotoSansHebrew-Regular.ttf
NotoSansGlagolitic-Regular.ttf
NotoSansCuneiform-Regular.ttf
NotoSansOldPersian-Regular.ttf
NotoSansAvestan-Regular.ttf
NotoSansImperialAramaic-Regular.ttf
NotoSansPhoenician-Regular.ttf
NotoSansEgyptianHieroglyphs-Regular.ttf
NotoSansRunic-Regular.ttf
```

## Enabling Fonts in the App

After adding font files:

1. Uncomment the corresponding font family in `pubspec.yaml`
2. Run `flutter pub get`
3. Rebuild the app: `flutter run` or `flutter build`

Example in `pubspec.yaml`:
```yaml
fonts:
  - family: Noto Sans Runic
    fonts:
      - asset: assets/fonts/NotoSansRunic-Regular.ttf
```

## Testing Font Rendering

Use the language selector screen to verify:
1. All ancient scripts display correctly (no tofu/boxes)
2. RTL languages (Hebrew, Aramaic, Avestan) align right-to-left
3. Ligatures work correctly
4. Tooltips show for reconstructed languages

## Font Licenses

All Noto fonts are licensed under the **SIL Open Font License 1.1**, which allows:
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use

See individual font directories for full license text.

## Troubleshooting

### Fonts show as boxes (tofu)
- Verify the `.ttf` file is in `assets/fonts/`
- Check filename matches exactly (case-sensitive)
- Uncomment font family in `pubspec.yaml`
- Run `flutter clean && flutter pub get`

### RTL text displays incorrectly
- Ensure language has `textDirection: TextDirection.rtl` in `language.dart`
- Verify the `AncientLabel` widget wraps text in `Directionality`

### Fonts look blurry on web
- Use `flutter build web --web-renderer canvaskit` for better font rendering
- Add `--dart-define=FLUTTER_WEB_USE_SKIA=true`

## Font Size Recommendations

- **Language selector cards**: 14-16pt
- **Navigation labels**: 12-14pt
- **Headings**: 18-24pt
- **Body text in lessons**: 16-18pt

Adjust `fontSize` parameter in `AncientLabel` widgets as needed.

## Performance Notes

- Each bundled font adds ~200-500KB to app size
- System fallback fonts have zero size impact
- Consider subsetting fonts for production (advanced)
- Web apps: fonts load async, may see flash of unstyled text

## Advanced: Font Subsetting

To reduce app size, subset fonts to only include needed glyphs:

```bash
# Install pyftsubset
pip install fonttools

# Subset to specific Unicode ranges
pyftsubset NotoSansRunic-Regular.ttf \
  --unicodes=U+16A0-16FF \
  --output-file=NotoSansRunic-Subset.ttf
```

Update `pubspec.yaml` to use the subset file.

## Resources

- [Google Fonts Noto](https://fonts.google.com/noto)
- [Noto GitHub](https://github.com/notofonts)
- [Unicode Scripts](https://unicode.org/charts/)
- [SIL OFL License](https://scripts.sil.org/OFL)
