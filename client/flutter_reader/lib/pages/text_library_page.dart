/// Page for browsing available classical texts in the Reader feature.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_providers.dart';
import '../models/reader.dart';
import '../theme/vibrant_theme.dart';
import '../services/haptic_service.dart';
import '../widgets/premium_buttons.dart';
import '../widgets/premium_cards.dart';
import 'text_structure_page.dart';

/// Provider for text list
final textListProvider = FutureProvider.autoDispose<TextListResponse>((ref) async {
  final api = ref.watch(textReaderApiProvider);
  return api.getTexts(language: 'grc');
});

/// Page showing all available classical texts for reading.
class TextLibraryPage extends ConsumerWidget {
  const TextLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textList = ref.watch(textListProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Classical Texts',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              HapticService.light();
              _showAboutDialog(context);
            },
            tooltip: 'About these texts',
          ),
        ],
      ),
      body: textList.when(
        data: (response) => _buildTextList(context, theme, colorScheme, response),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, theme, colorScheme, error, ref),
      ),
    );
  }

  Widget _buildTextList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextListResponse response,
  ) {
    if (response.texts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.library_books_outlined,
                size: 80,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: VibrantSpacing.lg),
              Text(
                'No texts available',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                'Check back later for classical texts',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group texts by author
    final textsByAuthor = <String, List<TextWorkInfo>>{};
    for (final text in response.texts) {
      textsByAuthor.putIfAbsent(text.author, () => []).add(text);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger refresh by invalidating the provider
        // ref.invalidate(textListProvider);
      },
      child: CustomScrollView(
        slivers: [
          // Header with stats
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(VibrantSpacing.lg),
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(VibrantRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    '${response.texts.length}',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    'Classical Greek Texts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.sm),
                  Text(
                    'From the Perseus Digital Library',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Texts grouped by author
          ...textsByAuthor.entries.map((entry) {
            final author = entry.key;
            final texts = entry.value;

            return SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VibrantSpacing.lg,
                      VibrantSpacing.xl,
                      VibrantSpacing.lg,
                      VibrantSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getAuthorIcon(author),
                          color: colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: VibrantSpacing.md),
                        Text(
                          author,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.sm,
                            vertical: VibrantSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(VibrantRadius.sm),
                          ),
                          child: Text(
                            '${texts.length} ${texts.length == 1 ? 'text' : 'texts'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.lg),
                  sliver: SliverList.builder(
                    itemCount: texts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
                        child: _buildTextCard(context, theme, colorScheme, texts[index]),
                      );
                    },
                  ),
                ),
              ],
            );
          }),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: VibrantSpacing.xl),
          ),
        ],
      ),
    );
  }

  Widget _buildTextCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextWorkInfo text,
  ) {
    return ElevatedCard(
      elevation: 2,
      onTap: () {
        HapticService.medium();
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => TextStructurePage(textWork: text),
          ),
        );
      },
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Title in Greek font
              Expanded(
                child: Text(
                  text.title,
                  style: GoogleFonts.notoSerif(
                    textStyle: theme.textTheme.headlineSmall,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.sm),

          // Metadata row
          Wrap(
            spacing: VibrantSpacing.md,
            runSpacing: VibrantSpacing.xs,
            children: [
              _buildMetadataChip(
                Icons.article_outlined,
                '${text.segmentCount.toString()} ${_getRefLabel(text.refScheme)}',
                colorScheme,
              ),
              _buildMetadataChip(
                Icons.schema_outlined,
                _getRefSchemeLabel(text.refScheme),
                colorScheme,
              ),
              _buildMetadataChip(
                Icons.shield_outlined,
                text.licenseName,
                colorScheme,
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.sm),

          // Source info
          Row(
            children: [
              Icon(
                Icons.source_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: VibrantSpacing.xs),
              Expanded(
                child: Text(
                  text.sourceTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Object error,
    WidgetRef ref,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'Failed to load texts',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: VibrantSpacing.xl),
            PremiumButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: () {
                HapticService.medium();
                ref.invalidate(textListProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAuthorIcon(String author) {
    switch (author.toLowerCase()) {
      case 'homer':
        return Icons.castle_outlined;
      case 'plato':
        return Icons.psychology_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _getRefLabel(String refScheme) {
    switch (refScheme) {
      case 'book.line':
        return 'lines';
      case 'stephanus':
        return 'pages';
      case 'chapter.verse':
        return 'verses';
      default:
        return 'segments';
    }
  }

  String _getRefSchemeLabel(String refScheme) {
    switch (refScheme) {
      case 'book.line':
        return 'Book.Line';
      case 'stephanus':
        return 'Stephanus';
      case 'chapter.verse':
        return 'Chapter.Verse';
      default:
        return refScheme;
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('About These Texts'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'All texts are provided by the Perseus Digital Library at Tufts University.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  'License: Creative Commons Attribution-ShareAlike 3.0 (CC BY-SA 3.0)',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  'These are scholarly editions of classical Greek texts, digitized and made freely available for educational purposes.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  'Reference Schemes:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  '• Book.Line - Homer\'s works (e.g., Il.1.1)\n'
                  '• Stephanus - Plato\'s dialogues (e.g., Apol.17a)\n'
                  '• Chapter.Verse - Biblical texts (future)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
