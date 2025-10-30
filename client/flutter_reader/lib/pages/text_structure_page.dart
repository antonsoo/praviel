/// Page for selecting a book or section within a classical text.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_providers.dart';
import '../models/reader.dart';
import '../services/haptic_service.dart';
import '../services/reader_fallback_catalog.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_3d_animations.dart';
import 'passage_selection_page.dart';
import 'reading_page.dart';

/// Provider for text structure
final textStructureProvider = FutureProvider.autoDispose
    .family<TextStructureResponse, int>((ref, textId) async {
      if (textId < 0) {
        final fallback = ReaderFallbackCatalog.structureFor(textId);
        if (fallback != null) {
          return fallback;
        }
        throw Exception(
          'No fallback structure defined for textId '
          '\${textId}',
        );
      }
      final api = ref.watch(textReaderApiProvider);
      return api.getTextStructure(textId: textId);
    });

/// Page showing the structure of a text work (books, chapters, or pages).
class TextStructurePage extends ConsumerWidget {
  const TextStructurePage({required this.textWork, super.key});

  final TextWorkInfo textWork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final structureAsync = ref.watch(textStructureProvider(textWork.id));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              textWork.title,
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              textWork.author,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () => _showLicenseDialog(context),
            tooltip: 'License info',
          ),
        ],
      ),
      body: structureAsync.when(
        data: (response) =>
            _buildStructure(context, theme, colorScheme, response),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            _buildErrorState(context, theme, colorScheme, error, ref),
      ),
    );
  }

  Widget _buildStructure(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextStructureResponse response,
  ) {
    final structure = response.structure;

    // Handle different reference schemes
    if (structure.refScheme == 'book.line' && structure.books != null) {
      return _buildBookLineStructure(context, theme, colorScheme, structure);
    } else if (structure.refScheme == 'stephanus' && structure.pages != null) {
      return _buildStephanusStructure(context, theme, colorScheme, structure);
    } else if (structure.refScheme == 'section' && structure.chapters != null) {
      return _buildSectionStructure(context, theme, colorScheme, structure);
    } else {
      return _buildGenericStructure(context, theme, colorScheme, structure);
    }
  }

  Widget _buildBookLineStructure(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextStructure structure,
  ) {
    final books = structure.books!;

    return CustomScrollView(
      slivers: [
        _buildActionPanel(context, theme, colorScheme, structure),
        // Header with stats
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: RotatingCard(
              maxRotation: 0.04,
              child: Container(
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
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    Text(
                      '${books.length}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      'Books',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      'Select a book to read',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Book grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            VibrantSpacing.lg,
            0,
            VibrantSpacing.lg,
            VibrantSpacing.xl,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisSpacing: VibrantSpacing.md,
              crossAxisSpacing: VibrantSpacing.md,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final book = books[index];
              return _buildBookCard(
                context,
                theme,
                colorScheme,
                book,
                structure,
              );
            }, childCount: books.length),
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    BookInfo book,
    TextStructure structure,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () {
          HapticService.light();
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => PassageSelectionPage(
                textWork: textWork,
                structure: structure,
                selectedBook: book.book,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Book number
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    book.book.toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),

              // "Book X" label
              Text(
                'Book ${book.book}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: VibrantSpacing.xs),

              // Line count
              Text(
                '${book.lineCount} lines',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              // Line range
              Text(
                '${book.firstLine}-${book.lastLine}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStephanusStructure(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextStructure structure,
  ) {
    final pages = structure.pages!;

    return CustomScrollView(
      slivers: [
        _buildActionPanel(context, theme, colorScheme, structure),
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: RotatingCard(
              maxRotation: 0.04,
              child: Container(
                padding: const EdgeInsets.all(VibrantSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.tertiaryContainer,
                      colorScheme.primaryContainer,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(VibrantRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.tertiary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.format_list_numbered_rounded,
                      size: 48,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    Text(
                      '${pages.length}',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      'Stephanus Pages',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      'Standard reference system for Plato',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onTertiaryContainer.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Page grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            VibrantSpacing.lg,
            0,
            VibrantSpacing.lg,
            VibrantSpacing.xl,
          ),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100,
              mainAxisSpacing: VibrantSpacing.sm,
              crossAxisSpacing: VibrantSpacing.sm,
              childAspectRatio: 1.2,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final page = pages[index];
              return _buildPageCard(
                context,
                theme,
                colorScheme,
                page,
                structure,
              );
            }, childCount: pages.length),
          ),
        ),
      ],
    );
  }

  Widget _buildPageCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    String page,
    TextStructure structure,
  ) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          HapticService.light();
          // For Stephanus pages, we'll show a single page at a time
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => PassageSelectionPage(
                textWork: textWork,
                structure: structure,
                selectedPage: page,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        child: Center(
          child: Text(
            page,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenericStructure(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextStructure structure,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: VibrantSpacing.lg),
            Text(
              'Unsupported Structure',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'This text uses a reference scheme (${structure.refScheme}) '
              'that is not yet supported.',
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


Widget _buildSectionStructure(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextStructure structure,
  ) {
    final sections = structure.chapters ?? const <Map<String, dynamic>>[];

    return CustomScrollView(
      slivers: [
        _buildActionPanel(context, theme, colorScheme, structure),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            VibrantSpacing.lg,
            VibrantSpacing.lg,
            VibrantSpacing.lg,
            VibrantSpacing.xxxl,
          ),
          sliver: SliverList.separated(
            itemBuilder: (context, index) {
              final section = sections[index];
              final label = section['label'] as String? ?? 'Section ${index + 1}';
              final refStart = section['ref_start'] as String? ?? '';
              final refEnd = section['ref_end'] as String? ?? refStart;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VibrantRadius.lg),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(VibrantSpacing.lg),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      (index + 1).toString(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '$refStart — $refEnd',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Icon(
                    Icons.auto_stories_rounded,
                    color: colorScheme.primary,
                  ),
                  onTap: () {
                    HapticService.light();
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => ReadingPage(
                          textWork: textWork,
                          refStart: refStart,
                          refEnd: refEnd,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            separatorBuilder: (context, index) =>
                const SizedBox(height: VibrantSpacing.sm),
            itemCount: sections.length,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _buildActionPanel(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextStructure structure,
  ) {
    final isFallback = _isFallbackWork();
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VibrantSpacing.lg,
          VibrantSpacing.lg,
          VibrantSpacing.lg,
          VibrantSpacing.sm,
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                    Expanded(
                      child: Text(
                        textWork.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isFallback)
                      Chip(
                        avatar: const Icon(Icons.offline_bolt_outlined, size: 16),
                        label: const Text('Curated fallback'),
                        backgroundColor: colorScheme.tertiaryContainer,
                        labelStyle: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Wrap(
                  spacing: VibrantSpacing.sm,
                  runSpacing: VibrantSpacing.xs,
                  children: [
                    _buildChip(
                      theme,
                      colorScheme,
                      Icons.person_outline_rounded,
                      textWork.author,
                    ),
                    _buildChip(
                      theme,
                      colorScheme,
                      Icons.source_outlined,
                      textWork.sourceTitle,
                    ),
                    _buildChip(
                      theme,
                      colorScheme,
                      Icons.gavel_outlined,
                      textWork.licenseName,
                    ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.lg),
                Wrap(
                  spacing: VibrantSpacing.sm,
                  runSpacing: VibrantSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _quickStartReading(context, structure),
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: const Text('Quick start'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showMetadataSheet(context),
                      icon: const Icon(Icons.info_outline_rounded),
                      label: const Text('View metadata'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _quickStartReading(BuildContext context, TextStructure structure) {
    HapticService.light();
    final random = Random();
    if (structure.refScheme == 'book.line' &&
        structure.books != null &&
        structure.books!.isNotEmpty) {
      final books = structure.books!;
      final book = books[random.nextInt(books.length)];
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => PassageSelectionPage(
            textWork: textWork,
            structure: structure,
            selectedBook: book.book,
          ),
        ),
      );
      return;
    }
    if (structure.refScheme == 'stephanus' &&
        structure.pages != null &&
        structure.pages!.isNotEmpty) {
      final page = structure.pages![random.nextInt(structure.pages!.length)];
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => PassageSelectionPage(
            textWork: textWork,
            structure: structure,
            selectedPage: page,
          ),
        ),
      );
      return;
    }
    if (structure.refScheme == 'section' &&
        structure.chapters != null &&
        structure.chapters!.isNotEmpty) {
      final chapter =
          structure.chapters![random.nextInt(structure.chapters!.length)];
      final refStart = chapter['ref_start'] as String? ?? '';
      final refEnd = chapter['ref_end'] as String? ?? refStart;
      if (refStart.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => ReadingPage(
              textWork: textWork,
              refStart: refStart,
              refEnd: refEnd,
            ),
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Unable to quick-start this text yet'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Browse',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => PassageSelectionPage(
                  textWork: textWork,
                  structure: structure,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showMetadataSheet(BuildContext context) {
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
              Text(
                textWork.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                'Author: ${textWork.author}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                'Source: ${textWork.sourceTitle}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                'License: ${textWork.licenseName}',
                style: theme.textTheme.bodyMedium,
              ),
              if (textWork.licenseUrl != null &&
                  textWork.licenseUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: VibrantSpacing.sm),
                SelectableText(
                  textWork.licenseUrl!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
              if (_isFallbackWork()) ...[
                const SizedBox(height: VibrantSpacing.lg),
                Text(
                  'Fallback notice:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  'This text comes from the offline fallback catalog. Once the live corpus is available, you will see even more passages and metadata automatically.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: VibrantSpacing.xl),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isFallbackWork() {
    return textWork.id < 0 ||
        textWork.sourceTitle.toLowerCase().contains('fallback') ||
        textWork.sourceTitle.toLowerCase().contains('curated');
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
              'Failed to load structure',
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
              onPressed: () {
                HapticService.medium();
                ref.invalidate(textStructureProvider(textWork.id));
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Retry'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text('${textWork.title} - License'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'License: ${textWork.licenseName}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  'Source: ${textWork.sourceTitle}',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  'This text is freely available for educational purposes under '
                  '${textWork.licenseName}. You may share and adapt it with '
                  'proper attribution.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (textWork.licenseUrl != null) ...[
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    'Full license: ${textWork.licenseUrl}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
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
