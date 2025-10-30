/// Page for reading a passage of classical Greek text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_providers.dart';
import '../models/reader.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/interactive_text.dart';
import '../widgets/premium_snackbars.dart';
import '../services/reader_fallback_catalog.dart';
import '../widgets/premium_buttons.dart';
import '../widgets/premium_cards.dart';
import '../services/haptic_service.dart';
import '../widgets/lesson_loading_screen.dart';
import '../services/fun_fact_catalog.dart';
import '../widgets/reader/premium_word_popup.dart';
import '../widgets/reader/premium_text_settings.dart';

/// Provider for text segments
final textSegmentsProvider = FutureProvider.autoDispose
    .family<TextSegmentsResponse, _SegmentRequest>((ref, request) async {
      if (request.textId < 0) {
        final fallback = ReaderFallbackCatalog.segmentsFor(
          request.textId,
          request.refStart,
          request.refEnd,
        );
        if (fallback != null) {
          return fallback;
        }
        throw Exception(
          'No fallback segments defined for textId '
          '\${request.textId}',
        );
      }
      final api = ref.watch(textReaderApiProvider);
      return api.getTextSegments(
        textId: request.textId,
        refStart: request.refStart,
        refEnd: request.refEnd,
      );
    });

/// Request parameters for text segments
class _SegmentRequest {
  const _SegmentRequest({
    required this.textId,
    required this.refStart,
    required this.refEnd,
  });

  final int textId;
  final String refStart;
  final String refEnd;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SegmentRequest &&
          runtimeType == other.runtimeType &&
          textId == other.textId &&
          refStart == other.refStart &&
          refEnd == other.refEnd;

  @override
  int get hashCode => Object.hash(textId, refStart, refEnd);
}

/// Page for reading a passage of Greek text.
class ReadingPage extends ConsumerStatefulWidget {
  const ReadingPage({
    required this.textWork,
    required this.refStart,
    required this.refEnd,
    super.key,
  });

  final TextWorkInfo textWork;
  final String refStart;
  final String refEnd;

