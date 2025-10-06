# Donation Setup Guide

**Status**: ✅ Code ready, placeholders need replacement

## Quick Overview

The donation infrastructure is implemented and working. You need to:

1. Create accounts on donation platforms (~1-2 hours)
2. Replace 21 placeholders in 4 files (~15 minutes)
3. Test the app (~15 minutes)

**Total time**: 2-3 hours

---

## Step 1: Create Accounts (Priority Order)

### Must Have (Start Here):
1. **GitHub Sponsors** - ✅ Already enabled (@antonsoo)
2. **Stripe** - One-time donations - https://dashboard.stripe.com/payment-links
   - Most versatile, accepts cards/Apple Pay/Google Pay
   - Setup time: 10 minutes

### Should Have (Easy Setup):
3. **Ko-fi** - Quick tips - https://ko-fi.com/manage/register
   - Easiest platform, takes 5 minutes
4. **Liberapay** - Recurring, 0% fees - https://liberapay.com/sign-up
   - Takes 5 minutes

### Nice to Have:
5. **Patreon** - Membership tiers - https://www.patreon.com/create
   - Takes 15 minutes if you want tiers
6. **Open Collective** - Transparent funding - https://opencollective.com/create
   - Takes 10 minutes, offers public budget

### Optional (Crypto):
7. Create crypto wallets for BTC, ETH, XMR
   - Use Coinbase/Kraken (easy) or hardware wallet (secure)
   - **Important**: Use NEW addresses for donations, not your personal wallets

---

## Step 2: Replace Placeholders

### Files to Update (4 total):

1. **`.github/FUNDING.yml`** - GitHub sponsor button config
2. **`docs/SUPPORT.md`** - Full donation documentation
3. **`README.md`** - Header CTA + "How to Help" section
4. **`client/flutter_reader/lib/pages/support_page.dart`** - Flutter app UI

### Find All Placeholders:

```bash
grep -r "PLACEHOLDER_" .github/FUNDING.yml docs/SUPPORT.md README.md client/flutter_reader/lib/pages/support_page.dart
```

### Replace Guide:

#### Platform URLs (14 placeholders):

**Stripe** (4 occurrences):
- `.github/FUNDING.yml`: Uncomment `custom:` line, replace URL
- `docs/SUPPORT.md`: Replace `PLACEHOLDER_STRIPE_LINK`
- `README.md`: Replace `PLACEHOLDER_STRIPE`
- `support_page.dart`: Replace `PLACEHOLDER_STRIPE_URL`

**Patreon** (4 occurrences):
- `.github/FUNDING.yml`: Uncomment `patreon:`, add username
- `docs/SUPPORT.md`: Replace `PLACEHOLDER_PATREON_LINK`
- `README.md`: Replace `PLACEHOLDER_PATREON`
- `support_page.dart`: Replace `PLACEHOLDER_PATREON_URL`

**Ko-fi** (4 occurrences):
- `.github/FUNDING.yml`: Uncomment `ko_fi:`, add username
- `docs/SUPPORT.md`: Replace `PLACEHOLDER_KOFI_LINK`
- `README.md`: Replace `PLACEHOLDER_KOFI`
- `support_page.dart`: Replace `PLACEHOLDER_KOFI_URL`

**Liberapay** (4 occurrences):
- `.github/FUNDING.yml`: Uncomment `liberapay:`, add username
- `docs/SUPPORT.md`: Replace `PLACEHOLDER_LIBERAPAY_LINK`
- `README.md`: Replace `PLACEHOLDER_LIBERAPAY`
- `support_page.dart`: Replace `PLACEHOLDER_LIBERAPAY_URL`

**Open Collective** (4 occurrences) - OPTIONAL:
- `.github/FUNDING.yml`: Uncomment `open_collective:`, add slug
- `docs/SUPPORT.md`: Replace `PLACEHOLDER_OPENCOLLECTIVE_LINK`
- `README.md`: Replace `PLACEHOLDER_OPENCOLLECTIVE`
- `support_page.dart`: Replace `PLACEHOLDER_OPENCOLLECTIVE_URL`

#### Crypto Addresses (9 placeholders):

**Bitcoin** (3 occurrences):
- `docs/SUPPORT.md`: Replace `PLACEHOLDER_BTC_ADDRESS`
- `README.md`: Replace `PLACEHOLDER_BTC`
- `support_page.dart`: Replace `PLACEHOLDER_BTC`

