/// Page for reading a passage of classical Greek text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_providers.dart';
import '../models/reader.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/interactive_text.dart';

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

  Future<void> _handleWordTap(String word) async {
    // Remove punctuation
    final cleanWord = word.replaceAll(RegExp(r'[.,;:!?·—]'), '');
    if (cleanWord.isEmpty) return;

    try {
      final api = ref.read(textReaderApiProvider);
      final response = await api.analyzeText(
        text: cleanWord,
        language: widget.textWork.language,
      );

      if (!mounted) return;

      // Show word analysis bottom sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => WordAnalysisSheet(
          word: cleanWord,
          lemma: response.tokens.isNotEmpty ? response.tokens.first.lemma : null,
          morph: response.tokens.isNotEmpty ? response.tokens.first.morph : null,
          onAddToSRS: () {
            setState(() => _knownWords.add(cleanWord));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "$cleanWord" to SRS'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to analyze word: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            onPressed: () => _showTextSettingsDialog(context),
            tooltip: 'Text settings',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: () {
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
          // Attribution header
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
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

          // License footer
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
            ),
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
    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
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
            FilledButton.icon(
              onPressed: () {
                ref.invalidate(textSegmentsProvider(request));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
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
