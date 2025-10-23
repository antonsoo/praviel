import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

enum ContextType {
  historical,
  cultural,
  literary,
  linguistic,
  archaeological,
  religious,
}

class CulturalContext {
  final String id;
  final String title;
  final String content;
  final ContextType type;
  final String? imageUrl;
  final String? videoUrl;
  final List<String> tags;
  final DateTime? era; // Historical period
  final List<String> relatedTexts;
  final List<String> sources;

  const CulturalContext({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    this.videoUrl,
    required this.tags,
    this.era,
    required this.relatedTexts,
    required this.sources,
  });
}

/// Cultural and historical context widget for ancient texts
class CulturalContextWidget extends StatefulWidget {
  const CulturalContextWidget({
    super.key,
    required this.contexts,
    required this.passageReference,
    this.onContextTap,
  });

  final List<CulturalContext> contexts;
  final String passageReference;
  final Function(CulturalContext)? onContextTap;

  @override
  State<CulturalContextWidget> createState() => _CulturalContextWidgetState();
}

class _CulturalContextWidgetState extends State<CulturalContextWidget> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final types = widget.contexts.map((c) => c.type).toSet().toList();
    _tabController = TabController(
      length: types.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CulturalContext> _getContextsByType(ContextType type) {
    return widget.contexts.where((c) => c.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final types = widget.contexts.map((c) => c.type).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                    Icons.public_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  Text(
                    'Cultural Context',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.xs),
              Text(
                widget.passageReference,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),

        // Type tabs
        Container(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: types.map((type) {
              return Tab(
                child: Row(
                  children: [
                    Icon(_getContextIcon(type), size: 16),
                    const SizedBox(width: VibrantSpacing.xs),
                    Text(_getContextLabel(type)),
                  ],
                ),
              );
            }).toList(),
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
            onTap: (_) {
              HapticService.light();
              SoundService.instance.tap();
            },
          ),
        ),

        // Context cards
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: types.map((type) {
              final contexts = _getContextsByType(type);
              return ListView.separated(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                itemCount: contexts.length,
                separatorBuilder: (context, index) => const SizedBox(height: VibrantSpacing.md),
                itemBuilder: (context, index) {
                  final culturalContext = contexts[index];
                  return _ContextCard(
                    context: culturalContext,
                    onTap: widget.onContextTap != null
                        ? () {
                            HapticService.medium();
                            SoundService.instance.tap();
                            widget.onContextTap!(culturalContext);
                          }
                        : null,
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getContextIcon(ContextType type) {
    switch (type) {
      case ContextType.historical:
        return Icons.history_rounded;
      case ContextType.cultural:
        return Icons.groups_rounded;
      case ContextType.literary:
        return Icons.auto_stories_rounded;
      case ContextType.linguistic:
        return Icons.language_rounded;
      case ContextType.archaeological:
        return Icons.terrain_rounded;
      case ContextType.religious:
        return Icons.church_rounded;
    }
  }

  String _getContextLabel(ContextType type) {
    switch (type) {
      case ContextType.historical:
        return 'Historical';
      case ContextType.cultural:
        return 'Cultural';
      case ContextType.literary:
        return 'Literary';
      case ContextType.linguistic:
        return 'Linguistic';
      case ContextType.archaeological:
        return 'Archaeological';
      case ContextType.religious:
        return 'Religious';
    }
  }
}

/// Individual context card
class _ContextCard extends StatelessWidget {
  const _ContextCard({
    required this.context,
    this.onTap,
  });

  final CulturalContext context;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(VibrantRadius.lg),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image header (if available)
              if (this.context.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(VibrantRadius.lg),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      this.context.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: colorScheme.onSurfaceVariant,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      this.context.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Era (if available)
                    if (this.context.era != null) ...[
                      const SizedBox(height: VibrantSpacing.xs),
                      Text(
                        _formatEra(this.context.era!),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],

                    const SizedBox(height: VibrantSpacing.md),

                    // Content
                    Text(
                      this.context.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.6,
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Tags
                    if (this.context.tags.isNotEmpty) ...[
                      const SizedBox(height: VibrantSpacing.md),
                      Wrap(
                        spacing: VibrantSpacing.xs,
                        runSpacing: VibrantSpacing.xs,
                        children: this.context.tags.take(4).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VibrantSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(VibrantRadius.sm),
                            ),
                            child: Text(
                              tag,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    // Related texts and sources count
                    const SizedBox(height: VibrantSpacing.md),
                    Row(
                      children: [
                        if (this.context.relatedTexts.isNotEmpty) ...[
                          Icon(
                            Icons.menu_book_rounded,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${this.context.relatedTexts.length} related',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: VibrantSpacing.md),
                        ],
                        Icon(
                          Icons.source_rounded,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${this.context.sources.length} sources',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (this.context.videoUrl != null) ...[
                          const SizedBox(width: VibrantSpacing.md),
                          Icon(
                            Icons.play_circle_outline_rounded,
                            size: 14,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Video',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

/// Detailed cultural context view
class CulturalContextDetail extends StatelessWidget {
  const CulturalContextDetail({
    super.key,
    required this.context,
  });

  final CulturalContext context;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image
          if (this.context.imageUrl != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                this.context.imageUrl!,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(VibrantSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and era
                Text(
                  this.context.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (this.context.era != null) ...[
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    _formatEra(this.context.era!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ],

                const SizedBox(height: VibrantSpacing.xl),

                // Content
                Text(
                  this.context.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.8,
                  ),
                ),

                const SizedBox(height: VibrantSpacing.xl),

                // Tags
                if (this.context.tags.isNotEmpty) ...[
                  Text(
                    'Topics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Wrap(
                    spacing: VibrantSpacing.sm,
                    runSpacing: VibrantSpacing.sm,
                    children: this.context.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.md,
                          vertical: VibrantSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(VibrantRadius.md),
                        ),
                        child: Text(
                          tag,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: VibrantSpacing.xl),
                ],

                // Related texts
                if (this.context.relatedTexts.isNotEmpty) ...[
                  Text(
                    'Related Texts',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  ...this.context.relatedTexts.map((text) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: VibrantSpacing.sm),
                          Expanded(
                            child: Text(
                              text,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: VibrantSpacing.xl),
                ],

                // Sources
                if (this.context.sources.isNotEmpty) ...[
                  Text(
                    'Sources',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.md),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: this.context.sources.map((source) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: VibrantSpacing.xs),
                          child: Text(
                            '• $source',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }).toList(),
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