  @override
  ConsumerState<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends ConsumerState<ReadingPage>
    with SingleTickerProviderStateMixin {
  double _fontSize = 20.0;
  double _lineHeight = 1.8;
  bool _showTransliteration = false;
  final Set<String> _knownWords = {};

  bool _funFactTriggered = false;
  bool _funFactSheetOpen = false;
  int _funFactIndex = 0;

  // Word definition cache: word -> (lemma, morph)
  final Map<String, (String?, String?)> _wordCache = {};

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleWordTap(String word) async {
    // Remove punctuation
    final cleanWord = word.replaceAll(RegExp(r'[.,;:!?·—]'), '');
    if (cleanWord.isEmpty) return;

    String? lemma;
    String? morph;

    // Check cache first
    if (_wordCache.containsKey(cleanWord)) {
      final cached = _wordCache[cleanWord]!;
      lemma = cached.$1;
      morph = cached.$2;
    } else {
      // Cache miss - fetch from API
      try {
        final api = ref.read(textReaderApiProvider);
        final response = await api.analyzeText(
          text: cleanWord,
          language: widget.textWork.language,
        );

        if (!mounted) return;

        // Store in cache
        lemma = response.tokens.isNotEmpty ? response.tokens.first.lemma : null;
        morph = response.tokens.isNotEmpty ? response.tokens.first.morph : null;
        _wordCache[cleanWord] = (lemma, morph);
      } catch (e) {
        if (!mounted) return;
        PremiumSnackBar.error(
          context,
          title: 'Analysis Failed',
          message: 'Could not analyze word: $e',
        );
        return;
      }
    }

    if (!mounted) return;

    // Show premium word analysis popup
    final api = ref.read(textReaderApiProvider);
    await PremiumWordPopup.show(
      context: context,
      word: cleanWord,
      lemma: lemma,
      morph: morph,
      onAddToSRS: () async {
        HapticService.medium();

        // Show loading toast
        if (mounted) {
          FloatingToast.show(
            context,
            message: 'Adding to SRS...',
            icon: Icons.schedule_rounded,
          );
        }

        try {
          // Call the backend API
          await api.addToSRS(word: cleanWord, lemma: lemma);

          if (mounted) {
            setState(() => _knownWords.add(cleanWord));
            PremiumSnackBar.success(
              context,
              title: 'Card Created',
              message: 'Added "$cleanWord" to your SRS deck',
            );
          }
        } catch (e) {
          if (mounted) {
            PremiumSnackBar.error(
              context,
              title: 'Failed',
              message: 'Could not add to SRS: $e',
              );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final request = _SegmentRequest(
      textId: widget.textWork.id,
      refStart: widget.refStart,
      refEnd: widget.refEnd,
    );

    final segmentsAsync = ref.watch(textSegmentsProvider(request));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.textWork.title,
              style: GoogleFonts.notoSerif(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${widget.refStart} – ${widget.refEnd}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_fields_rounded),
            onPressed: () {
              HapticService.light();
              _showTextSettingsDialog(context);
            },
            tooltip: 'Text settings',
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline_rounded),
            onPressed: () {
              HapticService.light();
              _showCompletionFact();
            },
            tooltip: 'Show fun fact',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
              HapticService.light();
              final response = segmentsAsync.asData?.value;
              _showInfoDialog(context, response);
            },
            tooltip: 'About this passage',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: segmentsAsync.when(
          data: (response) =>
              _buildReadingView(context, theme, colorScheme, response),
          loading: () => LessonLoadingScreen(
            languageCode: widget.textWork.language,
            headline: 'Preparing your reading session...',
            statusMessage:
                "Fetching the passage, morphology, and reference notes. Keep this tab open while we assemble your reader experience.",
          ),
          error: (error, stack) =>
              _buildErrorState(context, theme, colorScheme, error, ref, request),
        ),
      ),
    );
  }

  Widget _buildReadingView(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    TextSegmentsResponse response,
  ) {
    if (response.segments.isEmpty) {
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
                'No text found',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Text(
                'The selected range contains no text segments.',
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

    if (!_funFactSheetOpen) {
      _funFactTriggered = false;
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Attribution header with premium card
          ElevatedCard(
            elevation: 1,
            padding: const EdgeInsets.all(VibrantSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                    Expanded(
                      child: Text(
                        '${response.textInfo['author']} - ${response.textInfo['title']}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Wrap(
                  spacing: VibrantSpacing.sm,
                  runSpacing: VibrantSpacing.xs,
                  children: [
                    _buildMetaChip(
                      theme,
                      colorScheme,
                      Icons.source_outlined,
                      response.textInfo['source'] as String? ??
                          widget.textWork.sourceTitle,
                    ),
                    _buildMetaChip(
                      theme,
                      colorScheme,
                      Icons.policy_outlined,
                      response.textInfo['license'] as String? ??
                          widget.textWork.licenseName,
                    ),
                    _buildMetaChip(
                      theme,
                      colorScheme,
                      Icons.calendar_month_outlined,
                      '${response.segments.length} segment${response.segments.length == 1 ? '' : 's'}',
                    ),
                    if (_isFallbackWork())
                      _buildMetaChip(
                        theme,
                        colorScheme,
                        Icons.offline_bolt_outlined,
                        'Fallback catalog',
                        highlight: true,
                      ),
                  ],
                ),
                if (_isFallbackWork()) ...[
                  const SizedBox(height: VibrantSpacing.sm),
                  Text(
                    'This passage comes from our offline curated set while the live corpus is unavailable.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Text segments
          ...response.segments.map((segment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.lg),
              child: _buildSegment(theme, colorScheme, segment),
            );
          }),

          const SizedBox(height: VibrantSpacing.xl),

          // License footer with premium card
          ElevatedCard(
            elevation: 1,
            padding: const EdgeInsets.all(VibrantSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: VibrantSpacing.sm),
                    Text(
                      'License',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  response.textInfo['license'] as String? ?? 'Unknown license',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (response.textInfo['license_url'] != null) ...[
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    response.textInfo['license_url'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_funFactTriggered &&
        !_funFactSheetOpen &&
        notification.metrics.maxScrollExtent > 0 &&
        notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 48 &&
        notification is ScrollEndNotification) {
      _funFactTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCompletionFact();
        }
      });
    }
    return false;
  }

  void _showCompletionFact() {
    final facts = FunFactCatalog.factsForLanguage(widget.textWork.language);
    if (facts.isEmpty) return;
    if (_funFactSheetOpen) return;
    HapticService.light();
    setState(() {
      _funFactSheetOpen = true;
      if (facts.isNotEmpty) {
        _funFactIndex = _funFactIndex % facts.length;
      }
    });
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        int localIndex = _funFactIndex % facts.length;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final fact = facts[localIndex % facts.length];
            final category = fact['category'] ?? 'Fun fact';
            final factText = fact['fact'] ?? '';
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            return Padding(
              padding: const EdgeInsets.all(VibrantSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.sm),
                  Text(
                    factText,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            localIndex = (localIndex + 1) % facts.length;
                            _funFactIndex = localIndex;
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Another fact'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _funFactSheetOpen = false;
        });
      }
    });
  }

  Widget _buildSegment(
    ThemeData theme,
    ColorScheme colorScheme,
    SegmentWithMeta segment,
  ) {
    return ElevatedCard(
      elevation: 2,
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reference number
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.sm,
              vertical: VibrantSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(VibrantRadius.sm),
            ),
            child: Text(
              segment.ref,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),

          const SizedBox(height: VibrantSpacing.md),

          // Interactive Greek text with word tapping
          InteractiveText(
            text: segment.text,
            fontSize: _fontSize,
            lineHeight: _lineHeight,
            onWordTap: _handleWordTap,
            highlightedWords: _knownWords,
          ),

          // Optional transliteration (placeholder for future feature)
          if (_showTransliteration) ...[
            const SizedBox(height: VibrantSpacing.sm),
            const Divider(),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              '[Transliteration coming soon]',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    Object error,
    WidgetRef ref,
    _SegmentRequest request,
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
              'Failed to load passage',
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
                ref.invalidate(textSegmentsProvider(request));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTextSettingsDialog(BuildContext context) {
    PremiumTextSettings.show(
      context: context,
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      showTransliteration: _showTransliteration,
      onFontSizeChanged: (value) => setState(() => _fontSize = value),
      onLineHeightChanged: (value) => setState(() => _lineHeight = value),
      onTransliterationToggled: (value) =>
          setState(() => _showTransliteration = value),
    );
  }

  void _showInfoDialog(BuildContext context, TextSegmentsResponse? response) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('About This Passage'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(theme, 'Work', widget.textWork.title),
                _buildInfoRow(theme, 'Author', widget.textWork.author),
                _buildInfoRow(
                  theme,
                  'Reference',
                  '${widget.refStart} – ${widget.refEnd}',
                ),
                if (response != null) ...[
                  _buildInfoRow(
                    theme,
                    'Segments',
                    '${response.segments.length}',
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  const Divider(),
                  const SizedBox(height: VibrantSpacing.md),
                  _buildInfoRow(
                    theme,
                    'Source',
                    response.textInfo['source'] as String? ?? 'Unknown',
                  ),
                  _buildInfoRow(
                    theme,
                    'License',
                    response.textInfo['license'] as String? ?? 'Unknown',
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

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  bool _isFallbackWork() {
    return widget.textWork.id < 0 ||
        widget.textWork.sourceTitle.toLowerCase().contains('fallback') ||
        widget.textWork.sourceTitle.toLowerCase().contains('curated');
  }

  Widget _buildMetaChip(
    ThemeData theme,
    ColorScheme colorScheme,
    IconData icon,
    String label, {
    bool highlight = false,
  }) {
    final background = highlight
        ? colorScheme.tertiaryContainer
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);
    final textColor =
        highlight ? colorScheme.onTertiaryContainer : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
