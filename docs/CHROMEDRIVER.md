# Chromedriver Strategy

## Overview
This project uses Chromedriver for web-based E2E tests (Selenium + Flutter web). Chromedriver binaries are **NOT** committed to the repository.

## CI Environment
GitHub Actions downloads Chromedriver at runtime:
- `setup-chromedriver@v1` action handles version matching with installed Chrome
- Automatic compatibility between Chrome and Chromedriver versions
- No local binaries committed to version control
- `tools/chromedriver-*` excluded from packaging via `.gitignore`

## Local Development

### Automated (Recommended)
The orchestrator automatically downloads Chromedriver to `tools/` when needed:
- Matches system Chrome version
- Downloads to `tools/chromedriver-{version}/`
- Gitignored (not tracked)

### Manual Setup
If you prefer manual control:
1. Install Chrome/Chromium on your system
2. Download matching Chromedriver from [chromedriver.chromium.org](https://chromedriver.chromium.org/)
3. Add to PATH, or place in `tools/` directory
4. Orchestrator will detect existing binary

## Troubleshooting

### Version Mismatch
```
ERROR: session not created: This version of ChromeDriver only supports Chrome version X
```
**Solution:** Delete `tools/chromedriver-*` and re-run orchestrator to download correct version.

### Permission Denied (Unix/Linux)
```
ERROR: Permission denied: 'tools/chromedriver'
```
**Solution:** `chmod +x tools/chromedriver-*/chromedriver`

### Windows Firewall
If Chromedriver prompts for network access, allow it for `127.0.0.1` (localhost only).

## References
- [Chromedriver Downloads](https://chromedriver.chromium.org/)
- [Selenium WebDriver Docs](https://www.selenium.dev/documentation/webdriver/)
- GitHub Action: [setup-chromedriver](https://github.com/marketplace/actions/setup-chromedriver)
