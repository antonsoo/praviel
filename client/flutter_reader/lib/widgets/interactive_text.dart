import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/vibrant_theme.dart';

/// Interactive text widget that makes words tappable for analysis
class InteractiveText extends StatefulWidget {
  const InteractiveText({
    required this.text,
    required this.fontSize,
    required this.lineHeight,
    required this.onWordTap,
    this.highlightedWords = const {},
    super.key,
  });

  final String text;
  final double fontSize;
  final double lineHeight;
  final Function(String word) onWordTap;
  final Set<String> highlightedWords;

  @override
  State<InteractiveText> createState() => _InteractiveTextState();
}

class _InteractiveTextState extends State<InteractiveText> with SingleTickerProviderStateMixin {
  String? _hoveredWord;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  List<_WordSpan> _splitIntoWords(String text) {
    final spans = <_WordSpan>[];
    final regex = RegExp(r'(\S+)(\s*)');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      final word = match.group(1)!;
      final space = match.group(2) ?? '';
      spans.add(_WordSpan(word: word, space: space));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final wordSpans = _splitIntoWords(widget.text);

    return Wrap(
      children: wordSpans.map((span) {
        final isHighlighted = widget.highlightedWords.contains(span.word);
        final isHovered = _hoveredWord == span.word;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hoveredWord = span.word),
          onExit: (_) => setState(() => _hoveredWord = null),
          child: GestureDetector(
            onTap: () {
              _pulseController.forward(from: 0);
              widget.onWordTap(span.word);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: isHovered
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : isHighlighted
                        ? colorScheme.tertiary.withValues(alpha: 0.15)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: isHovered
                    ? Border.all(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
              ),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: span.word,
                      style: GoogleFonts.notoSerif(
                        fontSize: widget.fontSize,
                        height: widget.lineHeight,
                        fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.3,
                        color: isHovered
                            ? colorScheme.primary
                            : isHighlighted
                                ? colorScheme.tertiary
                                : colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: span.space,
                      style: GoogleFonts.notoSerif(fontSize: widget.fontSize),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WordSpan {
  const _WordSpan({required this.word, required this.space});

  final String word;
  final String space;
}

/// Bottom sheet for word analysis
class WordAnalysisSheet extends StatelessWidget {
  const WordAnalysisSheet({
    required this.word,
    required this.lemma,
    required this.morph,
    required this.onAddToSRS,
    super.key,
  });

  final String word;
  final String? lemma;
  final String? morph;
  final Future<void> Function() onAddToSRS;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xxl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Word header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.7),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.translate,
                  color: colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: VibrantSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (lemma != null) ...[
                      const SizedBox(height: VibrantSpacing.xxs),
                      Text(
                        'Lemma: $lemma',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // Morphology
          if (morph != null) ...[
            Container(
              padding: const EdgeInsets.all(VibrantSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: VibrantSpacing.xs),
                      Text(
                        'Morphology',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VibrantSpacing.sm),
                  Text(
                    morph!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VibrantSpacing.md),
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onAddToSRS,
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('Add to SRS'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                  ),
                ),
              ),
              const SizedBox(width: VibrantSpacing.sm),
              OutlinedButton.icon(
                onPressed: () {
                  // Open full lexicon entry
                },
                icon: const Icon(Icons.book_outlined),
                label: const Text('Dictionary'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                ),
              ),
            ],
          ),

          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
