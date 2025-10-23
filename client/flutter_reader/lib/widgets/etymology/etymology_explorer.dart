import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

enum LanguageFamily {
  indoEuropean,
  semitic,
  sinoTibetan,
  turkic,
  uralic,
  other,
}

class EtymologyNode {
  final String word;
  final String language;
  final String languageCode;
  final String meaning;
  final String? pronunciation;
  final DateTime? era;
  final List<EtymologyNode> derivatives; // Words that came from this word
  final EtymologyNode? parent; // Where this word came from

  const EtymologyNode({
    required this.word,
    required this.language,
    required this.languageCode,
    required this.meaning,
    this.pronunciation,
    this.era,
    this.derivatives = const [],
    this.parent,
  });
}

class WordEtymology {
  final String word;
  final String currentLanguage;
  final EtymologyNode rootNode;
  final List<String> cognates; // Related words in other languages
  final String? historicalNote;
  final LanguageFamily family;

  const WordEtymology({
    required this.word,
    required this.currentLanguage,
    required this.rootNode,
    required this.cognates,
    this.historicalNote,
    required this.family,
  });
}

/// Interactive etymology explorer with word origin trees
class EtymologyExplorer extends StatefulWidget {
  const EtymologyExplorer({
    super.key,
    required this.etymology,
    this.onNodeTap,
  });

  final WordEtymology etymology;
  final Function(EtymologyNode)? onNodeTap;

  @override
  State<EtymologyExplorer> createState() => _EtymologyExplorerState();
}

class _EtymologyExplorerState extends State<EtymologyExplorer> with SingleTickerProviderStateMixin {
  EtymologyNode? _selectedNode;
  late AnimationController _expandController;
  bool _showTree = true;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandController.forward();
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          decoration: BoxDecoration(
            gradient: VibrantTheme.heroGradient,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(VibrantRadius.xl),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_edu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Etymology',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.etymology.word,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(VibrantRadius.sm),
                ),
                child: Text(
                  _getLanguageFamilyLabel(widget.etymology.family),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // View toggle
        Padding(
          padding: const EdgeInsets.all(VibrantSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: _ViewToggleButton(
                  label: 'Tree View',
                  icon: Icons.account_tree_rounded,
                  isSelected: _showTree,
                  onTap: () {
                    setState(() => _showTree = true);
                    HapticService.light();
                    SoundService.instance.tap();
                  },
                ),
              ),
              const SizedBox(width: VibrantSpacing.sm),
              Expanded(
                child: _ViewToggleButton(
                  label: 'Timeline',
                  icon: Icons.timeline_rounded,
                  isSelected: !_showTree,
                  onTap: () {
                    setState(() => _showTree = false);
                    HapticService.light();
                    SoundService.instance.tap();
                  },
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showTree)
                  _EtymologyTree(
                    rootNode: widget.etymology.rootNode,
                    selectedNode: _selectedNode,
                    onNodeTap: (node) {
                      setState(() => _selectedNode = node);
                      HapticService.medium();
                      SoundService.instance.tap();
                      widget.onNodeTap?.call(node);
                    },
                  )
                else
                  _EtymologyTimeline(
                    rootNode: widget.etymology.rootNode,
                    selectedNode: _selectedNode,
                    onNodeTap: (node) {
                      setState(() => _selectedNode = node);
                      HapticService.medium();
                      SoundService.instance.tap();
                      widget.onNodeTap?.call(node);
                    },
                  ),

                const SizedBox(height: VibrantSpacing.xl),

                // Cognates
                if (widget.etymology.cognates.isNotEmpty) ...[
                  _CognatesSection(cognates: widget.etymology.cognates),
                  const SizedBox(height: VibrantSpacing.xl),
                ],

                // Historical note
                if (widget.etymology.historicalNote != null)
                  _HistoricalNote(note: widget.etymology.historicalNote!),
              ],
            ),
          ),
        ),

        // Selected node detail
        if (_selectedNode != null)
          _NodeDetailPanel(
            node: _selectedNode!,
            onClose: () {
              setState(() => _selectedNode = null);
              HapticService.light();
            },
          ),
      ],
    );
  }

  String _getLanguageFamilyLabel(LanguageFamily family) {
    switch (family) {
      case LanguageFamily.indoEuropean:
        return 'Indo-European Family';
      case LanguageFamily.semitic:
        return 'Semitic Family';
      case LanguageFamily.sinoTibetan:
        return 'Sino-Tibetan Family';
      case LanguageFamily.turkic:
        return 'Turkic Family';
      case LanguageFamily.uralic:
        return 'Uralic Family';
      case LanguageFamily.other:
        return 'Other Family';
    }
  }
}

