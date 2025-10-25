import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../services/search_api.dart';
import '../services/haptic_service.dart';
import '../theme/vibrant_animations.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/common/aurora_background.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/search/modern_search_bar.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage>
    with TickerProviderStateMixin {
  static const _typeLabels = <String, String>{
    'lexicon': 'Lexicon',
    'grammar': 'Grammar',
    'text': 'Texts',
  };
  static const _languageLabels = <String, String>{
    'grc': 'Greek',
    'lat': 'Latin',
    'hbo': 'Hebrew',
  };

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  late final AnimationController _heroController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  AsyncValue<SearchResponse?> _searchState = const AsyncValue.data(null);
  String _currentQuery = '';
  final Set<String> _selectedTypes = {'lexicon', 'grammar', 'text'};
  String? _selectedLanguage;
  int? _selectedWorkId;
  String? _selectedWorkLabel;
  List<SearchWork> _availableWorks = const [];
  bool _loadingWorks = false;
  String? _worksError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    final initial = widget.initialQuery?.trim();
    if (initial != null && initial.isNotEmpty) {
      _controller.text = initial;
      _currentQuery = initial;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runSearch();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWorks();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _heroController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _currentQuery = value;
    _debounce?.cancel();

    if (value.trim().length < 2) {
      setState(() {
        _searchState = const AsyncValue.data(null);
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  void _toggleType(String type) {
    HapticService.light();
    setState(() {
      if (_selectedTypes.contains(type)) {
        _selectedTypes.remove(type);
      } else {
        _selectedTypes.add(type);
      }
    });
    _runSearch();
  }

  void _selectLanguage(String? language) {
    setState(() {
      _selectedLanguage = language;
      _selectedWorkId = null;
      _selectedWorkLabel = null;
    });
    _loadWorks();
    _runSearch();
  }

  void _resetFilters() {
    HapticService.light();
    setState(() {
      _selectedTypes
        ..clear()
        ..addAll(_typeLabels.keys);
      _selectedLanguage = null;
      _selectedWorkId = null;
      _selectedWorkLabel = null;
      _availableWorks = const [];
    });
    _loadWorks();
    _runSearch();
  }

  void _showFilterModal() {
    HapticService.medium();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            var localTypes = Set<String>.from(_selectedTypes);
            var localLanguage = _selectedLanguage;
            var localWorkId = _selectedWorkId;
            var localWorkLabel = _selectedWorkLabel;

            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                expand: false,
                builder: (context, scrollController) {
                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: VibrantSpacing.sm),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(VibrantSpacing.lg),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Search Filters',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  localTypes
                                    ..clear()
                                    ..addAll(_typeLabels.keys);
                                  localLanguage = null;
                                  localWorkId = null;
                                  localWorkLabel = null;
                                });
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(VibrantSpacing.lg),
                          children: [
                            Text(
                              'Content Types',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.sm),
                            ..._typeLabels.entries.map((entry) {
                              return CheckboxListTile(
                                title: Text(entry.value),
                                value: localTypes.contains(entry.key),
                                onChanged: (value) {
                                  setModalState(() {
                                    if (value == true) {
                                      localTypes.add(entry.key);
                                    } else {
                                      localTypes.remove(entry.key);
                                    }
                                  });
                                },
                              );
                            }),
                            const SizedBox(height: VibrantSpacing.lg),
                            Text(
                              'Language',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: VibrantSpacing.sm),
                            ...[
                              _FilterOption('All Languages', null, localLanguage, (v) {
                                setModalState(() {
                                  localLanguage = v;
                                  localWorkId = null;
                                  localWorkLabel = null;
                                });
                              }),
                              ..._languageLabels.entries.map((e) =>
                                _FilterOption(e.value, e.key, localLanguage, (v) {
                                  setModalState(() {
                                    localLanguage = v;
                                    localWorkId = null;
                                    localWorkLabel = null;
                                  });
                                })
                              ),
                            ],
                            if (_availableWorks.isNotEmpty) ...[
                              const SizedBox(height: VibrantSpacing.lg),
                              Text(
                                'Specific Work',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: VibrantSpacing.sm),
                              RadioListTile<int?>(
                                title: const Text('All Works'),
                                value: null,
                                groupValue: localWorkId,
                                onChanged: (v) {
                                  setModalState(() {
                                    localWorkId = v;
                                    localWorkLabel = null;
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(VibrantSpacing.lg),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  _selectedTypes
                                    ..clear()
                                    ..addAll(localTypes);
                                  _selectedLanguage = localLanguage;
                                  _selectedWorkId = localWorkId;
                                  _selectedWorkLabel = localWorkLabel;
                                });
                                if (_currentQuery.trim().isNotEmpty) {
                                  _runSearch();
                                }
                                Navigator.of(context).pop();
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.all(VibrantSpacing.lg),
                              ),
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _runSearch() async {
    final query = _currentQuery.trim();
    if (query.length < 2) {
      setState(() {
        _searchState = const AsyncValue.data(null);
      });
      return;
    }

    setState(() {
      _searchState = const AsyncValue.loading();
    });

    try {
      final searchApi = ref.read(searchApiProvider);
      final types = _selectedTypes.isEmpty ? null : _selectedTypes.toList();
      final response = await searchApi.search(
        query: query,
        types: types,
        language: _selectedLanguage,
        workId: _selectedWorkId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _searchState = AsyncValue.data(response);
      });
    } catch (error, stack) {
      if (!mounted) {
        return;
      }
      setState(() {
        _searchState = AsyncValue.error(error, stack);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  VibrantSpacing.lg,
                  VibrantSpacing.lg,
                  VibrantSpacing.lg,
                  VibrantSpacing.md,
                ),
                child: _buildHeroSection(theme, colorScheme),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: VibrantSpacing.lg,
                vertical: VibrantSpacing.sm,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildFilterCard(theme, colorScheme),
                  const SizedBox(height: VibrantSpacing.lg),
                  _buildWorkCard(theme, colorScheme),
                  if (_selectedWorkId != null) ...[
                    const SizedBox(height: VibrantSpacing.md),
                    _buildSelectedWorkChip(),
                  ],
                  const SizedBox(height: VibrantSpacing.lg),
                  _buildResultsSection(theme, colorScheme),
                  const SizedBox(height: VibrantSpacing.xxxl),
                ]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildHeroSection(ThemeData theme, ColorScheme colorScheme) {
    final filtersActive = _selectedTypes.length;
    final languageLabel = _selectedLanguage == null
        ? 'All languages'
        : (_languageLabels[_selectedLanguage] ??
              _selectedLanguage!.toUpperCase());

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: const BoxDecoration(gradient: VibrantTheme.auroraGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: AuroraBackground(controller: _heroController),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore the classical library',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  'Search lexicon entries, grammar chapters, and curated texts with premium filters.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: VibrantSpacing.lg),
                ModernSearchBar(
                  controller: _controller,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => _runSearch(),
                  hint: 'Search lexicon, grammar, or texts…',
                  showFilter: true,
                  onFilter: () {
                    HapticService.medium();
                    _showFilterModal();
                  },
                  autofocus: false,
                ),
                const SizedBox(height: VibrantSpacing.md),
                Wrap(
                  spacing: VibrantSpacing.sm,
                  runSpacing: VibrantSpacing.xs,
                  children: [
                    _HeroChip(
                      icon: Icons.filter_alt_rounded,
                      label: '$filtersActive filters',
                    ),
                    _HeroChip(
                      icon: Icons.language_rounded,
                      label: languageLabel,
                    ),
                    if (_selectedWorkLabel != null)
                      _HeroChip(
                        icon: Icons.menu_book_rounded,
                        label: _selectedWorkLabel!,
                      ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _resetFilters,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.9),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(ThemeData theme, ColorScheme colorScheme) {
    return GlassmorphismCard(
      blur: 18,
      borderRadius: 28,
      opacity: 0.16,
      borderOpacity: 0.22,
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Content types',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          _buildTypeFilters(colorScheme),
          const SizedBox(height: VibrantSpacing.md),
          Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'Languages',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          _buildLanguageFilters(colorScheme),
        ],
      ),
    );
  }

  Widget _buildWorkCard(ThemeData theme, ColorScheme colorScheme) {
    return GlassmorphismCard(
      blur: 18,
      borderRadius: 28,
      opacity: 0.16,
      borderOpacity: 0.22,
      padding: const EdgeInsets.all(VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Limit to specific work',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: VibrantSpacing.sm),
          _buildWorkSelector(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildResultsSection(ThemeData theme, ColorScheme colorScheme) {
    return AnimatedSwitcher(
      duration: VibrantDuration.moderate,
      switchInCurve: VibrantCurve.smooth,
      child: _searchState.when(
        data: (data) {
          if (data == null) {
            return _buildPlaceholder(theme, colorScheme);
          }
          if (data.totalResults == 0) {
            return _buildNoResults(theme);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.lexiconResults.isNotEmpty)
                _LexiconSection(results: data.lexiconResults),
              if (data.grammarResults.isNotEmpty)
                _GrammarSection(results: data.grammarResults),
              if (data.textResults.isNotEmpty)
                _TextSection(
                  results: data.textResults,
                  onOpen: _handleTextSelection,
                  onFilter: _filterByWork,
                ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: VibrantSpacing.xxxl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => _buildError(theme, error),
      ),
    );
  }

  Widget _buildTypeFilters(ColorScheme colorScheme) {
    return Wrap(
      spacing: VibrantSpacing.sm,
      runSpacing: VibrantSpacing.xs,
      children: _typeLabels.entries.map((entry) {
        final selected = _selectedTypes.contains(entry.key);
        return FilterChip(
          label: Text(entry.value),
          selected: selected,
          onSelected: (_) => _toggleType(entry.key),
          selectedColor: colorScheme.primary.withValues(alpha: 0.2),
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: selected
                ? Colors.white
                : colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.4,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageFilters(ColorScheme colorScheme) {
    return Wrap(
      spacing: VibrantSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('All languages'),
          selected: _selectedLanguage == null,
          onSelected: (selected) {
            if (selected) {
              _selectLanguage(null);
            }
          },
          labelStyle: TextStyle(
            color: _selectedLanguage == null
                ? Colors.white
                : colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
          ),
          selectedColor: colorScheme.secondary.withValues(alpha: 0.35),
          checkmarkColor: Colors.white,
          backgroundColor: colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
        ),
        for (final entry in _languageLabels.entries)
          ChoiceChip(
            label: Text(entry.value),
            selected: _selectedLanguage == entry.key,
            onSelected: (selected) {
              if (selected) {
                _selectLanguage(entry.key);
              }
            },
            selectedColor: colorScheme.secondary.withValues(alpha: 0.35),
            checkmarkColor: Colors.white,
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            labelStyle: TextStyle(
              color: _selectedLanguage == entry.key
                  ? Colors.white
                  : colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildWorkSelector(ThemeData theme, ColorScheme colorScheme) {
    final items = <DropdownMenuItem<int?>>[
      const DropdownMenuItem<int?>(value: null, child: Text('All works')),
      ..._availableWorks.map(
        (work) => DropdownMenuItem<int?>(
          value: work.id,
          child: Text('${work.author} — ${work.title}'),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<int?>(
          isExpanded: true,
          initialValue: _selectedWorkId,
          items: items,
          decoration: const InputDecoration(
            labelText: 'Limit to work',
            prefixIcon: Icon(Icons.menu_book_outlined),
          ),
          onChanged: (value) {
            if (value == null) {
              _selectWork(null, null);
            } else {
              final work = _availableWorks.firstWhere(
                (w) => w.id == value,
                orElse: () => SearchWork(
                  id: value,
                  title: _selectedWorkLabel ?? 'Work $value',
                  author: '',
                  language: _selectedLanguage ?? '',
                ),
              );
              final label = work.author.isNotEmpty
                  ? '${work.author} — ${work.title}'
                  : work.title;
              _selectWork(work.id, label);
            }
          },
        ),
        if (_loadingWorks)
          const Padding(
            padding: EdgeInsets.only(top: VibrantSpacing.xs),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (_worksError != null)
          Padding(
            padding: const EdgeInsets.only(top: VibrantSpacing.xs),
            child: Text(
              _worksError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectedWorkChip() {
    final label =
        _selectedWorkLabel ??
        (_selectedWorkId != null ? 'Work $_selectedWorkId' : 'Work');
    return Align(
      alignment: Alignment.centerLeft,
      child: GlassmorphismCard(
        blur: 16,
        borderRadius: 24,
        opacity: 0.2,
        borderOpacity: 0.35,
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.md,
          vertical: VibrantSpacing.xs,
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_rounded, color: Colors.white, size: 18),
            const SizedBox(width: VibrantSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: VibrantSpacing.sm),
            IconButton(
              onPressed: () => _selectWork(null, null),
              icon: const Icon(Icons.close, color: Colors.white, size: 18),
              tooltip: 'Clear work filter',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, ColorScheme colorScheme) {
    return GlassmorphismCard(
      blur: 16,
      borderRadius: 28,
      opacity: 0.16,
      borderOpacity: 0.24,
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 48,
            color: colorScheme.primary.withValues(alpha: 0.9),
          ),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'Search our lexicon, grammar, and curated texts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return GlassmorphismCard(
      blur: 16,
      borderRadius: 28,
      opacity: 0.16,
      borderOpacity: 0.24,
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sentiment_dissatisfied, size: 48),
          const SizedBox(height: VibrantSpacing.sm),
          Text('No results found.', style: theme.textTheme.titleMedium),
          const SizedBox(height: VibrantSpacing.xs),
          Text(
            'Try a different spelling or broaden your filters.',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme, Object error) {
    return GlassmorphismCard(
      blur: 16,
      borderRadius: 28,
      opacity: 0.16,
      borderOpacity: 0.24,
      padding: const EdgeInsets.all(VibrantSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: VibrantSpacing.sm),
          Text('Search error', style: theme.textTheme.titleMedium),
          const SizedBox(height: VibrantSpacing.xs),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleTextSelection(TextPassage entry) {
    Navigator.of(context).pop({
      'target': 'reader',
      'text': entry.passage,
      'includeLsj': true,
      'includeSmyth': true,
    });
  }

  void _filterByWork(TextPassage entry) {
    setState(() {
      _selectedWorkId = entry.workId;
      _selectedWorkLabel =
          '${entry.author.isNotEmpty ? '${entry.author} — ' : ''}${entry.workTitle}';
      _selectedTypes.add('text');
      if (_availableWorks.every((work) => work.id != entry.workId)) {
        final updated = [
          ..._availableWorks,
          SearchWork(
            id: entry.workId,
            title: entry.workTitle,
            author: entry.author,
            language: _selectedLanguage ?? '',
          ),
        ]..sort((a, b) => (a.author + a.title).compareTo(b.author + b.title));
        _availableWorks = updated;
      }
    });
    _runSearch();
  }

  void _selectWork(int? workId, String? label) {
    setState(() {
      _selectedWorkId = workId;
      _selectedWorkLabel = label;
    });
    _runSearch();
  }

  Future<void> _loadWorks() async {
    setState(() {
      _loadingWorks = true;
      _worksError = null;
    });
    try {
      final api = ref.read(searchApiProvider);
      final works = await api.fetchWorks(language: _selectedLanguage);
      if (!mounted) {
        return;
      }
      setState(() {
        _availableWorks = works;
        _loadingWorks = false;
        if (_selectedWorkId != null &&
            works.every((work) => work.id != _selectedWorkId)) {
          _selectedWorkId = null;
          _selectedWorkLabel = null;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingWorks = false;
        _availableWorks = const [];
        _worksError = error.toString();
      });
    }
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassmorphismCard(
      blur: 14,
      borderRadius: 22,
      opacity: 0.18,
      borderOpacity: 0.3,
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: VibrantSpacing.xxs),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: VibrantSpacing.xs),
          Text(
            '$count',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LexiconSection extends StatelessWidget {
  const _LexiconSection({required this.results});

  final List<LexiconEntry> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Lexicon', count: results.length),
          ...results.map(
            (entry) => GlassmorphismCard(
              margin: const EdgeInsets.only(bottom: VibrantSpacing.sm),
              padding: const EdgeInsets.all(VibrantSpacing.md),
              blur: 16,
              borderRadius: 24,
              opacity: 0.14,
              borderOpacity: 0.22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.lemma,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: VibrantSpacing.xs),
                      if (entry.partOfSpeech != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VibrantSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              VibrantRadius.sm,
                            ),
                          ),
                          child: Text(
                            entry.partOfSpeech!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (entry.shortDefinition != null) ...[
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      entry.shortDefinition!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.85,
                        ),
                      ),
                    ),
                  ],
                  if (entry.forms.isNotEmpty) ...[
                    const SizedBox(height: VibrantSpacing.sm),
                    Wrap(
                      spacing: VibrantSpacing.xs,
                      runSpacing: VibrantSpacing.xs,
                      children: entry.forms
                          .map(
                            (form) => Chip(
                              label: Text(form),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrammarSection extends StatelessWidget {
  const _GrammarSection({required this.results});

  final List<GrammarEntry> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Grammar', count: results.length),
          ...results.map(
            (entry) => GlassmorphismCard(
              margin: const EdgeInsets.only(bottom: VibrantSpacing.sm),
              padding: const EdgeInsets.all(VibrantSpacing.md),
              blur: 16,
              borderRadius: 24,
              opacity: 0.14,
              borderOpacity: 0.22,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: VibrantSpacing.xs),
                  Text(
                    entry.summary ?? entry.content ?? 'No summary available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.85,
                      ),
                    ),
                  ),
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: VibrantSpacing.sm),
                    Wrap(
                      spacing: VibrantSpacing.xs,
                      runSpacing: VibrantSpacing.xs,
                      children: entry.tags
                          .map(
                            (tag) => Chip(
                              avatar: const Icon(Icons.tag, size: 14),
                              label: Text(tag),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: theme
                                  .colorScheme
                                  .secondaryContainer
                                  .withValues(alpha: 0.4),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.results,
    required this.onOpen,
    required this.onFilter,
  });

  final List<TextPassage> results;
  final void Function(TextPassage) onOpen;
  final void Function(TextPassage) onFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Texts', count: results.length),
          ...results.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: VibrantSpacing.sm),
              child: AnimatedScaleButton(
                onTap: () {
                  HapticService.medium();
                  onOpen(entry);
                },
                child: GlassmorphismCard(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  blur: 18,
                  borderRadius: 28,
                  opacity: 0.18,
                  borderOpacity: 0.25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.workTitle} — ${entry.author}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: VibrantSpacing.xs),
                      Text(
                        entry.passage,
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                      if (entry.translation != null) ...[
                        const SizedBox(height: VibrantSpacing.xs),
                        Text(
                          entry.translation!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: VibrantSpacing.sm),
                      Row(
                        children: [
                          const Icon(Icons.bookmark_outline, size: 16),
                          const SizedBox(width: VibrantSpacing.xs),
                          Text(
                            entry.reference,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.9),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.trending_up, size: 16),
                          const SizedBox(width: VibrantSpacing.xs),
                          Text(
                            entry.relevanceScore.toStringAsFixed(2),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: VibrantSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.filter_list, size: 16),
                          label: const Text('Only this work'),
                          onPressed: () => onFilter(entry),
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
}

class _FilterOption extends StatelessWidget {
  const _FilterOption(this.label, this.value, this.groupValue, this.onChanged);
  
  final String label;
  final String? value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;
  
  @override
  Widget build(BuildContext context) {
    return RadioListTile<String?>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }
}
