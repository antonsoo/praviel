# Git LFS Recommendation for Large Font Files

## Current Status
The following CJK font files are **58MB each** and are currently tracked in Git:

- `NotoSerifCJKjp-VF.ttf` (58MB - Japanese)
- `NotoSerifCJKsc-VF.ttf` (58MB - Simplified Chinese)
- `NotoSerifCJKtc-VF.ttf` (58MB - Traditional Chinese)

**Total:** 174MB of font files in this directory

## Recommendation: Git LFS

For better performance, consider migrating these large font files to Git LFS:

```bash
# Install Git LFS
git lfs install

# Track large font files
git lfs track "client/flutter_reader/assets/fonts/*-VF.ttf"
git lfs track "client/flutter_reader/assets/fonts/NotoSerifCJK*.ttf"

# Add .gitattributes
git add .gitattributes

# Migrate existing files (CAREFUL: rewrites history)
git lfs migrate import --include="client/flutter_reader/assets/fonts/NotoSerifCJK*.ttf"
```

## Why Git LFS?

- Reduces clone time for developers
- Keeps repository size manageable
- GitHub has a 100MB file size limit (we're under it, but close)
- LFS is standard practice for binary assets >50MB

## Current Solution

All font files are committed directly to Git. This works but may slow down clones/fetches as the repository grows.

Future maintainers should consider LFS migration if:
- Repository size exceeds 500MB
- Clone times become problematic
- More large fonts are added