**Ethereum** (3 occurrences):
- `docs/SUPPORT.md`: Replace `PLACEHOLDER_ETH_ADDRESS`
- `README.md`: Replace `PLACEHOLDER_ETH`
- `support_page.dart`: Replace `PLACEHOLDER_ETH`

**Monero** (3 occurrences):
- `docs/SUPPORT.md`: Replace `PLACEHOLDER_XMR_ADDRESS`
- `README.md`: Replace `PLACEHOLDER_XMR`
- `support_page.dart`: Replace `PLACEHOLDER_XMR`

---

## Step 3: Generate Crypto QR Codes (Optional)

If you added crypto addresses:

```bash
# Linux/macOS
qrencode -o assets/donations/btc.png "bitcoin:YOUR_BTC_ADDRESS"
qrencode -o assets/donations/eth.png "ethereum:YOUR_ETH_ADDRESS"
qrencode -o assets/donations/xmr.png "monero:YOUR_XMR_ADDRESS"
```

Windows: Use online QR generator at https://www.qr-code-generator.com/

---

## Step 4: Test

```bash
# 1. Install dependencies
cd client/flutter_reader
flutter pub get

# 2. Run the app
flutter run -d chrome

# 3. Test navigation
# - Go to Settings (⚙️ icon)
# - Scroll to "About" section
# - Tap "Support This Project"
# - Verify all buttons work correctly
```

### Testing Checklist:

- [ ] Support page loads without errors
- [ ] GitHub Sponsors button is enabled (should work now)
- [ ] Other platform buttons are enabled (after you replaced placeholders)
- [ ] Placeholders you didn't replace show "Coming soon" and are disabled
- [ ] Crypto section expands and shows QR codes (if you added addresses)
- [ ] Copy address button works
- [ ] Clicking enabled buttons opens correct URLs in browser

---

## Step 5: Deploy

```bash
# Commit placeholder replacements
git add .
git commit -m "chore: configure donation platform accounts"
git push origin main
```

After push, verify:
- [ ] GitHub repo shows Sponsor button (may take a few minutes)
- [ ] Clicking Sponsor button shows your configured platforms

---

## Troubleshooting

**GitHub Sponsor button not showing?**
- Check `.github/FUNDING.yml` syntax is correct (YAML is strict about indentation)
- Wait 5-10 minutes after push (GitHub caches this)
- Ensure you uncommented the lines (remove the `#`)

**Donation buttons not working in app?**
- Check you replaced `PLACEHOLDER_` with actual URLs (no typos)
- For platform usernames: use just the username, not full URL (e.g., `yourname` not `https://ko-fi.com/yourname`)
- For custom links: use full URL (e.g., `https://donate.stripe.com/xxxxx`)

**QR codes not showing?**
- They only appear if crypto address is NOT a placeholder
- Check the address doesn't start with `PLACEHOLDER`

---

## What's Already Done

✅ GitHub FUNDING.yml configured (GitHub Sponsors working)
✅ Flutter support page with donation UI
✅ Documentation in README and docs/SUPPORT.md
✅ Settings integration (Settings → About → Support This Project)
✅ Android url_launcher permissions configured
✅ Crypto QR codes use proper URI schemes (bitcoin:, ethereum:, monero:)
✅ Placeholder handling (disabled buttons show "Coming soon")
✅ Widget tests for support page
✅ Empty sections hidden (if Open Collective not configured)

---

## Platform-Specific Notes

**Stripe**: Use Payment Links feature (easiest) - https://dashboard.stripe.com/payment-links

**Ko-fi**: Format can be username (e.g., `yourname`) OR full URL

**Patreon**: Can use username OR full URL

**Liberapay**: Can use username OR full URL

**Open Collective**: Use the "slug" (URL segment), e.g., if your URL is `https://opencollective.com/ancientlanguages`, use `ancientlanguages`

**Crypto**: Always use NEW addresses for maximum privacy and security

---

## Need Help?

- GitHub Sponsors setup: https://docs.github.com/en/sponsors
- Stripe Payment Links: https://support.stripe.com/questions/how-to-create-a-payment-link
- Ko-fi: https://help.ko-fi.com/
- Questions about this codebase: GitHub Issues

---

**Estimated total time**: 2-3 hours (1-2 hours for accounts, 15 min for placeholders, 15 min for testing)
