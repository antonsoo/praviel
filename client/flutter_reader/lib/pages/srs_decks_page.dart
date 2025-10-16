import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/srs_api.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_animations.dart';
import 'srs_review_page.dart';
import 'srs_create_card_page.dart';

/// SRS Deck Browser - Browse flashcard decks and statistics
class SrsDecksPage extends ConsumerStatefulWidget {
  const SrsDecksPage({super.key, required this.srsApi});

  final SrsApi srsApi;

  @override
  ConsumerState<SrsDecksPage> createState() => _SrsDecksPageState();
}

class _SrsDecksPageState extends ConsumerState<SrsDecksPage> {
  Map<String, SrsDeckStats> _deckStats = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDecks();
  }

  Future<void> _loadDecks() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final stats = await widget.srsApi.getDeckStats();
      if (mounted) {
        setState(() {
          _deckStats = stats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load decks: $e';
          _loading = false;
        });
      }
    }
  }

  void _navigateToReview(String? deck) {
    HapticService.medium();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SrsReviewPage(srsApi: widget.srsApi, deck: deck),
      ),
    );
  }

  void _navigateToCreateCard() {
    HapticService.medium();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SrsCreateCardPage(srsApi: widget.srsApi),
      ),
    ).then((created) {
      if (created == true) {
        _loadDecks(); // Reload stats after creating a card
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SRS Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToCreateCard,
            tooltip: 'Create Card',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDecks,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(_error!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDecks,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_deckStats.isEmpty) {
      return _buildEmptyState(theme, colorScheme);
    }

    return RefreshIndicator(
      onRefresh: _loadDecks,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // All Cards Overview
          _buildOverviewCard(theme, colorScheme),
          const SizedBox(height: 24),

          // Deck List
          Text(
            'Decks',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Individual decks
          ..._deckStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDeckCard(theme, colorScheme, entry.key, entry.value),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: SlideInFromBottom(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style_outlined, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'No Flashcards Yet',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first flashcard to start learning',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToCreateCard,
              icon: const Icon(Icons.add),
              label: const Text('Create Flashcard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(ThemeData theme, ColorScheme colorScheme) {
    // Calculate totals across all decks
    int totalCards = 0;
    int totalNew = 0;
    int totalLearning = 0;
    int totalReview = 0;
    int totalDue = 0;

    for (final stats in _deckStats.values) {
      totalCards += stats.totalCards;
      totalNew += stats.newCards;
      totalLearning += stats.learningCards;
      totalReview += stats.reviewCards;
      totalDue += stats.dueToday;
    }

    return ScaleIn(
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: totalDue > 0 ? () => _navigateToReview(null) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.dashboard,
                        color: colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Cards',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$totalCards total cards',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (totalDue > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$totalDue due',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatChip(
                      theme,
                      colorScheme,
                      'New',
                      totalNew,
                      Colors.blue,
                    ),
                    _buildStatChip(
                      theme,
                      colorScheme,
                      'Learning',
                      totalLearning,
                      Colors.orange,
                    ),
                    _buildStatChip(
                      theme,
                      colorScheme,
                      'Review',
                      totalReview,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeckCard(
    ThemeData theme,
    ColorScheme colorScheme,
    String deckName,
    SrsDeckStats stats,
  ) {
    final hasDue = stats.dueToday > 0;

    return ScaleIn(
      child: Card(
        elevation: 1,
        child: InkWell(
          onTap: hasDue ? () => _navigateToReview(deckName) : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.folder,
                        color: colorScheme.onSecondaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deckName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${stats.totalCards} cards',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasDue)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${stats.dueToday}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMiniStat(
                      theme,
                      colorScheme,
                      'New',
                      stats.newCards,
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      theme,
                      colorScheme,
                      'Learning',
                      stats.learningCards,
                      Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _buildMiniStat(
                      theme,
                      colorScheme,
                      'Review',
                      stats.reviewCards,
                      Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    int value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    ThemeData theme,
    ColorScheme colorScheme,
    String label,
    int value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: $value',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
