# Large Font Files Management

## Current Status (October 2025)

The following CJK font files are stored in this directory:

- `NotoSerifCJKjp-VF.ttf` (58MB - Japanese) - **Loaded from R2 in production**
- `NotoSerifCJKsc-VF.ttf` (58MB - Simplified Chinese) - **Loaded from R2 in production**
- ~~`NotoSerifCJKtc-VF.ttf`~~ - **DELETED** (was unused)

**Total:** 116MB of font files in this directory

## Production Solution: Cloudflare R2

These fonts are **no longer bundled** in the Flutter web build. Instead, they are:

1. Hosted on **Cloudflare R2** (zero egress fees)
2. Loaded dynamically via `R2FontService` using the `dynamic_fonts` package
3. Served from `https://fonts.praviel.com` with custom domain
4. Converted to WOFF2 format for ~30% better compression

**See**: `docs/R2_FONT_DEPLOYMENT.md` for full deployment guide.

### Why R2 Instead of Bundling?

- **Cloudflare Pages Limit**: Cannot deploy files >25MB
- **Reduced Bundle Size**: Saves 116MB from initial download
- **On-Demand Loading**: Fonts only load when user selects CJK language
- **Zero Bandwidth Costs**: R2 has free egress (unlike AWS S3)

## Alternative: Git LFS (Not Recommended)

Git LFS could be used, but R2 is superior for our use case:

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

## Why R2 Over Git LFS?

| Feature | R2 (Current) | Git LFS |
|---------|--------------|---------|
| Production delivery | ✅ Direct CDN | ❌ Still bundled in app |
| Bundle size | ✅ 0 MB | ❌ 116 MB |
| Bandwidth costs | ✅ Free forever | ❌ GitHub charges for LFS bandwidth |
| On-demand loading | ✅ Only when needed | ❌ All fonts always downloaded |
| Cloudflare Pages compatible | ✅ Yes | ❌ Files >25MB blocked |

## Local Development

Font files remain in this directory for:
- **Reference**: Source TTF files for reconversion
- **Local Testing**: Can be used in debug builds if needed
- **Backup**: Ensures fonts aren't lost if R2 has issues

These files are still committed to Git (not LFS) because:
- Total repo size is acceptable (~200MB total)
- Simplifies developer setup (no LFS required)
- Files serve as backup/source of truth
