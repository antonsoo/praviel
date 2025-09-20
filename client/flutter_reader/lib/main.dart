import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart' as rp;

import 'api/reader_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  final storage = FlutterSecureStorageAdapter();
  final storedKey = await storage.read(ByokController.apiKeyStorageKey);
  final storedEnabled = await storage.read(ByokController.enabledStorageKey) == '1';
  final initialByok = ByokState(
    apiKey: storedKey,
    enabled: storedKey != null && storedKey.isNotEmpty && storedEnabled,
  );

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        secureStorageProvider.overrideWithValue(storage),
        byokControllerProvider.overrideWith(
          (ref) => ByokController(storage: storage, initial: initialByok),
        ),
      ],
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

abstract class SecureStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
}

class FlutterSecureStorageAdapter implements SecureStorage {
  FlutterSecureStorageAdapter([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

final secureStorageProvider = Provider<SecureStorage>((_) => FlutterSecureStorageAdapter());

class ByokState {
  const ByokState({required this.apiKey, required this.enabled});

  final String? apiKey;
  final bool enabled;

  bool get hasKey => apiKey != null && apiKey!.isNotEmpty;
}

class ByokController extends StateNotifier<ByokState> {
  ByokController({required SecureStorage storage, required ByokState initial})
      : _storage = storage,
        super(initial);

  static const apiKeyStorageKey = 'openai_api_key';
  static const enabledStorageKey = 'openai_api_key_enabled';

  final SecureStorage _storage;

  Future<void> saveKey(String value, {required bool enabled}) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await clear();
      return;
    }
    await _storage.write(apiKeyStorageKey, trimmed);
    await _storage.write(enabledStorageKey, enabled ? '1' : '0');
    state = ByokState(apiKey: trimmed, enabled: enabled);
  }

  Future<void> updateEnabled(bool enabled) async {
    if (!state.hasKey) {
      await _storage.write(enabledStorageKey, '0');
      state = const ByokState(apiKey: null, enabled: false);
      return;
    }
    await _storage.write(enabledStorageKey, enabled ? '1' : '0');
    state = ByokState(apiKey: state.apiKey, enabled: enabled);
  }

  Future<void> clear() async {
    await _storage.delete(apiKeyStorageKey);
    await _storage.delete(enabledStorageKey);
    state = const ByokState(apiKey: null, enabled: false);
  }
}

final byokControllerProvider =
    StateNotifierProvider<ByokController, ByokState>((ref) =>
        throw UnimplementedError('byokControllerProvider must be overridden'));

final readerApiProvider = rp.Provider<ReaderApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = ReaderApi(baseUrl: config.apiBaseUrl);
  ref.onDispose(api.close);
  return api;
});

final latencyProvider = StateProvider<double?>((_) => null);

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
      ref.read(latencyProvider.notifier).state = null;
      state = rp.AsyncValue.error(
        'Provide Greek text to analyze.',
        StackTrace.current,
      );
      return;
    }

    final byok = ref.read(byokControllerProvider);
    final apiKey = byok.enabled && byok.hasKey ? byok.apiKey : null;

    state = const rp.AsyncValue.loading();
    final stopwatch = Stopwatch()..start();
    try {
      final result = await _api.analyze(
        query,
        lsj: includeLsj,
        smyth: includeSmyth,
        apiKey: apiKey,
      );
      stopwatch.stop();
      ref.read(latencyProvider.notifier).state =
          stopwatch.elapsedMilliseconds.toDouble();
      state = rp.AsyncValue.data(result);
    } catch (error, stackTrace) {
      stopwatch.stop();
      ref.read(latencyProvider.notifier).state =
          stopwatch.elapsedMilliseconds.toDouble();
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
      appBar: AppBar(
        title: const Text('Iliad Reader'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Configure OpenAI key',
              icon: const Icon(Icons.vpn_key_outlined),
              onPressed: _showByokSheet,
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
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
            ),
            if (kDebugMode) const _LatencyBadge(),
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

  void _showByokSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const _ByokSheet(),
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
            .where((entry) => entry.lemma.toLowerCase() == lemma.toLowerCase())
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
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
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

class _ByokSheet extends ConsumerStatefulWidget {
  const _ByokSheet();

  @override
  ConsumerState<_ByokSheet> createState() => _ByokSheetState();
}

class _ByokSheetState extends ConsumerState<_ByokSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(byokControllerProvider);
    _controller = TextEditingController(text: state.apiKey ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final byok = ref.watch(byokControllerProvider);
    final hasPendingKey = _controller.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bring your own OpenAI key (dev only)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'OpenAI API key',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              title: const Text('Send Authorization header'),
              contentPadding: EdgeInsets.zero,
              value: byok.enabled,
              onChanged: _isSaving
                  ? null
                  : (value) async {
                      if (!byok.hasKey && !hasPendingKey) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Save an API key before enabling BYOK.'),
                          ),
                        );
                        return;
                      }
                      setState(() => _isSaving = true);
                      if (!byok.hasKey && hasPendingKey) {
                        await ref
                            .read(byokControllerProvider.notifier)
                            .saveKey(_controller.text, enabled: value);
                      } else {
                        await ref
                            .read(byokControllerProvider.notifier)
                            .updateEnabled(value);
                      }
                      setState(() => _isSaving = false);
                    },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            await ref
                                .read(byokControllerProvider.notifier)
                                .saveKey(
                                  _controller.text,
                                  enabled: byok.enabled || hasPendingKey,
                                );
                            setState(() => _isSaving = false);
                          },
                    child: Text(byok.hasKey ? 'Update key' : 'Save key'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving || (!byok.hasKey && !hasPendingKey)
                        ? null
                        : () async {
                            setState(() => _isSaving = true);
                            await ref.read(byokControllerProvider.notifier).clear();
                            _controller.clear();
                            setState(() => _isSaving = false);
                          },
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Keys stay on-device via flutter_secure_storage and only attach to analyzer calls in debug builds.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LatencyBadge extends ConsumerWidget {
  const _LatencyBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latency = ref.watch(latencyProvider);
    if (latency == null) {
      return const SizedBox.shrink();
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withAlpha(230),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Last analyze: ${latency.toStringAsFixed(0)} ms',
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
          ),
        ),
      ),
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
        final subtitle =
            details.isEmpty ? 'No morphological analysis available.' : details.join(' · ');
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
