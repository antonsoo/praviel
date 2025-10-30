/// Premium reading view with enhanced typography and interactions
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/reader.dart';
import '../../theme/vibrant_theme.dart';
import '../interactive_text.dart';

/// Enhanced reading view with premium typography and word-tap support
class EnhancedReadingView extends StatefulWidget {
  const EnhancedReadingView({
    super.key,
    required this.segments,
    required this.language,
    required this.fontSize,
    required this.lineHeight,
    required this.onWordTap,
    this.knownWords = const {},
  });

  final List<SegmentWithMeta> segments;
  final String language;
  final double fontSize;
  final double lineHeight;
  final Function(String word) onWordTap;
  final Set<String> knownWords;

  @override
  State<EnhancedReadingView> createState() => _EnhancedReadingViewState();
}

class _EnhancedReadingViewState extends State<EnhancedReadingView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.surface,
            colorScheme.surfaceContainerLowest,
          ],
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(VibrantSpacing.xl),
        itemCount: widget.segments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: VibrantSpacing.xl),
        itemBuilder: (context, index) {
          final segment = widget.segments[index];
          return _buildSegmentCard(context, theme, colorScheme, segment, index);
        },
      ),
    );
  }

  Widget _buildSegmentCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    SegmentWithMeta segment,
    int index,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.xl),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reference badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.lg,
              vertical: VibrantSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.6),
                  colorScheme.secondaryContainer.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(VibrantRadius.xl),
                topRight: Radius.circular(VibrantRadius.xl),
              ),
            ),
            child: Row(
              children: [
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
                    segment.ref,
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Expanded(
                  child: Text(
                    'Line ${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),

          // Text content
          Padding(
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            child: InteractiveText(
              text: segment.text,
              fontSize: widget.fontSize,
              lineHeight: widget.lineHeight,
              onWordTap: widget.onWordTap,
              highlightedWords: widget.knownWords,
            ),
          ),
        ],
      ),
    );
  }
}
