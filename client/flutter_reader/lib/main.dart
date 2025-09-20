import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart' as rp;

import 'api/reader_api.dart';

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

class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  static Future<AppConfig> load() async {
    final raw = await rootBundle.loadString('assets/config/dev.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final baseUrl = data['apiBaseUrl'] as String? ?? '';
    if (baseUrl.isEmpty) {
      throw StateError('apiBaseUrl missing in config');
    }
    return AppConfig(apiBaseUrl: baseUrl);
  }
}

final appConfigProvider = rp.Provider<AppConfig>((_) {
  throw UnimplementedError('AppConfig must be overridden');
});

final readerApiProvider = rp.Provider<ReaderApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = ReaderApi(baseUrl: config.apiBaseUrl);
  ref.onDispose(api.close);
  return api;
});

final analysisControllerProvider =
    rp.AsyncNotifierProvider<AnalysisController, AnalyzeResult?>(
      AnalysisController.new,
    );

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
      title: 'Iliad Reader',
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
  late final TextEditingController _controller;
  bool _includeLsj = true;
  bool _includeSmyth = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'Μῆνιν ἄειδε');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Iliad Reader')),
      body: SafeArea(
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
                  hintText: 'Μῆνιν ἄειδε, θεά... ',
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
                      onChanged: (value) =>
                          setState(() => _includeSmyth = value),
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
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorMessage(error: error),
                ),
              ),
            ],
          ),
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
