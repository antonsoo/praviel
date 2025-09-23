import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as rp;

import 'app_providers.dart';
import 'api/reader_api.dart';
import 'localization/strings_lessons_en.dart';
import 'models/app_config.dart';
import 'models/lesson.dart';
import 'pages/lessons_page.dart';
import 'services/byok_controller.dart';
import 'services/lesson_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const ReaderApp(),
    ),
  );
}

final analysisControllerProvider =
    rp.AsyncNotifierProvider<AnalysisController, AnalyzeResult?>(
      AnalysisController.new,
    );

final readerIntentProvider = StateProvider<ReaderIntent?>((_) => null);

class ReaderIntent {
  ReaderIntent({
    required this.text,
    this.includeLsj = true,
    this.includeSmyth = true,
  });

  final String text;
  final bool includeLsj;
  final bool includeSmyth;
}

class AnalysisController extends rp.AsyncNotifier<AnalyzeResult?> {
  late final ReaderApi _api;

  @override
  Future<AnalyzeResult?> build() async {
    _api = ref.watch(readerApiProvider);
    return null;
  }

  Future<void> analyze(
    String raw, {
    required bool includeLsj,
    required bool includeSmyth,
  }) async {
    final query = raw.trim();
    if (query.isEmpty) {
      state = rp.AsyncValue.error(
        'Provide Greek text to analyze.',
        StackTrace.current,
      );
      return;
    }

    state = const rp.AsyncValue.loading();
    try {
      final result = await _api.analyze(
        query,
        lsj: includeLsj,
        smyth: includeSmyth,
      );
      state = rp.AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = rp.AsyncValue.error(error, stackTrace);
    }
  }
}

class ReaderApp extends ConsumerWidget {
  const ReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ancient Languages',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: 'GentiumPlus',
      ),
      home: const ReaderHomePage(),
    );
  }
}

class ReaderHomePage extends ConsumerStatefulWidget {
  const ReaderHomePage({super.key});

  @override
  ConsumerState<ReaderHomePage> createState() => _ReaderHomePageState();
}

class _ReaderHomePageState extends ConsumerState<ReaderHomePage> {
  int _tabIndex = 0;
  final GlobalKey<ReaderTabState> _readerKey = GlobalKey<ReaderTabState>();

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final params = Uri.base.queryParameters;
      if (params['tab'] == 'lessons') {
        _tabIndex = 1;
      }
      final readerText = params['reader_text'];
      if (readerText != null && readerText.trim().isNotEmpty) {
        final includeLsj = params['reader_lsj'] != '0';
        final includeSmyth = params['reader_smyth'] != '0';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ref.read(readerIntentProvider.notifier).state = ReaderIntent(
            text: readerText,
            includeLsj: includeLsj,
            includeSmyth: includeSmyth,
          );
          if (_tabIndex != 0) {
            setState(() => _tabIndex = 0);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonApi = ref.watch(lessonApiProvider);
    final tabs = [
      ReaderTab(key: _readerKey),
      LessonsPage(api: lessonApi, openReader: _openReaderFromLessons),
    ];
    final titles = ['Reader', L10nLessons.tabTitle];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'Configure provider key',
            onPressed: _showByokSheet,
          ),
        ],
      ),
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Reader',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Lessons',
          ),
        ],
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
      ),
    );
  }

  void _openReaderFromLessons(ClozeTask task) {
    ref.read(readerIntentProvider.notifier).state = ReaderIntent(
      text: task.text,
      includeLsj: true,
      includeSmyth: true,
    );
    setState(() => _tabIndex = 0);
  }

  Future<void> _showByokSheet() async {
    final notifier = ref.read(byokControllerProvider.notifier);
    final current = notifier.current;
    final result = await showModalBottomSheet<ByokSettings>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ByokSheet(initial: current),
    );
    if (!mounted || result == null) {
      return;
    }
    await notifier.saveSettings(result);
  }
}

class _ByokSheet extends StatefulWidget {
  const _ByokSheet({required this.initial});

  final ByokSettings initial;

  @override
  State<_ByokSheet> createState() => _ByokSheetState();
}

class _ByokSheetState extends State<_ByokSheet> {
  late final TextEditingController _keyController;
  late final TextEditingController _lessonModelController;
  late final TextEditingController _ttsModelController;
  late String _lessonProvider;
  late String _ttsProvider;
  bool _obscure = true;

  bool get _requiresKey => _lessonProvider != 'echo' || _ttsProvider != 'echo';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _keyController = TextEditingController(text: initial.apiKey);
    _lessonModelController = TextEditingController(
      text: initial.lessonModel ?? '',
    );
    _ttsModelController = TextEditingController(text: initial.ttsModel ?? '');
    _lessonProvider = _normalizeProvider(initial.lessonProvider);
    _ttsProvider = _normalizeProvider(initial.ttsProvider);
    _keyController.addListener(_onChanged);
    _lessonModelController.addListener(_onChanged);
    _ttsModelController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _keyController.removeListener(_onChanged);
    _lessonModelController.removeListener(_onChanged);
    _ttsModelController.removeListener(_onChanged);
    _keyController.dispose();
    _lessonModelController.dispose();
    _ttsModelController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  String _normalizeProvider(String raw) {
    return raw.trim().toLowerCase() == 'openai' ? 'openai' : 'echo';
  }

  void _handleSave() {
    final lessonModel = _lessonModelController.text.trim();
    final ttsModel = _ttsModelController.text.trim();
    final settings = ByokSettings(
      apiKey: _keyController.text.trim(),
      lessonProvider: _lessonProvider,
      lessonModel: lessonModel.isEmpty ? null : lessonModel,
      ttsProvider: _ttsProvider,
      ttsModel: ttsModel.isEmpty ? null : ttsModel,
    );
    Navigator.pop(context, settings);
  }

