# Donation Assets

This directory contains QR codes and related assets for cryptocurrency donations.

## Generate QR Codes (Maintainer Only)

After generating cryptocurrency addresses, create QR code images for easy scanning:

### Linux / macOS

```bash
# Install qrencode
sudo apt-get install qrencode  # Ubuntu/Debian
brew install qrencode          # macOS

# Generate QR codes
qrencode -o btc.png "bitcoin:YOUR_BTC_ADDRESS"
qrencode -o eth.png "ethereum:YOUR_ETH_ADDRESS"
qrencode -o xmr.png "monero:YOUR_XMR_ADDRESS"
```

### Windows

```powershell
# Install via Chocolatey (if available)
choco install qrencode

# Or use online QR generator:
# - https://www.qr-code-generator.com/
# - Save as btc.png, eth.png, xmr.png
```

### Online Alternative

Use a secure QR code generator:
1. Visit https://www.the-qrcode-generator.com/
2. Select "Text" mode
3. Enter the cryptocurrency address
4. Download as PNG (200x200 or 300x300)
5. Save as `btc.png`, `eth.png`, or `xmr.png`

## Files

Once generated, this directory should contain:

- **btc.png** - Bitcoin QR code
- **eth.png** - Ethereum QR code
- **xmr.png** - Monero QR code

These QR codes are referenced in:
- Flutter app: `client/flutter_reader/lib/pages/support_page.dart`
- Documentation: `docs/SUPPORT.md`

## Security Note

**DO NOT commit actual wallet addresses to version control without carefully considering privacy implications.**

For maximum privacy with cryptocurrency donations:
- Use separate donation addresses (not your personal wallet)
- Consider using privacy-focused coins (like Monero)
- Rotate addresses periodically if desired
