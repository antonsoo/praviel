import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

/// Professional text display widget with inline learning tools
/// Features: word highlighting, inline glossary, grammar hints, progress tracking
class EnhancedTextDisplay extends StatefulWidget {
  const EnhancedTextDisplay({
    super.key,
    required this.text,
    required this.translation,
    required this.languageCode,
    this.onWordTap,
    this.showTranslation = false,
    this.showGrammarHints = true,
    this.fontSize = 20.0,
  });

  final String text;
  final String? translation;
  final String languageCode;
  final Function(String word, int wordIndex)? onWordTap;
  final bool showTranslation;
  final bool showGrammarHints;
  final double fontSize;

  @override
  State<EnhancedTextDisplay> createState() => _EnhancedTextDisplayState();
}

class _EnhancedTextDisplayState extends State<EnhancedTextDisplay> with SingleTickerProviderStateMixin {
  int? _selectedWordIndex;
  late AnimationController _highlightController;
  late Animation<double> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _highlightAnimation = CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  void _handleWordTap(String word, int index) {
    setState(() {
      if (_selectedWordIndex == index) {
        // Deselect
        _selectedWordIndex = null;
        _highlightController.reverse();
      } else {
        // Select new word
        _selectedWordIndex = index;
        _highlightController.forward();
        HapticService.light();
        SoundService.instance.tap();
      }
    });

    widget.onWordTap?.call(word, index);
  }

  List<String> _tokenizeText(String text) {
    // Simple word tokenization - in production this would use proper linguistic tokenization
    return text.split(RegExp(r'[\s\p{P}]+', unicode: true))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final words = _tokenizeText(widget.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main text display
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.xl),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: SelectionArea(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(words.length, (index) {
                final word = words[index];
                final isSelected = _selectedWordIndex == index;

                return GestureDetector(
                  onTap: () => _handleWordTap(word, index),
                  child: AnimatedBuilder(
                    animation: _highlightAnimation,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primaryContainer.withValues(
                                  alpha: 0.3 + (_highlightAnimation.value * 0.4),
                                )
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(VibrantRadius.sm),
                        ),
                        child: Text(
                          word,
                          style: _getTextStyle(theme, colorScheme, isSelected),
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),
        ),

        // Translation (if enabled)
        if (widget.showTranslation && widget.translation != null) ...[
          const SizedBox(height: VibrantSpacing.lg),
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.translate_rounded,
                  size: 20,
                  color: colorScheme.secondary,
                ),
                const SizedBox(width: VibrantSpacing.sm),
                Expanded(
                  child: Text(
                    widget.translation!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Selected word info panel
        if (_selectedWordIndex != null) ...[
          const SizedBox(height: VibrantSpacing.lg),
          AnimatedBuilder(
            animation: _highlightAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.9 + (_highlightAnimation.value * 0.1),
                child: Opacity(
                  opacity: _highlightAnimation.value,
                  child: child,
                ),
              );
            },
            child: _WordInfoPanel(
              word: words[_selectedWordIndex!],
              languageCode: widget.languageCode,
              onClose: () {
                setState(() {
                  _selectedWordIndex = null;
                  _highlightController.reverse();
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  TextStyle _getTextStyle(ThemeData theme, ColorScheme colorScheme, bool isSelected) {
    // Use authentic fonts for ancient languages
    final fontFamily = _getFontFamily(widget.languageCode);

    return theme.textTheme.headlineSmall!.copyWith(
      fontSize: widget.fontSize,
      fontFamily: fontFamily,
      height: 1.8,
      letterSpacing: 0.5,
      color: isSelected
          ? colorScheme.primary
          : colorScheme.onSurface,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
    );
  }

  String? _getFontFamily(String languageCode) {
    // Map language codes to appropriate fonts
    switch (languageCode) {
      case 'lat':
        return 'Noto Serif';
      case 'grc-cls':
      case 'grc-koi':
        return 'Noto Serif';
      case 'hbo':
        return 'Noto Serif Hebrew';
      case 'san':
      case 'san-ved':
        return 'Noto Serif Devanagari';
      case 'ara':
        return 'Noto Naskh Arabic';
      case 'lzh':
        return 'Noto Serif SC';
      default:
        return null;
    }
  }
}

/// Word information panel with glossary, grammar, etymology
class _WordInfoPanel extends StatelessWidget {
  const _WordInfoPanel({
    required this.word,
    required this.languageCode,
    required this.onClose,
  });

  final String word;
  final String languageCode;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.book_outlined,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Expanded(
                child: Text(
                  word,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                iconSize: 20,
                onPressed: onClose,
                color: colorScheme.onPrimaryContainer,
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),
          _buildInfoSection(
            context,
            'Definition',
            Icons.description_outlined,
            _getMockDefinition(word, languageCode),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          _buildInfoSection(
            context,
            'Grammar',
            Icons.auto_stories_outlined,
            _getMockGrammar(word, languageCode),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          _buildInfoSection(
            context,
            'Etymology',
            Icons.history_edu_outlined,
            _getMockEtymology(word, languageCode),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    BuildContext context,
    String title,
    IconData icon,
    String content,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.primary.withValues(alpha: 0.7)),
        const SizedBox(width: VibrantSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getMockDefinition(String word, String languageCode) {
    // In production, this would fetch from a real dictionary API
    return 'Tap to analyze this word with AI';
  }

  String _getMockGrammar(String word, String languageCode) {
    // In production, this would use morphological analysis
    switch (languageCode) {
      case 'lat':
        return 'Noun, genitive singular';
      case 'grc-cls':
      case 'grc-koi':
        return 'Verb, aorist active indicative';
      case 'hbo':
        return 'Perfect, 3rd person masculine';
      default:
        return 'Analyzing...';
    }
  }

  String _getMockEtymology(String word, String languageCode) {
    // In production, this would fetch etymological data
    return 'From Proto-Indo-European root *bʰer-';
  }
}
