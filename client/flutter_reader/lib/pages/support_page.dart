import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Support page for displaying donation options and project contribution methods.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  // Donation platform URLs
  static const _githubSponsors = 'https://github.com/sponsors/antonsoo';
  static const _stripe = 'PLACEHOLDER_STRIPE_URL';
  static const _patreon = 'PLACEHOLDER_PATREON_URL';
  static const _liberapay = 'PLACEHOLDER_LIBERAPAY_URL';
  static const _kofi = 'PLACEHOLDER_KOFI_URL';
  static const _openCollective = 'PLACEHOLDER_OPENCOLLECTIVE_URL';

  // Cryptocurrency addresses
  static const _btcAddress = 'PLACEHOLDER_BTC';
  static const _ethAddress = 'PLACEHOLDER_ETH';
  static const _xmrAddress = 'PLACEHOLDER_XMR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support This Project'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildIntro(),
          const SizedBox(height: 24),
          _buildSection('One-Time Donations', [
            _buildLinkButton(context, 'Stripe Payment', _stripe, Icons.payment),
            _buildLinkButton(context, 'Ko-fi', _kofi, Icons.coffee),
          ]),
          const SizedBox(height: 16),
          _buildSection('Recurring Support', [
            _buildLinkButton(
              context,
              'GitHub Sponsors',
              _githubSponsors,
              Icons.favorite,
            ),
            _buildLinkButton(context, 'Patreon', _patreon, Icons.people),
            _buildLinkButton(
              context,
              'Liberapay',
              _liberapay,
              Icons.card_giftcard,
            ),
          ]),
          const SizedBox(height: 16),
          // Only show Transparent Funding section if Open Collective is configured
          if (!_openCollective.startsWith('PLACEHOLDER')) ...[
            _buildSection('Transparent Funding', [
              _buildLinkButton(
                context,
                'Open Collective',
                _openCollective,
                Icons.account_balance,
              ),
            ]),
            const SizedBox(height: 16),
          ],
          _buildCryptoSection(context),
          const SizedBox(height: 24),
          _buildWhatYourSupportEnables(),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why Support AncientLanguages?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Research-grade accuracy with Perseus, LSJ, Smyth citations'),
            SizedBox(height: 4),
            Text('• Privacy-respecting BYOK (keys never persisted)'),
            SizedBox(height: 4),
            Text('• Open source forever (Elastic License 2.0)'),
            SizedBox(height: 4),
            Text('• Active development: Reader v0 live, Latin + TTS coming'),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildLinkButton(
    BuildContext context,
    String label,
    String url,
    IconData icon,
  ) {
    final bool isPlaceholder = url.startsWith('PLACEHOLDER');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Row(
          children: [
            Expanded(child: Text(label)),
            if (isPlaceholder)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
        onPressed: isPlaceholder ? null : () => _launchUrl(context, url),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  Widget _buildCryptoSection(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        'Cryptocurrency Donations',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        _buildCryptoAddress(context, 'Bitcoin (BTC)', _btcAddress, 'bitcoin'),
        _buildCryptoAddress(context, 'Ethereum (ETH)', _ethAddress, 'ethereum'),
        _buildCryptoAddress(context, 'Monero (XMR)', _xmrAddress, 'monero'),
      ],
    );
  }

  Widget _buildCryptoAddress(
    BuildContext context,
    String currency,
    String address,
    String uriScheme,
  ) {
    final bool isPlaceholder = address.startsWith('PLACEHOLDER');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(currency, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (!isPlaceholder) ...[
            Center(
              child: QrImageView(
                data: '$uriScheme:$address',
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  isPlaceholder ? 'Address coming soon' : address,
                  style: TextStyle(
                    fontFamily: isPlaceholder ? null : 'monospace',
                    fontSize: 12,
                    fontStyle: isPlaceholder ? FontStyle.italic : null,
                  ),
                ),
              ),
              if (!isPlaceholder)
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () => _copyAddress(context, address),
                  tooltip: 'Copy address',
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildWhatYourSupportEnables() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What Your Support Enables',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Continued development and maintenance'),
            SizedBox(height: 4),
            Text('• Expanded language coverage (Latin, Hebrew, Egyptian)'),
            SizedBox(height: 4),
            Text('• Text-to-speech integration'),
            SizedBox(height: 4),
            Text('• Server costs for demo instances'),
            SizedBox(height: 4),
            Text('• Curated learning materials and grammar references'),
            SizedBox(height: 12),
            Text(
              'Thank you for supporting open scholarship!',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse('$url?utm_source=app&utm_medium=support_page');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $url')),
        );
      }
    }
  }

  void _copyAddress(BuildContext context, String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied to clipboard')),
    );
  }
}
