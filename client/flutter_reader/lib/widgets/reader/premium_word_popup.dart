/// Premium word analysis popup for Reader with stunning 2025 design
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';

/// Stunning word analysis popup that appears when tapping words
class PremiumWordPopup extends StatefulWidget {
  const PremiumWordPopup({
    super.key,
    required this.word,
    this.lemma,
    this.morph,
    this.gloss,
    this.examples,
    required this.onAddToSRS,
    required this.onClose,
  });

  final String word;
  final String? lemma;
  final String? morph;
  final String? gloss;
  final List<String>? examples;
  final VoidCallback onAddToSRS;
  final VoidCallback onClose;

  @override
  State<PremiumWordPopup> createState() => _PremiumWordPopupState();

  /// Show the premium word popup as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String word,
    String? lemma,
    String? morph,
    String? gloss,
    List<String>? examples,
    required VoidCallback onAddToSRS,
  }) {
    HapticService.light();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) => PremiumWordPopup(
        word: word,
        lemma: lemma,
        morph: morph,
        gloss: gloss,
        examples: examples,
        onAddToSRS: () {
          onAddToSRS();
          Navigator.pop(context);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

class _PremiumWordPopupState extends State<PremiumWordPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black54,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ScaleTransition(
              scale: _scaleAnimation,
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {}, // Prevent closing when tapping content
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: size.height * 0.75,
                    maxWidth: 600,
                  ),
                  margin: const EdgeInsets.only(
                    left: VibrantSpacing.md,
                    right: VibrantSpacing.md,
                    bottom: VibrantSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(VibrantRadius.xxl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: VibrantSpacing.md),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(VibrantSpacing.xl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Word header with gradient
                              Container(
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
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.word,
                                      style: GoogleFonts.notoSerif(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w900,
                                        height: 1.2,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                    if (widget.lemma != null &&
                                        widget.lemma!.isNotEmpty &&
                                        widget.lemma != widget.word) ...[
                                      const SizedBox(height: VibrantSpacing.sm),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: VibrantSpacing.md,
                                              vertical: VibrantSpacing.xs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.surface.withValues(alpha: 0.9),
                                              borderRadius: BorderRadius.circular(
                                                VibrantRadius.md,
                                              ),
                                            ),
                                            child: Text(
                                              widget.lemma!,
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: VibrantSpacing.sm),
                                          Text(
                                            'lemma',
                                            style: theme.textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onPrimaryContainer.withValues(
                                                alpha: 0.7,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: VibrantSpacing.xl),

                              // Morphology section
                              if (widget.morph != null && widget.morph!.isNotEmpty) ...[
                                _buildSectionHeader(
                                  context,
                                  'Morphology',
                                  Icons.schema_outlined,
                                ),
                                const SizedBox(height: VibrantSpacing.md),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer.withValues(
                                      alpha: 0.4,
                                    ),
                                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                                    border: Border.all(
                                      color: colorScheme.secondary.withValues(alpha: 0.2),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    widget.morph!,
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 16,
                                      height: 1.6,
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: VibrantSpacing.xl),
                              ],

                              // Gloss/Definition section
                              if (widget.gloss != null && widget.gloss!.isNotEmpty) ...[
                                _buildSectionHeader(
                                  context,
                                  'Definition',
                                  Icons.menu_book_outlined,
                                ),
                                const SizedBox(height: VibrantSpacing.md),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(VibrantSpacing.lg),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiaryContainer.withValues(
                                      alpha: 0.4,
                                    ),
                                    borderRadius: BorderRadius.circular(VibrantRadius.lg),
                                  ),
                                  child: Text(
                                    widget.gloss!,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      height: 1.6,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: VibrantSpacing.xl),
                              ],

                              // Examples section
                              if (widget.examples != null &&
                                  widget.examples!.isNotEmpty) ...[
                                _buildSectionHeader(
                                  context,
                                  'Examples',
                                  Icons.format_quote_outlined,
                                ),
                                const SizedBox(height: VibrantSpacing.md),
                                ...widget.examples!.map((example) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: VibrantSpacing.sm,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(VibrantSpacing.md),
                                        decoration: BoxDecoration(
                                          color: colorScheme.surfaceContainerHighest.withValues(
                                            alpha: 0.6,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            VibrantRadius.md,
                                          ),
                                        ),
                                        child: Text(
                                          example,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    )),
                                const SizedBox(height: VibrantSpacing.xl),
                              ],

                              // Action buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () {
                                        HapticService.medium();
                                        widget.onAddToSRS();
                                      },
                                      icon: const Icon(Icons.add_circle_outline),
                                      label: const Text('Add to SRS'),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: VibrantSpacing.md,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: VibrantSpacing.md),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      HapticService.light();
                                      _close();
                                    },
                                    icon: const Icon(Icons.close),
                                    label: const Text('Close'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: VibrantSpacing.lg,
                                        vertical: VibrantSpacing.md,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.sm),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(VibrantRadius.md),
          ),
          child: Icon(
            icon,
            size: 20,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: VibrantSpacing.md),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