  void _handleClear() {
    Navigator.pop(context, const ByokSettings());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bring your own key', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              'Keys stay on-device. Enable BYOK providers to send your OpenAI credentials per request.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'API key',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _lessonProvider,
              decoration: const InputDecoration(labelText: 'Lesson provider'),
              items: const [
                DropdownMenuItem(value: 'echo', child: Text('Echo (offline)')),
                DropdownMenuItem(value: 'openai', child: Text('OpenAI (BYOK)')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _lessonProvider = value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _lessonModelController,
              decoration: const InputDecoration(
                labelText: 'Lesson model',
                hintText: 'gpt-5-mini',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _ttsProvider,
              decoration: const InputDecoration(labelText: 'TTS provider'),
              items: const [
                DropdownMenuItem(value: 'echo', child: Text('Echo (offline)')),
                DropdownMenuItem(value: 'openai', child: Text('OpenAI (BYOK)')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _ttsProvider = value);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ttsModelController,
              decoration: const InputDecoration(
                labelText: 'TTS model',
                hintText: 'gpt-4o-mini-tts',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: _handleClear, child: const Text('Clear')),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _requiresKey && _keyController.text.trim().isEmpty
                      ? null
                      : _handleSave,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReaderTab extends ConsumerStatefulWidget {
  const ReaderTab({super.key});

  @override
  ReaderTabState createState() => ReaderTabState();
}

class ReaderTabState extends ConsumerState<ReaderTab> {
  late final TextEditingController _controller;
  bool _includeLsj = true;
  bool _includeSmyth = true;
  late final rp.ProviderSubscription<ReaderIntent?> _intentSubscription;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'Μῆνιν ἄειδε');
    _intentSubscription = ref.listenManual<ReaderIntent?>(
      readerIntentProvider,
      (previous, next) {
        if (next == null) {
          return;
        }
        _controller.text = next.text;
        setState(() {
          _includeLsj = next.includeLsj;
          _includeSmyth = next.includeSmyth;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onAnalyze();
          }
        });
        ref.read(readerIntentProvider.notifier).state = null;
      },
    );
  }

  @override
  void dispose() {
    _intentSubscription.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisControllerProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 3,
              style: Theme.of(context).textTheme.bodyLarge,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Greek text',
                hintText: 'Μῆνιν ἄειδε, θεά…',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SwitchListTile.adaptive(
                    title: const Text('Include LSJ'),
                    value: _includeLsj,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _includeLsj = value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SwitchListTile.adaptive(
                    title: const Text('Include Smyth'),
                    value: _includeSmyth,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => _includeSmyth = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: analysis.isLoading ? null : _onAnalyze,
              icon: const Icon(Icons.search),
              label: const Text('Analyze'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: analysis.when(
                data: (result) {
                  if (result == null) {
                    return const _PlaceholderMessage(
                      message:
                          'Paste Iliad 1.1–1.10 and tap Analyze to inspect lemma and morphology.',
                    );
                  }
                  return _TokenList(
                    result: result,
                    onTap: (token) => _showTokenSheet(context, token, result),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => _ErrorMessage(error: error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAnalyze() {
    ref
        .read(analysisControllerProvider.notifier)
        .analyze(
          _controller.text,
          includeLsj: _includeLsj,
          includeSmyth: _includeSmyth,
        );
  }

  void _showTokenSheet(
    BuildContext context,
    AnalyzeToken token,
    AnalyzeResult result,
  ) {
    final lemma = token.lemma?.trim();
    final lexiconMatches = lemma == null || lemma.isEmpty
        ? const <LexiconEntry>[]
        : result.lexicon
              .where(
                (entry) => entry.lemma.toLowerCase() == lemma.toLowerCase(),
              )
              .toList(growable: false);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  token.text,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text('Lemma: ${token.lemma ?? '—'}'),
                Text('Morphology: ${token.morph ?? '—'}'),
                if (lexiconMatches.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('LSJ', style: Theme.of(context).textTheme.titleMedium),
                  for (final entry in lexiconMatches) ...[
                    const SizedBox(height: 8),
                    if (entry.gloss != null && entry.gloss!.isNotEmpty)
                      Text(entry.gloss!),
                    if (entry.citation != null && entry.citation!.isNotEmpty)
                      Text(
                        entry.citation!,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Source: Liddell–Scott–Jones (Perseus)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
                if (result.grammar.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Smyth', style: Theme.of(context).textTheme.titleMedium),
                  for (final topic in result.grammar.take(5)) ...[
                    const SizedBox(height: 8),
                    Text(topic.title),
                    Text(
                      topic.anchor,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Source: Smyth, Greek Grammar',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TokenList extends StatelessWidget {
  const _TokenList({required this.result, required this.onTap});

  final AnalyzeResult result;
  final void Function(AnalyzeToken token) onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = result.tokens;
    if (tokens.isEmpty) {
      return const _PlaceholderMessage(
        message: 'No tokens returned from the analyzer.',
      );
    }
    return ListView.separated(
      itemCount: tokens.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final token = tokens[index];
        final details = <String>[];
        if (token.lemma != null && token.lemma!.isNotEmpty) {
          details.add('Lemma: ${token.lemma}');
        }
        if (token.morph != null && token.morph!.isNotEmpty) {
          details.add('Morph: ${token.morph}');
        }
        final subtitle = details.isEmpty
            ? 'No morphological analysis available.'
            : details.join(' · ');
        return ListTile(
          title: Text(token.text),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.unfold_more),
          onTap: () => onTap(token),
        );
      },
    );
  }
}

class _PlaceholderMessage extends StatelessWidget {
  const _PlaceholderMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Unable to analyze.\n${error.toString()}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