/// View toggle button
class _ViewToggleButton extends StatelessWidget {
  const _ViewToggleButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: VibrantSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: isSelected ? VibrantTheme.heroGradient : null,
            color: isSelected ? null : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(VibrantRadius.md),
            border: Border.all(
              color: isSelected ? Colors.transparent : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: VibrantSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etymology tree visualization
class _EtymologyTree extends StatelessWidget {
  const _EtymologyTree({
    required this.rootNode,
    required this.selectedNode,
    required this.onNodeTap,
  });

  final EtymologyNode rootNode;
  final EtymologyNode? selectedNode;
  final Function(EtymologyNode) onNodeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TreeNode(
          node: rootNode,
          isSelected: selectedNode == rootNode,
          onTap: () => onNodeTap(rootNode),
          depth: 0,
        ),
        if (rootNode.derivatives.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: VibrantSpacing.xl),
            child: Column(
              children: rootNode.derivatives.map((derivative) {
                return _buildTreeBranch(derivative, 1);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildTreeBranch(EtymologyNode node, int depth) {
    return Column(
      children: [
        _TreeNode(
          node: node,
          isSelected: selectedNode == node,
          onTap: () => onNodeTap(node),
          depth: depth,
        ),
        if (node.derivatives.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: VibrantSpacing.xl),
            child: Column(
              children: node.derivatives.map((derivative) {
                return _buildTreeBranch(derivative, depth + 1);
              }).toList(),
            ),
          ),
      ],
    );
  }
}

/// Individual tree node
class _TreeNode extends StatelessWidget {
  const _TreeNode({
    required this.node,
    required this.isSelected,
    required this.onTap,
    required this.depth,
  });

  final EtymologyNode node;
  final bool isSelected;
  final VoidCallback onTap;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VibrantRadius.md),
          child: Container(
            padding: const EdgeInsets.all(VibrantSpacing.md),
            decoration: BoxDecoration(
              gradient: isSelected ? VibrantTheme.heroGradient : null,
              color: isSelected ? null : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(VibrantRadius.md),
              border: Border.all(
                color: isSelected ? Colors.transparent : colorScheme.outline.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // Depth indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getDepthColor(depth).withValues(alpha: isSelected ? 1.0 : 0.5),
                    borderRadius: BorderRadius.circular(VibrantRadius.sm),
                  ),
                ),
                const SizedBox(width: VibrantSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.word,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${node.language} • ${node.meaning}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (node.era != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VibrantSpacing.xs,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(VibrantRadius.sm),
                    ),
                    child: Text(
                      _formatEra(node.era!),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isSelected ? Colors.white : colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDepthColor(int depth) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    return colors[depth % colors.length];
  }

  String _formatEra(DateTime era) {
    final year = era.year;
    if (year < 0) {
      return '${-year} BCE';
    } else if (year < 500) {
      return '$year CE';
    } else {
      return year.toString();
    }
  }
}

/// Timeline view
class _EtymologyTimeline extends StatelessWidget {
  const _EtymologyTimeline({
    required this.rootNode,
    required this.selectedNode,
    required this.onNodeTap,
  });

  final EtymologyNode rootNode;
  final EtymologyNode? selectedNode;
  final Function(EtymologyNode) onNodeTap;

  List<EtymologyNode> _flattenNodes(EtymologyNode node) {
    final nodes = <EtymologyNode>[node];
    for (final derivative in node.derivatives) {
      nodes.addAll(_flattenNodes(derivative));
    }
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    final allNodes = _flattenNodes(rootNode);
    final sortedNodes = allNodes.where((n) => n.era != null).toList()
      ..sort((a, b) => a.era!.compareTo(b.era!));

    return Column(
      children: sortedNodes.map((node) {
        return _TimelineItem(
          node: node,
          isSelected: selectedNode == node,
          onTap: () => onNodeTap(node),
        );
      }).toList(),
    );
  }
}

/// Timeline item
class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.node,
    required this.isSelected,
    required this.onTap,
  });

  final EtymologyNode node;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  gradient: isSelected ? VibrantTheme.heroGradient : null,
                  color: isSelected ? null : colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 60,
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(width: VibrantSpacing.md),
          // Content
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(VibrantRadius.md),
                child: Container(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  decoration: BoxDecoration(
                    gradient: isSelected ? VibrantTheme.heroGradient : null,
                    color: isSelected ? null : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(VibrantRadius.md),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (node.era != null)
                        Text(
                          _formatEra(node.era!),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected ? Colors.white.withValues(alpha: 0.8) : colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: VibrantSpacing.xs),
                      Text(
                        node.word,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${node.language} • ${node.meaning}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEra(DateTime era) {
    final year = era.year;
    if (year < 0) {
      return '${-year} BCE';
    } else if (year < 500) {
      return '$year CE';
    } else {
      return year.toString();
    }
  }
}

/// Cognates section
class _CognatesSection extends StatelessWidget {
  const _CognatesSection({required this.cognates});

  final List<String> cognates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded, color: colorScheme.tertiary, size: 20),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                'Related Words (Cognates)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.md),
          Wrap(
            spacing: VibrantSpacing.sm,
            runSpacing: VibrantSpacing.sm,
            children: cognates.map((cognate) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: VibrantSpacing.md,
                  vertical: VibrantSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                  border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  cognate,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Historical note
class _HistoricalNote extends StatelessWidget {
  const _HistoricalNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: Colors.amber),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
              const SizedBox(width: VibrantSpacing.sm),
              Text(
                'Historical Note',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            note,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Node detail panel
class _NodeDetailPanel extends StatelessWidget {
  const _NodeDetailPanel({
    required this.node,
    required this.onClose,
  });

  final EtymologyNode node;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      decoration: BoxDecoration(
        gradient: VibrantTheme.heroGradient,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(VibrantRadius.xl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.word,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: VibrantSpacing.sm),
          Text(
            node.language,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          if (node.pronunciation != null) ...[
            const SizedBox(height: VibrantSpacing.xs),
            Text(
              '[${node.pronunciation}]',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: VibrantSpacing.md),
          Text(
            node.meaning,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              height: 1.5,
            ),
          ),
          if (node.era != null) ...[
            const SizedBox(height: VibrantSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(VibrantRadius.sm),
              ),
              child: Text(
                _formatEra(node.era!),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatEra(DateTime era) {
    final year = era.year;
    if (year < 0) {
      return '${-year} BCE';
    } else if (year < 500) {
      return '$year CE';
    } else {
      return year.toString();
    }
  }
}
