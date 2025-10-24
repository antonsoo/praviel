/// Page for browsing available classical texts in the Reader feature.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_providers.dart';
import '../models/language.dart';
import '../models/reader.dart';
import '../services/haptic_service.dart';
import '../services/language_preferences.dart';
import '../services/reader_fallback_catalog.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/premium_buttons.dart';
import '../widgets/premium_cards.dart';
import '../widgets/lesson_loading_screen.dart';
import '../widgets/surface.dart';
import '../widgets/transitions/premium_page_transitions.dart';
import 'text_structure_page.dart';

/// Provider for text list
final textListProvider = FutureProvider.autoDispose
    .family<TextListResponse, String>((ref, language) async {
      final api = ref.watch(textReaderApiProvider);
      return api.getTexts(language: language);
    });

/// Page showing all available classical texts for reading.
class TextLibraryPage extends ConsumerStatefulWidget {
  const TextLibraryPage({super.key});

  @override
  ConsumerState<TextLibraryPage> createState() => _TextLibraryPageState();
}

class _TextLibraryPageState extends ConsumerState<TextLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _includeLive = true;
  bool _includeFallback = true;
  final Set<String> _selectedSchemes = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (_query != next) {
        setState(() => _query = next);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final languageCode = ref.watch(selectedLanguageProvider);
    final languageInfo = availableLanguages.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => availableLanguages.first,
    );
    final textList = ref.watch(textListProvider(languageCode));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '${languageInfo.name} Texts',
          style: const TextStyle(fontWeight: FontWeight.w900),
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
        data: (response) {
          final usingFallback =
              response.texts.isEmpty &&
              ReaderFallbackCatalog.hasLanguage(languageCode);
          final baseWorks = usingFallback
              ? ReaderFallbackCatalog.worksForLanguage(languageCode)
              : response.texts;
          final filtered = _filterWorks(baseWorks);
          final schemes = baseWorks.map((w) => w.refScheme).toSet();
          return _buildTextList(
            context,
            theme,
            colorScheme,
            filtered,
            languageInfo,
            usingFallback: usingFallback,
            refreshProvider: () =>
                ref.refresh(textListProvider(languageCode).future),
            searchController: _searchController,
            hasActiveFilter:
                _query.isNotEmpty ||
                !_includeLive ||
                !_includeFallback ||
                _selectedSchemes.isNotEmpty,
            totalCount: baseWorks.length,
            allSchemes: schemes,
          );
        },
        loading: () => LessonLoadingScreen(
          languageCode: languageCode,
          headline: 'Loading ${languageInfo.name} library…',
          statusMessage: 'Fetching curated texts, morphology, and metadata.',
        ),
        error: (error, stack) {
          if (ReaderFallbackCatalog.hasLanguage(languageCode)) {
            final baseWorks = ReaderFallbackCatalog.worksForLanguage(
              languageCode,
            );
            final filtered = _filterWorks(baseWorks);
            final schemes = baseWorks.map((w) => w.refScheme).toSet();
            return _buildTextList(
              context,
              theme,
              colorScheme,
              filtered,
              languageInfo,
              usingFallback: true,
              refreshProvider: () =>
                  ref.refresh(textListProvider(languageCode).future),
              fallbackError: error.toString(),
              searchController: _searchController,
              hasActiveFilter:
                  _query.isNotEmpty ||
                  !_includeLive ||
                  !_includeFallback ||
                  _selectedSchemes.isNotEmpty,
              totalCount: baseWorks.length,
              allSchemes: schemes,
            );
          }
          return _buildErrorState(
            context,
            theme,
            colorScheme,
            error,
            languageCode,
            ref,
          );
        },
      ),
    );
  }

  Widget _buildTextList(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    List<TextWorkInfo> works,
    LanguageInfo languageInfo, {
    required bool usingFallback,
    required Future<TextListResponse> Function() refreshProvider,
    String? fallbackError,
    required TextEditingController searchController,
    required bool hasActiveFilter,
    required int totalCount,
    required Set<String> allSchemes,
  }) {
    final sortedSchemes = allSchemes.toList()..sort();
    if (works.isEmpty) {
      if (hasActiveFilter) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 80,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: VibrantSpacing.lg),
                Text(
                  'No matches found',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  'Try a different keyword or clear the search to see all $totalCount works.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VibrantSpacing.md),
                FilledButton.icon(
                  onPressed: searchController.clear,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Clear search'),
                ),
              ],
            ),
          ),
        );
      }

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
                'No texts available yet',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                'Check back soon for ${languageInfo.name} excerpts',
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

    final textsByAuthor = <String, List<TextWorkInfo>>{};
    for (final text in works) {
      textsByAuthor.putIfAbsent(text.author, () => []).add(text);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await refreshProvider();
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(VibrantSpacing.lg),
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(VibrantRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.18),
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
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    hasActiveFilter
                        ? '${works.length} of $totalCount'
                        : '${works.length}',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    languageInfo.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.sm),
                  if (usingFallback)
                    Chip(
                      avatar: const Icon(Icons.offline_bolt_outlined, size: 16),
                      label: const Text('Curated fallback catalog'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: colorScheme.tertiaryContainer.withValues(
                        alpha: 0.9,
                      ),
                      labelStyle: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: VibrantSpacing.sm),
                  Text(
                    usingFallback
                        ? 'Curated fallback excerpts ready to explore'
                        : 'From the Perseus Digital Library corpus',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (fallbackError != null) ...[
                    const SizedBox(height: VibrantSpacing.md),
                    Text(
                      'Live corpus unavailable: $fallbackError',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: VibrantSpacing.md),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: hasActiveFilter
                          ? IconButton(
                              tooltip: 'Clear search',
                              onPressed: searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            )
                          : null,
                      labelText: 'Search works or authors',
                    ),
                  ),
                  if (hasActiveFilter) ...[
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      'Showing ${works.length} result${works.length == 1 ? '' : 's'} for "${searchController.text}".',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: VibrantSpacing.sm),
                  Wrap(
                    spacing: VibrantSpacing.sm,
                    runSpacing: VibrantSpacing.sm,
                    children: [
                      FilterChip(
                        label: const Text('Live corpus'),
                        selected: _includeLive,
                        onSelected: (value) {
                          setState(() {
                            _includeLive = value;
                            if (!_includeLive && !_includeFallback) {
                              _includeFallback = true;
                            }
                          });
                        },
                      ),
                      FilterChip(
                        label: const Text('Fallback catalog'),
                        selected: _includeFallback,
                        onSelected: (value) {
                          setState(() {
                            _includeFallback = value;
                            if (!_includeFallback && !_includeLive) {
                              _includeLive = true;
                            }
                          });
                        },
                      ),
                      for (final scheme in sortedSchemes)
                        FilterChip(
                          label: Text(_schemeLabel(scheme)),
                          selected: _selectedSchemes.contains(scheme),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedSchemes.add(scheme);
                              } else {
                                _selectedSchemes.remove(scheme);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: VibrantSpacing.lg),
                  Wrap(
                    spacing: VibrantSpacing.sm,
                    runSpacing: VibrantSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openRandomText(context, works),
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Surprise me'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _showCatalogInfo(
                          context,
                          languageInfo,
                          usingFallback,
                        ),
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('Catalog info'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
                        Text(
                          '${texts.length} work${texts.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.lg,
                    vertical: VibrantSpacing.sm,
                  ),
                  sliver: SliverList.separated(
                    itemBuilder: (context, index) {
                      final textWork = texts[index];
                      return _buildTextCard(
                        context,
                        theme,
                        colorScheme,
                        textWork,
                      );
                    },
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: VibrantSpacing.sm),
                    itemCount: texts.length,
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  List<TextWorkInfo> _filterWorks(List<TextWorkInfo> works) {
    return works
        .where((text) {
          final isFallback = _isFallback(text);
          if (isFallback && !_includeFallback) return false;
          if (!isFallback && !_includeLive) return false;
          if (_selectedSchemes.isNotEmpty &&
              !_selectedSchemes.contains(text.refScheme)) {
            return false;
          }
          if (_query.isNotEmpty) {
            final preview = isFallback
                ? ReaderFallbackCatalog.previewFor(text.id)
                : text.preview;
            final haystack =
                ('${text.title} ${text.author} ${text.sourceTitle} ${preview ?? ''}')
                    .toLowerCase();
            if (!haystack.contains(_query)) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);
  }

  Widget _buildTextCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextWorkInfo text,
  ) {
    final isFallback = _isFallback(text);
    final fallbackPreview = isFallback
        ? ReaderFallbackCatalog.previewFor(text.id)
        : null;
    final previewSnippet = (fallbackPreview ?? text.preview)?.trim();
    final displayPreview = previewSnippet != null && previewSnippet.length > 240
        ? '${previewSnippet.substring(0, 237).trimRight()}…'
        : previewSnippet;

    return ElevatedCard(
      elevation: 2,
      onTap: () {
        HapticService.medium();
        Navigator.push(
          context,
          SlideUpPageRoute(
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
              if (isFallback) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: VibrantSpacing.sm,
                    vertical: VibrantSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.offline_bolt_outlined,
                        size: 14,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fallback text',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VibrantSpacing.sm),
              ],
              Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
            ],
          ),

          if (displayPreview != null && displayPreview.isNotEmpty) ...[
            const SizedBox(height: VibrantSpacing.sm),
            Surface(
              backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              padding: const EdgeInsets.all(VibrantSpacing.sm),
              child: Text(
                displayPreview,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
          ],
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

          const SizedBox(height: VibrantSpacing.md),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () {
                  HapticService.light();
                  Navigator.push(
                    context,
                    SlideUpPageRoute(
                      builder: (context) => TextStructurePage(textWork: text),
                    ),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Browse sections'),
              ),
              const SizedBox(width: VibrantSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => _openQuickRead(context, text),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Quick read'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataChip(
    IconData icon,
    String label,
    ColorScheme colorScheme,
  ) {
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
    String languageCode,
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
              onPressed: () async {
                HapticService.medium();
                final _ = await ref.refresh(
                  textListProvider(languageCode).future,
                );
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

  void _openRandomText(BuildContext context, List<TextWorkInfo> works) {
    if (works.isEmpty) return;
    final random = Random();
    final choice = works[random.nextInt(works.length)];
    _openQuickRead(context, choice);
  }

  void _showCatalogInfo(
    BuildContext context,
    LanguageInfo language,
    bool usingFallback,
  ) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        return Padding(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: colorScheme.primary),
                  const SizedBox(width: VibrantSpacing.sm),
                  Text(
                    '${language.name} catalog',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.lg),
              Text(
                usingFallback
                    ? 'You are viewing curated fallback readings while the live corpus is offline. These excerpts are hand-picked to demonstrate the reader experience.'
                    : 'These texts come directly from our live corpus (Perseus Digital Library) with morphology, licensing, and metadata preserved.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VibrantSpacing.lg),
              Text(
                'Tip: Use “Surprise me” to jump into a random work, or tap the quick read button on any card to start reading immediately.',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VibrantSpacing.xl),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _schemeLabel(String refScheme) {
    switch (refScheme) {
      case 'book.line':
        return 'Book · line';
      case 'stephanus':
        return 'Stephanus pages';
      case 'chapter.verse':
        return 'Chapter · verse';
      default:
        return refScheme;
    }
  }

  bool _isFallback(TextWorkInfo text) {
    return text.id < 0 ||
        text.sourceTitle.toLowerCase().contains('fallback') ||
        text.sourceTitle.toLowerCase().contains('curated');
  }

  void _openQuickRead(BuildContext context, TextWorkInfo textWork) {
    HapticService.light();
    Navigator.push(
      context,
      SlideUpPageRoute(
        builder: (context) => TextStructurePage(textWork: textWork),
      ),
    );
  }
}
