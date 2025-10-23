import 'package:flutter/material.dart';
import '../../theme/vibrant_theme.dart';
import '../../services/haptic_service.dart';
import '../../services/sound_service.dart';

enum GrammarCategory {
  nouns,
  verbs,
  adjectives,
  pronouns,
  prepositions,
  conjunctions,
  syntax,
  particles,
}

class GrammarTopic {
  final String id;
  final String title;
  final String description;
  final GrammarCategory category;
  final List<GrammarSection> sections;
  final List<String> examples;
  final String? videoUrl;
  final bool isFavorite;

  const GrammarTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.sections,
    required this.examples,
    this.videoUrl,
    this.isFavorite = false,
  });
}

class GrammarSection {
  final String heading;
  final String content;
  final GrammarTable? table;
  final List<String>? notes;

  const GrammarSection({
    required this.heading,
    required this.content,
    this.table,
    this.notes,
  });
}

class GrammarTable {
  final List<String> headers;
  final List<List<String>> rows;
  final String? caption;

  const GrammarTable({
    required this.headers,
    required this.rows,
    this.caption,
  });
}

/// Comprehensive grammar reference library
class GrammarReference extends StatefulWidget {
  const GrammarReference({
    super.key,
    required this.topics,
    required this.onTopicTap,
    this.onFavoriteToggle,
    this.selectedCategory,
    this.languageCode = 'lat',
  });

  final List<GrammarTopic> topics;
  final Function(GrammarTopic) onTopicTap;
  final Function(GrammarTopic)? onFavoriteToggle;
  final GrammarCategory? selectedCategory;
  final String languageCode;

  @override
  State<GrammarReference> createState() => _GrammarReferenceState();
}

