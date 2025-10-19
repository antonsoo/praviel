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
import '../widgets/premium_buttons.dart';
import '../widgets/premium_cards.dart';
import '../services/haptic_service.dart';

/// Provider for text segments
final textSegmentsProvider = FutureProvider.autoDispose.family<TextSegmentsResponse, _SegmentRequest>(
  (ref, request) async {
    final api = ref.watch(textReaderApiProvider);
    return api.getTextSegments(
      textId: request.textId,
      refStart: request.refStart,
      refEnd: request.refEnd,
    );
  },
);

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

class _ReadingPageState extends ConsumerState<ReadingPage> {
  double _fontSize = 20.0;
  double _lineHeight = 1.8;
  bool _showTransliteration = false;
  final Set<String> _knownWords = {};

  // Word definition cache: word -> (lemma, morph)
  final Map<String, (String?, String?)> _wordCache = {};

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

    HapticService.light();

    // Show word analysis bottom sheet
    final api = ref.read(textReaderApiProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => WordAnalysisSheet(
        word: cleanWord,
        lemma: lemma,
        morph: morph,
        onAddToSRS: () async {
          Navigator.pop(context);

          HapticService.medium();

          // Show loading toast
          FloatingToast.show(
            context,
            message: 'Adding to SRS...',
            icon: Icons.schedule_rounded,
          );

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
      ),
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
      body: segmentsAsync.when(
        data: (response) => _buildReadingView(context, theme, colorScheme, response),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, theme, colorScheme, error, ref, request),
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

    return SingleChildScrollView(
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
                        '${response.textInfo['author']} – ${response.textInfo['title']}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.xs),
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
                        response.textInfo['source'] as String? ?? 'Unknown source',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildSegment(ThemeData theme, ColorScheme colorScheme, SegmentWithMeta segment) {
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
    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Text Settings'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Font Size: ${_fontSize.toInt()}', style: theme.textTheme.titleSmall),
                    Slider(
                      value: _fontSize,
                      min: 14,
                      max: 32,
                      divisions: 18,
                      label: _fontSize.toInt().toString(),
                      onChanged: (value) {
                        setDialogState(() {
                          setState(() {
                            _fontSize = value;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    Text('Line Height: ${_lineHeight.toStringAsFixed(1)}', style: theme.textTheme.titleSmall),
                    Slider(
                      value: _lineHeight,
                      min: 1.2,
                      max: 2.5,
                      divisions: 13,
                      label: _lineHeight.toStringAsFixed(1),
                      onChanged: (value) {
                        setDialogState(() {
                          setState(() {
                            _lineHeight = value;
                          });
                        });
                      },
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    SwitchListTile(
                      title: const Text('Show Transliteration'),
                      subtitle: const Text('Coming soon'),
                      value: _showTransliteration,
                      onChanged: (value) {
                        setDialogState(() {
                          setState(() {
                            _showTransliteration = value;
                          });
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _fontSize = 20.0;
                      _lineHeight = 1.8;
                      _showTransliteration = false;
                    });
                    setDialogState(() {});
                  },
                  child: const Text('Reset'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
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
                _buildInfoRow(theme, 'Reference', '${widget.refStart} – ${widget.refEnd}'),
                if (response != null) ...[
                  _buildInfoRow(theme, 'Segments', '${response.segments.length}'),
                  const SizedBox(height: VibrantSpacing.md),
                  const Divider(),
                  const SizedBox(height: VibrantSpacing.md),
                  _buildInfoRow(theme, 'Source', response.textInfo['source'] as String? ?? 'Unknown'),
                  _buildInfoRow(theme, 'License', response.textInfo['license'] as String? ?? 'Unknown'),
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
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
