import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;
import 'package:riverpod/legacy.dart' as legacy;
import 'package:riverpod/riverpod.dart' as rp;

import 'api/reader_api.dart';
import 'app_providers.dart';
import 'localization/strings_lessons_en.dart';
import 'models/app_config.dart';
import 'models/lesson.dart';
import 'pages/lessons_page.dart';
import 'services/byok_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/surface.dart';

const bool kIntegrationTestMode = bool.fromEnvironment('INTEGRATION_TEST');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await AppConfig.load();
  runApp(
    frp.ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const ReaderApp(),
    ),
  );
}

final analysisControllerProvider =
    rp.AsyncNotifierProvider<AnalysisController, AnalyzeResult?>(
      AnalysisController.new,
    );

final readerIntentProvider = legacy.StateProvider<ReaderIntent?>((_) => null);

final onboardingShownProvider = legacy.StateProvider<bool>((ref) => false);

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

class _ModelPreset {
  const _ModelPreset(this.value, this.label);

  final String value;
  final String label;
}

const List<_ModelPreset> _kLessonModelPresets = <_ModelPreset>[
  _ModelPreset('gpt-4o-mini', 'GPT-4o mini'),
  _ModelPreset('gpt-4o', 'GPT-4o'),
  _ModelPreset('gpt-4.1-mini', 'GPT-4.1 mini'),
  _ModelPreset('gpt-4.1', 'GPT-4.1'),
];

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

class ReaderApp extends frp.ConsumerWidget {
  const ReaderApp({super.key});

  @override
  Widget build(BuildContext context, frp.WidgetRef ref) {
    return MaterialApp(
      title: 'Ancient Languages',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const ReaderHomePage(),
    );
  }
}

class ReaderHomePage extends frp.ConsumerStatefulWidget {
  const ReaderHomePage({super.key});

  @override
  frp.ConsumerState<ReaderHomePage> createState() => _ReaderHomePageState();
}

class _ReaderHomePageState extends frp.ConsumerState<ReaderHomePage> {
  int _tabIndex = 0;
  final GlobalKey<ReaderTabState> _readerKey = GlobalKey<ReaderTabState>();
  final GlobalKey<LessonsPageState> _lessonsKey = GlobalKey<LessonsPageState>();

  late final frp.ProviderSubscription<frp.AsyncValue<ByokSettings>> _byokSubscription;

