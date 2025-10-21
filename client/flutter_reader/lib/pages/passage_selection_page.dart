/// Page for selecting a specific passage range within a text.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/reader.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/premium_micro_interactions.dart';
import '../widgets/premium_3d_animations.dart';
import 'reading_page.dart';

/// Page for selecting a passage range to read.
class PassageSelectionPage extends ConsumerStatefulWidget {
  const PassageSelectionPage({
    required this.textWork,
    required this.structure,
    this.selectedBook,
    this.selectedPage,
    super.key,
  });

  final TextWorkInfo textWork;
  final TextStructure structure;
  final int? selectedBook;
  final String? selectedPage;

  @override
  ConsumerState<PassageSelectionPage> createState() => _PassageSelectionPageState();
}

class _PassageSelectionPageState extends ConsumerState<PassageSelectionPage> {
  // For book.line scheme
  int? _startLine;
  int? _endLine;

  // For stephanus scheme (single page view by default)
  String? _selectedPage;

  @override
  void initState() {
    super.initState();
    _selectedPage = widget.selectedPage;

    // For book.line, set default range to first 20 lines
    if (widget.selectedBook != null && widget.structure.books != null) {
      final book = widget.structure.books!.firstWhere(
        (b) => b.book == widget.selectedBook,
      );
      _startLine = book.firstLine;
      _endLine = (book.firstLine + 19).clamp(book.firstLine, book.lastLine);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.textWork.title,
              style: GoogleFonts.notoSerif(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _getSubtitle(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
      body: widget.structure.refScheme == 'book.line'
          ? _buildBookLineSelection(context, theme, colorScheme)
          : _buildStephanusSelection(context, theme, colorScheme),
      floatingActionButton: _canProceed()
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ShimmerButton(
                onPressed: () {
                  HapticService.medium();
                  _navigateToReading();
                },
                shimmerDuration: const Duration(milliseconds: 1500),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Read Passage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  String _getSubtitle() {
    if (widget.selectedBook != null) {
      return 'Book ${widget.selectedBook}';
    } else if (widget.selectedPage != null) {
      return 'Page ${widget.selectedPage}';
    }
    return widget.textWork.author;
  }

  bool _canProceed() {
    if (widget.structure.refScheme == 'book.line') {
      return _startLine != null && _endLine != null && _startLine! <= _endLine!;
    } else if (widget.structure.refScheme == 'stephanus') {
      return _selectedPage != null;
    }
    return false;
  }

  void _navigateToReading() {
    String refStart;
    String refEnd;

    if (widget.structure.refScheme == 'book.line') {
      // e.g., "Il.1.1" to "Il.1.20"
      final abbr = _getWorkAbbreviation();
      refStart = '$abbr.${widget.selectedBook}.$_startLine';
      refEnd = '$abbr.${widget.selectedBook}.$_endLine';
    } else if (widget.structure.refScheme == 'stephanus') {
      // e.g., "Apol.17a" (single page)
      final abbr = _getWorkAbbreviation();
      refStart = '$abbr.$_selectedPage';
      refEnd = '$abbr.$_selectedPage';
    } else {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ReadingPage(
          textWork: widget.textWork,
          refStart: refStart,
          refEnd: refEnd,
        ),
      ),
    );
  }

  String _getWorkAbbreviation() {
    // Map common titles to abbreviations
    final titleLower = widget.textWork.title.toLowerCase();
    if (titleLower.contains('iliad')) return 'Il';
    if (titleLower.contains('odyssey')) return 'Od';
    if (titleLower.contains('apology')) return 'Apol';
    if (titleLower.contains('symposium')) return 'Symp';
    if (titleLower.contains('republic')) return 'Rep';
    return widget.textWork.title.substring(0, 3);
  }

  Widget _buildBookLineSelection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final book = widget.structure.books!.firstWhere(
      (b) => b.book == widget.selectedBook,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card with 3D tilt effect
          RotatingCard(
            maxRotation: 0.05,
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
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            child: Column(
              children: [
                Icon(
                  Icons.format_list_numbered_rounded,
                  size: 48,
                  color: colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  'Book ${book.book}',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  '${book.lineCount} lines',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  'Lines ${book.firstLine}–${book.lastLine}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Range selection
          Text(
            'Select Line Range',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),

          // Start line
          Text(
            'Start Line',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Slider(
            value: (_startLine ?? book.firstLine).toDouble(),
            min: book.firstLine.toDouble(),
            max: book.lastLine.toDouble(),
            divisions: book.lineCount - 1,
            label: _startLine?.toString() ?? book.firstLine.toString(),
            onChanged: (value) {
              HapticService.selection();
              setState(() {
                _startLine = value.toInt();
                // Auto-adjust end line if needed
                if (_endLine != null && _endLine! < _startLine!) {
                  _endLine = _startLine;
                }
              });
            },
          ),
          Text(
            'Line ${_startLine ?? book.firstLine}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: VibrantSpacing.lg),

          // End line
          Text(
            'End Line',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Slider(
            value: (_endLine ?? book.firstLine).toDouble(),
            min: (_startLine ?? book.firstLine).toDouble(),
            max: book.lastLine.toDouble(),
            divisions: (book.lastLine - (_startLine ?? book.firstLine)).clamp(0, 1000),
            label: _endLine?.toString() ?? book.firstLine.toString(),
            onChanged: (value) {
              HapticService.selection();
              setState(() {
                _endLine = value.toInt();
              });
            },
          ),
          Text(
            'Line ${_endLine ?? book.firstLine}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.secondary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Summary
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Range',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lines:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${_startLine ?? book.firstLine}–${_endLine ?? book.firstLine}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total lines:',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      '${(_endLine ?? book.firstLine) - (_startLine ?? book.firstLine) + 1}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: VibrantSpacing.xxl),

          // Quick selection chips
          Text(
            'Quick Select',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Wrap(
            spacing: VibrantSpacing.sm,
            runSpacing: VibrantSpacing.sm,
            children: [
              _buildQuickSelectChip(
                context,
                '10 lines',
                () => _setQuickRange(book, 10),
              ),
              _buildQuickSelectChip(
                context,
                '20 lines',
                () => _setQuickRange(book, 20),
              ),
              _buildQuickSelectChip(
                context,
                '50 lines',
                () => _setQuickRange(book, 50),
              ),
              _buildQuickSelectChip(
                context,
                '100 lines',
                () => _setQuickRange(book, 100),
              ),
              _buildQuickSelectChip(
                context,
                'Full book',
                () => _setQuickRange(book, book.lineCount),
              ),
            ],
          ),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildQuickSelectChip(BuildContext context, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ActionChip(
      label: Text(label),
      onPressed: () {
        HapticService.light();
        onTap();
      },
      backgroundColor: colorScheme.secondaryContainer,
      labelStyle: TextStyle(
        color: colorScheme.onSecondaryContainer,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _setQuickRange(BookInfo book, int lineCount) {
    setState(() {
      _startLine = book.firstLine;
      _endLine = (book.firstLine + lineCount - 1).clamp(book.firstLine, book.lastLine);
    });
  }

  Widget _buildStephanusSelection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    final pages = widget.structure.pages!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card with 3D tilt effect
          RotatingCard(
            maxRotation: 0.05,
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
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
            child: Column(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 48,
                  color: colorScheme.onTertiaryContainer,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Text(
                  widget.textWork.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  'Stephanus pagination',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          Text(
            'Select a Page',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.md),

          // Page grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 80,
              mainAxisSpacing: VibrantSpacing.sm,
              crossAxisSpacing: VibrantSpacing.sm,
              childAspectRatio: 1.2,
            ),
            itemCount: pages.length,
            itemBuilder: (context, index) {
              final page = pages[index];
              final isSelected = _selectedPage == page;

              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? colorScheme.primaryContainer : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                  side: isSelected
                      ? BorderSide(color: colorScheme.primary, width: 2)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () {
                    HapticService.light();
                    setState(() {
                      _selectedPage = page;
                    });
                  },
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                  child: Center(
                    child: Text(
                      page,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }
}