class _GrammarReferenceState extends State<GrammarReference> {
  GrammarCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  List<GrammarTopic> get _filteredTopics {
    var topics = widget.topics;

    // Filter by category
    if (_selectedCategory != null) {
      topics = topics.where((t) => t.category == _selectedCategory).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      topics = topics.where((t) {
        return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return topics;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(VibrantSpacing.md),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search grammar topics...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(VibrantRadius.xl),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: VibrantSpacing.md),
            children: [
              _CategoryChip(
                label: 'All',
                icon: Icons.grid_view_rounded,
                isSelected: _selectedCategory == null,
                onTap: () {
                  setState(() => _selectedCategory = null);
                  HapticService.light();
                  SoundService.instance.tap();
                },
              ),
              ...GrammarCategory.values.map((category) {
                return _CategoryChip(
                  label: _getCategoryLabel(category),
                  icon: _getCategoryIcon(category),
                  isSelected: _selectedCategory == category,
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    HapticService.light();
                    SoundService.instance.tap();
                  },
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: VibrantSpacing.md),

        // Topics list
        Expanded(
          child: _filteredTopics.isEmpty
              ? _EmptyState(searchQuery: _searchQuery)
              : ListView.separated(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  itemCount: _filteredTopics.length,
                  separatorBuilder: (context, index) => const SizedBox(height: VibrantSpacing.md),
                  itemBuilder: (context, index) {
                    final topic = _filteredTopics[index];
                    return _TopicCard(
                      topic: topic,
                      onTap: () {
                        HapticService.medium();
                        SoundService.instance.tap();
                        widget.onTopicTap(topic);
                      },
                      onFavoriteToggle: widget.onFavoriteToggle != null
                          ? () {
                              HapticService.light();
                              widget.onFavoriteToggle!(topic);
                            }
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _getCategoryLabel(GrammarCategory category) {
    switch (category) {
      case GrammarCategory.nouns:
        return 'Nouns';
      case GrammarCategory.verbs:
        return 'Verbs';
      case GrammarCategory.adjectives:
        return 'Adjectives';
      case GrammarCategory.pronouns:
        return 'Pronouns';
      case GrammarCategory.prepositions:
        return 'Prepositions';
      case GrammarCategory.conjunctions:
        return 'Conjunctions';
      case GrammarCategory.syntax:
        return 'Syntax';
      case GrammarCategory.particles:
        return 'Particles';
    }
  }

  IconData _getCategoryIcon(GrammarCategory category) {
    switch (category) {
      case GrammarCategory.nouns:
        return Icons.label_rounded;
      case GrammarCategory.verbs:
        return Icons.flash_on_rounded;
      case GrammarCategory.adjectives:
        return Icons.palette_rounded;
      case GrammarCategory.pronouns:
        return Icons.person_rounded;
      case GrammarCategory.prepositions:
        return Icons.compare_arrows_rounded;
      case GrammarCategory.conjunctions:
        return Icons.link_rounded;
      case GrammarCategory.syntax:
        return Icons.account_tree_rounded;
      case GrammarCategory.particles:
        return Icons.grain_rounded;
    }
  }
}

/// Category filter chip
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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

    return Padding(
      padding: const EdgeInsets.only(right: VibrantSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VibrantRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VibrantSpacing.md,
              vertical: VibrantSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? VibrantTheme.heroGradient : null,
              color: isSelected ? null : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: VibrantSpacing.xs),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grammar topic card
class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.onTap,
    this.onFavoriteToggle,
  });

  final GrammarTopic topic;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

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
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              ],
            ),
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
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(VibrantSpacing.sm),
                    decoration: BoxDecoration(
                      gradient: VibrantTheme.heroGradient,
                      borderRadius: BorderRadius.circular(VibrantRadius.md),
                    ),
                    child: Icon(
                      _getCategoryIcon(topic.category),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: VibrantSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getCategoryLabel(topic.category),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Favorite button
                  if (onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        topic.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                        color: topic.isFavorite ? Colors.amber : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onFavoriteToggle,
                    ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.md),
              Text(
                topic.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: VibrantSpacing.md),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.list_alt_rounded,
                    label: '${topic.sections.length} sections',
                  ),
                  const SizedBox(width: VibrantSpacing.sm),
                  _InfoChip(
                    icon: Icons.lightbulb_outline_rounded,
                    label: '${topic.examples.length} examples',
                  ),
                  if (topic.videoUrl != null) ...[
                    const SizedBox(width: VibrantSpacing.sm),
                    _InfoChip(
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Video',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(GrammarCategory category) {
    switch (category) {
      case GrammarCategory.nouns:
        return Icons.label_rounded;
      case GrammarCategory.verbs:
        return Icons.flash_on_rounded;
      case GrammarCategory.adjectives:
        return Icons.palette_rounded;
      case GrammarCategory.pronouns:
        return Icons.person_rounded;
      case GrammarCategory.prepositions:
        return Icons.compare_arrows_rounded;
      case GrammarCategory.conjunctions:
        return Icons.link_rounded;
      case GrammarCategory.syntax:
        return Icons.account_tree_rounded;
      case GrammarCategory.particles:
        return Icons.grain_rounded;
    }
  }

  String _getCategoryLabel(GrammarCategory category) {
    switch (category) {
      case GrammarCategory.nouns:
        return 'Nouns';
      case GrammarCategory.verbs:
        return 'Verbs';
      case GrammarCategory.adjectives:
        return 'Adjectives';
      case GrammarCategory.pronouns:
        return 'Pronouns';
      case GrammarCategory.prepositions:
        return 'Prepositions';
      case GrammarCategory.conjunctions:
        return 'Conjunctions';
      case GrammarCategory.syntax:
        return 'Syntax';
      case GrammarCategory.particles:
        return 'Particles';
    }
  }
}

/// Info chip for topic metadata
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(VibrantRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no topics found
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: VibrantSpacing.lg),
          Text(
            searchQuery.isEmpty ? 'No topics available' : 'No topics found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'Try a different search term',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Detailed grammar topic view with tables
class GrammarTopicDetail extends StatelessWidget {
  const GrammarTopicDetail({
    super.key,
    required this.topic,
  });

  final GrammarTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.lg),
            decoration: BoxDecoration(
              gradient: VibrantTheme.heroGradient,
              borderRadius: BorderRadius.circular(VibrantRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topic.title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Text(
                  topic.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: VibrantSpacing.xl),

          // Sections
          ...topic.sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.heading,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.md),
                  Text(
                    section.content,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),
                  if (section.table != null) ...[
                    const SizedBox(height: VibrantSpacing.lg),
                    _GrammarTableWidget(table: section.table!),
                  ],
                  if (section.notes != null && section.notes!.isNotEmpty) ...[
                    const SizedBox(height: VibrantSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(VibrantSpacing.md),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(VibrantRadius.md),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: VibrantSpacing.xs),
                              Text(
                                'Notes',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: VibrantSpacing.sm),
                          ...section.notes!.map((note) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: VibrantSpacing.xs),
                              child: Text('• $note', style: theme.textTheme.bodySmall),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),

          // Examples
          if (topic.examples.isNotEmpty) ...[
            Text(
              'Examples',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: VibrantSpacing.md),
            ...topic.examples.map((example) {
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: VibrantSpacing.md),
                padding: const EdgeInsets.all(VibrantSpacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(VibrantRadius.md),
                ),
                child: Text(
                  example,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// Grammar table widget
class _GrammarTableWidget extends StatelessWidget {
  const _GrammarTableWidget({required this.table});

  final GrammarTable table;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(VibrantRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headers
          Container(
            padding: const EdgeInsets.all(VibrantSpacing.sm),
            decoration: BoxDecoration(
              gradient: VibrantTheme.heroGradient,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(VibrantRadius.md),
              ),
            ),
            child: Row(
              children: table.headers.map((header) {
                return Expanded(
                  child: Text(
                    header,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }).toList(),
            ),
          ),
          // Rows
          ...table.rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            return Container(
              padding: const EdgeInsets.all(VibrantSpacing.sm),
              decoration: BoxDecoration(
                color: index.isEven
                    ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : null,
              ),
              child: Row(
                children: row.map((cell) {
                  return Expanded(
                    child: Text(
                      cell,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  );
                }).toList(),
              ),
            );
          }),
          // Caption
          if (table.caption != null)
            Padding(
              padding: const EdgeInsets.all(VibrantSpacing.sm),
              child: Text(
                table.caption!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
