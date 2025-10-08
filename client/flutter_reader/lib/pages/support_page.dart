import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/professional_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/layout/section_header.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Support This Project'),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            ProSpacing.xl,
            ProSpacing.xl,
            ProSpacing.xl,
            ProSpacing.xxxl,
          ),
          children: [
            _buildIntro(context),
            const SizedBox(height: ProSpacing.xl),
            _buildSection(
              context,
              title: 'One-time donations',
              subtitle: 'Boost development with a quick contribution.',
              icon: Icons.flash_on_outlined,
              children: [
                _buildLinkButton(
                  context,
                  label: 'Stripe Payment',
                  url: _stripe,
                  icon: Icons.payment,
                ),
                _buildLinkButton(
                  context,
                  label: 'Ko-fi',
                  url: _kofi,
                  icon: Icons.coffee,
                ),
              ],
            ),
            const SizedBox(height: ProSpacing.xl),
            _buildSection(
              context,
              title: 'Recurring support',
              subtitle: 'Sustain roadmap velocity with monthly backing.',
              icon: Icons.favorite_outline,
              children: [
                _buildLinkButton(
                  context,
                  label: 'GitHub Sponsors',
                  url: _githubSponsors,
                  icon: Icons.favorite,
                ),
                _buildLinkButton(
                  context,
                  label: 'Patreon',
                  url: _patreon,
                  icon: Icons.people,
                ),
                _buildLinkButton(
                  context,
                  label: 'Liberapay',
                  url: _liberapay,
                  icon: Icons.card_giftcard,
                ),
              ],
            ),
            if (!_openCollective.startsWith('PLACEHOLDER')) ...[
              const SizedBox(height: ProSpacing.xl),
              _buildSection(
                context,
                title: 'Transparent funding',
                subtitle: 'Review line-item spending with full transparency.',
                icon: Icons.account_balance_outlined,
                children: [
                  _buildLinkButton(
                    context,
                    label: 'Open Collective',
                    url: _openCollective,
                    icon: Icons.account_balance,
                  ),
                ],
              ),
            ],
            const SizedBox(height: ProSpacing.xl),
            _buildCryptoSection(context),
            const SizedBox(height: ProSpacing.xl),
            _buildWhatYourSupportEnables(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PulseCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primary,
          colorScheme.primary.withValues(alpha: 0.65),
          colorScheme.secondary,
        ],
      ),
      padding: const EdgeInsets.all(ProSpacing.xl),
      borderRadius: BorderRadius.circular(ProRadius.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why support AncientLanguages?',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: ProSpacing.sm),
          Text(
            'Community funding keeps research-grade lexicon integrations, BYOK privacy, and new languages shipping at pace.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: ProSpacing.lg),
          Wrap(
            spacing: ProSpacing.sm,
            runSpacing: ProSpacing.sm,
            children: const [
              _SupportBadge(label: 'Perseus + LSJ citations'),
              _SupportBadge(label: 'Keys stay on-device'),
              _SupportBadge(label: 'Open source roadmap'),
              _SupportBadge(label: 'Latin + TTS coming'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    IconData? icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title,
          subtitle: subtitle,
          icon: icon ?? Icons.favorite_outline,
        ),
        const SizedBox(height: ProSpacing.md),
        PulseCard(
          color: colorScheme.surface,
          padding: const EdgeInsets.all(ProSpacing.lg),
          borderRadius: BorderRadius.circular(ProRadius.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: ProSpacing.sm),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkButton(
    BuildContext context, {
    required String label,
    required String url,
    required IconData icon,
  }) {
    final bool isPlaceholder = url.startsWith('PLACEHOLDER');

    return FilledButton.icon(
      onPressed: isPlaceholder ? null : () => _launchUrl(context, url),
      icon: Icon(icon, size: 18),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (isPlaceholder) ...[
              const SizedBox(width: ProSpacing.xs),
              Text(
                'Coming soon',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: ProSpacing.lg,
          vertical: ProSpacing.md,
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildCryptoSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Cryptocurrency donations',
          subtitle: 'Scan a QR code or copy a wallet address.',
          icon: Icons.currency_bitcoin,
        ),
        const SizedBox(height: ProSpacing.md),
        PulseCard(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ProRadius.xl),
          padding: EdgeInsets.zero,
          child: Theme(
            data: theme.copyWith(
              dividerColor: colorScheme.outline.withValues(alpha: 0.1),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: ProSpacing.lg,
                vertical: ProSpacing.md,
              ),
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: ProSpacing.lg,
                vertical: ProSpacing.md,
              ),
              title: Text(
                'Cryptocurrency wallets',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'BTC, ETH, and XMR options',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                _buildCryptoAddress(
                  context,
                  'Bitcoin (BTC)',
                  _btcAddress,
                  'bitcoin',
                ),
                const SizedBox(height: ProSpacing.md),
                _buildCryptoAddress(
                  context,
                  'Ethereum (ETH)',
                  _ethAddress,
                  'ethereum',
                ),
                const SizedBox(height: ProSpacing.md),
                _buildCryptoAddress(
                  context,
                  'Monero (XMR)',
                  _xmrAddress,
                  'monero',
                ),
              ],
            ),
          ),
        ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currency,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: ProSpacing.sm),
        if (!isPlaceholder) ...[
          Center(
            child: QrImageView(
              data: '$uriScheme:$address',
              version: QrVersions.auto,
              size: 180,
            ),
          ),
          const SizedBox(height: ProSpacing.sm),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                isPlaceholder ? 'Address coming soon' : address,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: isPlaceholder ? null : 'monospace',
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
      ],
    );
  }

  Widget _buildWhatYourSupportEnables(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'What your support enables',
          subtitle: 'Every contribution fuels research-grade language tools.',
          icon: Icons.rocket_launch_outlined,
        ),
        const SizedBox(height: ProSpacing.md),
        PulseCard(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(ProRadius.xl),
          padding: const EdgeInsets.all(ProSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SupportListItem(
                icon: Icons.auto_awesome,
                text: 'Continued feature development and maintenance',
              ),
              const SizedBox(height: ProSpacing.sm),
              _SupportListItem(
                icon: Icons.language,
                text: 'Expanded language coverage (Latin, Hebrew, Egyptian)',
              ),
              const SizedBox(height: ProSpacing.sm),
              _SupportListItem(
                icon: Icons.record_voice_over,
                text: 'Pronunciation and text-to-speech integrations',
              ),
              const SizedBox(height: ProSpacing.sm),
              _SupportListItem(
                icon: Icons.cloud_outlined,
                text: 'Hosting for public demos and classroom pilots',
              ),
              const SizedBox(height: ProSpacing.sm),
              _SupportListItem(
                icon: Icons.library_books_outlined,
                text: 'Curated grammar references and lesson authoring',
              ),
              const SizedBox(height: ProSpacing.lg),
              Text(
                'Thank you for supporting open scholarship!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse('$url?utm_source=app&utm_medium=support_page');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not open $url')));
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

class _SupportBadge extends StatelessWidget {
  const _SupportBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ProSpacing.md,
        vertical: ProSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(ProRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SupportListItem extends StatelessWidget {
  const _SupportListItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: ProSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