  @override
  void initState() {
    super.initState();
    if (kIntegrationTestMode) {
      Future(() {
        if (!mounted) {
          return;
        }
        ref.read(onboardingShownProvider.notifier).state = true;
      });
    }
    _byokSubscription = ref.listenManual<frp.AsyncValue<ByokSettings>>(
      byokControllerProvider,
      (previous, next) {
        next.whenOrNull(data: _handleOnboardingMaybe);
      },
    );
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
      LessonsPage(key: _lessonsKey, api: lessonApi, openReader: _openReaderFromLessons),
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

  void _handleOnboardingMaybe(ByokSettings settings) {
    if (kIntegrationTestMode) {
      return;
    }
    if (!mounted) {
      return;
    }
    final seen = ref.read(onboardingShownProvider);
    if (seen) {
      return;
    }
    if (!_shouldOfferOnboarding(settings)) {
      return;
    }
    ref.read(onboardingShownProvider.notifier).state = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _showOnboarding();
    });
  }

  bool _shouldOfferOnboarding(ByokSettings settings) {
    if (settings.hasKey) {
      return false;
    }
    if (settings.lessonProvider != 'echo') {
      return false;
    }
    final model = settings.lessonModel;
    if (model != null && model.trim().isNotEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _showOnboarding() async {
    if (kIntegrationTestMode) {
      return;
    }
    ref.read(onboardingShownProvider.notifier).state = true;
    final notifier = ref.read(byokControllerProvider.notifier);
    final current = notifier.current;
    final result = await showModalBottomSheet<_OnboardingResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _OnboardingSheet(
        initial: current,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    final settings = result.settings;
    await notifier.saveSettings(settings);
    if (result.launchSample) {
      setState(() => _tabIndex = 1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lessonsKey.currentState?.runSampleLesson();
      });
    }
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
    final result = await showModalBottomSheet<_ByokSheetResult>(
      context: context,
      showDragHandle: true,
      builder: (context) => _ByokSheet(initial: current),
    );
    if (!mounted || result == null) {
      return;
    }
    if (result.openOnboarding) {
      await _showOnboarding();
      return;
    }
    final settings = result.settings;
    if (settings == null) {
      return;
    }
    await notifier.saveSettings(settings);
  }

  @override
  void dispose() {
    _byokSubscription.close();
    super.dispose();
  }
}

class _ByokSheetResult {
  const _ByokSheetResult.settings(this.settings) : openOnboarding = false;

  const _ByokSheetResult.openOnboarding()
      : settings = null,
        openOnboarding = true;

  final ByokSettings? settings;
  final bool openOnboarding;
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
  String? _selectedLessonModel;
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
    _selectedLessonModel = _matchLessonPreset(_lessonModelController.text);
    _keyController.addListener(_onChanged);
    _lessonModelController.addListener(_handleLessonModelChanged);
    _ttsModelController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _keyController.removeListener(_onChanged);
    _lessonModelController.removeListener(_handleLessonModelChanged);
    _ttsModelController.removeListener(_onChanged);
    _keyController.dispose();
    _lessonModelController.dispose();
    _ttsModelController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _handleLessonModelChanged() {
    final preset = _matchLessonPreset(_lessonModelController.text);
    setState(() {
      _selectedLessonModel = preset;
    });
  }

  String? _matchLessonPreset(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    for (final preset in _kLessonModelPresets) {
      if (preset.value == trimmed) {
        return preset.value;
      }
    }
    return null;
  }

  void _applyLessonPreset(_ModelPreset preset) {
    if (_lessonModelController.text.trim() == preset.value) {
      return;
    }
    _lessonModelController.text = preset.value;
  }

  void _clearLessonPreset() {
    if (_lessonModelController.text.isEmpty) {
      return;
    }
    _lessonModelController.clear();
  }

  String _normalizeProvider(String raw) {
    return raw.trim().toLowerCase() == 'openai' ? 'openai' : 'echo';
  }

  void _handleSave() {
    final lessonModel = _lessonModelController.text.trim();
    final ttsModel = _ttsModelController.text.trim();
    final settings = ByokSettings(
      apiKey: _keyController.text.trim(),
      lessonProvider: _lessonProvider,
      lessonModel: _lessonProvider == 'echo' || lessonModel.isEmpty
          ? null
          : lessonModel,
      ttsProvider: _ttsProvider,
      ttsModel: ttsModel.isEmpty ? null : ttsModel,
    );
    Navigator.pop(context, _ByokSheetResult.settings(settings));
  }

  void _handleClear() {
    Navigator.pop(context, _ByokSheetResult.settings(const ByokSettings()));
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Bring your own key', style: theme.textTheme.titleMedium),
                TextButton(
                  onPressed: () => Navigator.pop(context, const _ByokSheetResult.openOnboarding()),
                  child: const Text('Quick start'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey('lesson_provider_$_lessonProvider'),
                    initialValue: _lessonProvider,
                    decoration: const InputDecoration(
                      labelText: 'Lesson provider',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'echo',
                        child: Text('Echo (offline)'),
                      ),
                      DropdownMenuItem(
                        value: 'openai',
                        child: Text('OpenAI (BYOK)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _lessonProvider = value;
                        if (_lessonProvider == 'echo') {
                          _lessonModelController.clear();
                          _selectedLessonModel = null;
                        } else {
                          _selectedLessonModel = _matchLessonPreset(
                            _lessonModelController.text,
                          );
                        }
                      });
                    },
                  ),
                  if (_lessonProvider == 'openai') ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Server default'),
                          selected: _lessonModelController.text.trim().isEmpty,
                          onSelected: (selected) {
                            if (!selected) return;
                            _clearLessonPreset();
                          },
                        ),
                        for (final preset in _kLessonModelPresets)
                          ChoiceChip(
                            label: Text(preset.label),
                            selected: _selectedLessonModel == preset.value,
                            onSelected: (selected) {
                              if (!selected) {
                                _clearLessonPreset();
                                return;
                              }
                              _applyLessonPreset(preset);
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lessonModelController,
                    decoration: const InputDecoration(
                      labelText: 'Lesson model',
                      hintText: 'gpt-5-mini',
                    ),
                    enabled: _lessonProvider == 'openai',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Surface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    key: ValueKey('tts_provider_$_ttsProvider'),
                    initialValue: _ttsProvider,
                    decoration: const InputDecoration(
                      labelText: 'TTS provider',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'echo',
                        child: Text('Echo (offline)'),
                      ),
                      DropdownMenuItem(
                        value: 'openai',
                        child: Text('OpenAI (BYOK)'),
                      ),
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
                ],
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
class _OnboardingResult {
  const _OnboardingResult({required this.settings, required this.launchSample});

  final ByokSettings settings;
  final bool launchSample;
}

class _OnboardingSheet extends StatefulWidget {
  const _OnboardingSheet({required this.initial});

  final ByokSettings initial;

  @override
  State<_OnboardingSheet> createState() => _OnboardingSheetState();
}

class _OnboardingSheetState extends State<_OnboardingSheet> {
  late final TextEditingController _keyController;
  late final TextEditingController _modelController;
  late String _lessonProvider;
  String? _selectedPreset;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _keyController = TextEditingController(text: initial.apiKey);
    _modelController = TextEditingController(text: initial.lessonModel ?? '');
    _lessonProvider = initial.lessonProvider.trim().isEmpty
        ? 'echo'
        : initial.lessonProvider.trim().toLowerCase();
    _selectedPreset = _matchLessonPreset(_modelController.text);
    _keyController.addListener(_onChanged);
    _modelController.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    _keyController.removeListener(_onChanged);
    _modelController.removeListener(_onModelChanged);
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _onModelChanged() {
    setState(() {
      _selectedPreset = _matchLessonPreset(_modelController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final isOpenAi = _lessonProvider == 'openai';
    final hasKey = _keyController.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + spacing.md,
        left: spacing.md,
        right: spacing.md,
        top: spacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick start', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Surface(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Paste your API key (optional)', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Keys stay on-device. The server only forwards requests you trigger.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'OpenAI API key',
                      helperText: 'Leave blank to stay on the offline echo provider.',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Surface(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('2. Pick a provider & model', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'echo', label: Text('Echo (offline)')),
                      ButtonSegment(value: 'openai', label: Text('OpenAI (BYOK)')),
                    ],
                    selected: <String>{_lessonProvider},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _lessonProvider = selection.first;
                        if (_lessonProvider == 'echo') {
                          _modelController.clear();
                          _selectedPreset = null;
                        }
                      });
                    },
                  ),
                  if (isOpenAi) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: spacing.sm,
                      runSpacing: spacing.xs,
                      children: [
                        for (final preset in _kLessonModelPresets)
                          ChoiceChip(
                            label: Text(preset.label),
                            selected: _selectedPreset == preset.value,
                            onSelected: (selected) {
                              if (selected) {
                                if (_modelController.text.trim() != preset.value) {
                                  _modelController.text = preset.value;
                                }
                              } else {
                                _modelController.clear();
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _modelController,
                      decoration: const InputDecoration(
                        labelText: 'Model (optional)',
                        helperText: 'Defaults to gpt-4o-mini if left empty.',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Surface(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('3. Sample lesson', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Jump straight into a short starter lesson using the offline echo provider.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      final settings = _buildSettings();
                      Navigator.pop(
                        context,
                        _OnboardingResult(settings: settings, launchSample: true),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Try a sample lesson'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final settings = _buildSettings();
                      Navigator.pop(
                        context,
                        _OnboardingResult(settings: settings, launchSample: false),
                      );
                    },
                    child: const Text('Save and continue'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Skip for now'),
                  ),
                ),
              ],
            ),
            if (isOpenAi && !hasKey) ...[
              const SizedBox(height: 12),
              Text(
                'Add your OpenAI key to enable BYOK generation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ByokSettings _buildSettings() {
    final trimmedKey = _keyController.text.trim();
    final trimmedModel = _modelController.text.trim();
    final normalizedProvider = _lessonProvider == 'openai' ? 'openai' : 'echo';
    return ByokSettings(
      apiKey: trimmedKey,
      lessonProvider: normalizedProvider,
      lessonModel: normalizedProvider == 'openai' && trimmedModel.isNotEmpty ? trimmedModel : null,
      ttsProvider: widget.initial.ttsProvider,
      ttsModel: widget.initial.ttsModel,
    );
  }

  String? _matchLessonPreset(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    for (final preset in _kLessonModelPresets) {
      if (preset.value == trimmed) {
        return preset.value;
      }
    }
    return null;
  }
}



class ReaderTab extends frp.ConsumerStatefulWidget {
  const ReaderTab({super.key});

  @override
  ReaderTabState createState() => ReaderTabState();
}

class ReaderTabState extends frp.ConsumerState<ReaderTab> {
  late final TextEditingController _controller;
  bool _includeLsj = true;
  bool _includeSmyth = true;
  late final rp.ProviderSubscription<ReaderIntent?> _intentSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'Îœá¿†Î½Î¹Î½ á¼„ÎµÎ¹Î´Îµ');
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
    _scrollController.dispose();
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
                hintText: 'Îœá¿†Î½Î¹Î½ á¼„ÎµÎ¹Î´Îµ, Î¸ÎµÎ¬â€¦',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Surface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _ReaderToggle(
                    label: 'Include LSJ',
                    value: _includeLsj,
                    onChanged: (value) => setState(() => _includeLsj = value),
                  ),
                  const SizedBox(width: 24),
                  _ReaderToggle(
                    label: 'Include Smyth',
                    value: _includeSmyth,
                    onChanged: (value) => setState(() => _includeSmyth = value),
                  ),
                ],
              ),
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
                          'Paste Iliad 1.1â€“1.10 and tap Analyze to inspect lemma and morphology.',
                    );
                  }
                  return _TokenList(
                    controller: _scrollController,
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
                Text('Lemma: ${token.lemma ?? 'â€”'}'),
                Text('Morphology: ${token.morph ?? 'â€”'}'),
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
                    'Source: Liddellâ€“Scottâ€“Jones (Perseus)',
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
  const _TokenList({
    required this.controller,
    required this.result,
    required this.onTap,
  });

  final ScrollController controller;
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

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: tokens.length,
      itemBuilder: (context, index) {
        final token = tokens[index];
        final lemma = token.lemma?.trim();
        final morph = token.morph?.trim();
        LexiconEntry? match;
        if (lemma != null && lemma.isNotEmpty) {
          match = result.lexicon.firstWhere(
            (entry) => entry.lemma.toLowerCase() == lemma.toLowerCase(),
            orElse: () => const LexiconEntry(lemma: ''),
          );
          if (match.lemma.isEmpty) {
            match = null;
          }
        }
        final gloss = match?.gloss?.trim();

        return Surface(
          margin: EdgeInsets.only(bottom: index == tokens.length - 1 ? 0 : 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onTap(token),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          token.text,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (morph != null && morph.isNotEmpty)
                        _MorphChip(label: morph),
                    ],
                  ),
                  if (lemma != null && lemma.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      lemma,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    gloss != null && gloss.isNotEmpty
                        ? gloss
                        : 'Tap for LSJ and Smyth detail.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.unfold_more,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReaderToggle extends StatelessWidget {
  const _ReaderToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Switch.adaptive(value: value, onChanged: onChanged),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MorphChip extends StatelessWidget {
  const _MorphChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
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
