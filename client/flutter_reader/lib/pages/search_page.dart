import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../services/search_api.dart';
import '../theme/vibrant_theme.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
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
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
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
      appBar: AppBar(
        title: const Text('Search Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Reset filters',
            onPressed: () {
              setState(() {
                _selectedTypes
                  ..clear()
                  ..addAll(_typeLabels.keys);
                _selectedLanguage = null;
                _selectedWorkId = null;
                _selectedWorkLabel = null;
              });
              _runSearch();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(theme),
              const SizedBox(height: VibrantSpacing.md),
              _buildTypeFilters(colorScheme),
              const SizedBox(height: VibrantSpacing.sm),
              _buildLanguageFilters(colorScheme),
              const SizedBox(height: VibrantSpacing.sm),
              _buildWorkSelector(theme, colorScheme),
              if (_selectedWorkId != null) ...[
                const SizedBox(height: VibrantSpacing.sm),
                _buildSelectedWorkChip(),
              ],
              const SizedBox(height: VibrantSpacing.lg),
              Expanded(child: _buildResults(theme, colorScheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.search,
      onChanged: _onQueryChanged,
      onSubmitted: (_) => _runSearch(),
      decoration: InputDecoration(
        hintText: 'Search lexicon, grammar, or texts…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _controller.clear();
                  _onQueryChanged('');
                  _focusNode.requestFocus();
                },
                icon: const Icon(Icons.close),
              ),
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
          selectedColor: colorScheme.primary.withValues(alpha: 0.15),
          checkmarkColor: colorScheme.primary,
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
            selectedColor: colorScheme.secondary.withValues(alpha: 0.15),
            checkmarkColor: colorScheme.secondary,
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
      child: InputChip(
        avatar: const Icon(Icons.filter_alt_outlined),
        label: Text(label),
        deleteIcon: const Icon(Icons.close),
        onDeleted: () => _selectWork(null, null),
      ),
    );
  }

  Widget _buildResults(ThemeData theme, ColorScheme colorScheme) {
    return _searchState.when(
      data: (data) {
        if (data == null) {
          return _buildPlaceholder(theme, colorScheme);
        }
        if (data.totalResults == 0) {
          return _buildNoResults(theme);
        }
        return ListView(
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
            const SizedBox(height: VibrantSpacing.lg),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildError(theme, error),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: VibrantSpacing.md),
          Text(
            'Search our lexicon, grammar, and curated texts.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
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
    return Center(
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
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: VibrantSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          entry.lemma,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: VibrantSpacing.xs),
                        if (entry.partOfSpeech != null)
                          Text(
                            entry.partOfSpeech!,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    if (entry.shortDefinition != null) ...[
                      const SizedBox(height: VibrantSpacing.xs),
                      Text(
                        entry.shortDefinition!,
                        style: theme.textTheme.bodyMedium,
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
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
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
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: VibrantSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Grammar', count: results.length),
          ...results.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: VibrantSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(VibrantSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xs),
                    Text(
                      entry.summary ?? entry.content ?? 'No summary available.',
                      style: theme.textTheme.bodyMedium,
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
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
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
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: VibrantSpacing.sm),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onOpen(entry),
                child: Padding(
                  padding: const EdgeInsets.all(VibrantSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.workTitle} — ${entry.author}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: VibrantSpacing.xs),
                      Text(entry.passage, style: theme.textTheme.bodyLarge),
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
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.trending_up, size: 16),
                          const SizedBox(width: VibrantSpacing.xs),
                          Text(
                            entry.relevanceScore.toStringAsFixed(2),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
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
