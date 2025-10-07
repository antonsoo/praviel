import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'api/reader_api.dart';
import 'app_providers.dart';
import 'localization/strings_lessons_en.dart';
import 'models/app_config.dart';
import 'models/lesson.dart';
import 'pages/lessons_page.dart';
import 'pages/settings_page.dart';
import 'pages/text_range_picker_page.dart';
import 'pages/pro_home_page.dart';
import 'pages/pro_chat_page.dart';
import 'pages/pro_history_page.dart';
import 'pages/profile_page.dart';
import 'services/byok_controller.dart';
import 'services/theme_controller.dart';
import 'theme/app_theme.dart';
import 'theme/professional_theme.dart';
import 'widgets/byok_onboarding_sheet.dart';
import 'widgets/progress_dashboard.dart';
import 'widgets/surface.dart';

const bool kIntegrationTestMode = bool.fromEnvironment('INTEGRATION_TEST');

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
    AsyncNotifierProvider<AnalysisController, AnalyzeResult?>(
      AnalysisController.new,
    );

// Simple notifiers for state management
class _ReaderIntentNotifier extends Notifier<ReaderIntent?> {
  @override
  ReaderIntent? build() => null;

  void set(ReaderIntent? intent) => state = intent;
}

class _OnboardingShownNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool shown) => state = shown;
}

final readerIntentProvider =
    NotifierProvider<_ReaderIntentNotifier, ReaderIntent?>(
      _ReaderIntentNotifier.new,
    );

final onboardingShownProvider =
    NotifierProvider<_OnboardingShownNotifier, bool>(
      _OnboardingShownNotifier.new,
    );

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

class AnalysisController extends AsyncNotifier<AnalyzeResult?> {
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
      state = AsyncValue.error(
        'Provide Greek text to analyze.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final result = await _api.analyze(
        query,
        lsj: includeLsj,
        smyth: includeSmyth,
      );
      state = AsyncValue.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class ReaderApp extends ConsumerWidget {
  const ReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Ancient Languages',
      debugShowCheckedModeBanner: false,
      theme: ProfessionalTheme.light(),
      darkTheme: ProfessionalTheme.dark(),
      themeMode: themeModeAsync.value ?? ThemeMode.light,
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
  final GlobalKey<LessonsPageState> _lessonsKey = GlobalKey<LessonsPageState>();

  late final ProviderSubscription<AsyncValue<ByokSettings>> _byokSubscription;

  @override
  void initState() {
    super.initState();
    if (kIntegrationTestMode) {
      Future(() {
        if (!mounted) {
          return;
        }
        ref.read(onboardingShownProvider.notifier).set(true);
      });
    }
    _byokSubscription = ref.listenManual<AsyncValue<ByokSettings>>(
      byokControllerProvider,
      (previous, next) {
        next.whenOrNull(data: _handleOnboardingMaybe);
      },
    );
    if (kIsWeb) {
      final params = Uri.base.queryParameters;
      if (params['tab'] == 'lessons') {
        _tabIndex = 2; // Updated: Lessons is now index 2
      }
      final readerText = params['reader_text'];
      if (readerText != null && readerText.trim().isNotEmpty) {
        final includeLsj = params['reader_lsj'] != '0';
        final includeSmyth = params['reader_smyth'] != '0';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ref
              .read(readerIntentProvider.notifier)
              .set(
                ReaderIntent(
                  text: readerText,
                  includeLsj: includeLsj,
                  includeSmyth: includeSmyth,
                ),
              );
          if (_tabIndex != 1) {
            setState(() => _tabIndex = 1); // Updated: Reader is now index 1
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonApi = ref.watch(lessonApiProvider);
    final tabs = [
      ProHomePage(
        onStartLearning: () {
          setState(() => _tabIndex = 2); // Navigate to Lessons
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Trigger smart defaults generation (not sample lesson)
            _lessonsKey.currentState?.generateWithSmartDefaults();
          });
        },
        onViewHistory: () =>
            setState(() => _tabIndex = 4), // Navigate to History
      ),
      ReaderTab(key: _readerKey),
      LessonsPage(
        key: _lessonsKey,
        api: lessonApi,
        openReader: _openReaderFromLessons,
      ),
      const ProChatPage(),
      const ProHistoryPage(),
      const ProfilePage(), // New profile tab
    ];
    final titles = ['Home', 'Reader', L10nLessons.tabTitle, 'Chat', 'History', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tabIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _showSettings,
          ),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
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
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
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
    ref.read(onboardingShownProvider.notifier).set(true);
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
    ref.read(onboardingShownProvider.notifier).set(true);
    final initial = await ref.read(byokControllerProvider.future);
    if (!mounted) {
      return;
    }
    final result = await ByokOnboardingSheet.show(
      context: context,
      initial: initial,
    );
    if (!mounted || result == null) {
      return;
    }
    await _applyByokResult(result);
  }

  Future<void> _applyByokResult(ByokOnboardingResult result) async {
    final notifier = ref.read(byokControllerProvider.notifier);
    await notifier.saveSettings(result.settings);
    if (result.trySample) {
      setState(() => _tabIndex = 2); // Updated: Lessons is now index 2
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lessonsKey.currentState?.runSampleLesson();
      });
    }
  }

  void _openReaderFromLessons(ClozeTask task) {
    ref
        .read(readerIntentProvider.notifier)
        .set(
          ReaderIntent(text: task.text, includeLsj: true, includeSmyth: true),
        );
    setState(() => _tabIndex = 1); // Updated: Reader is now index 1
  }

  void _showSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const SettingsPage(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Future<void> _showByokSheet() async {
    final initial = await ref.read(byokControllerProvider.future);
    if (!mounted) {
      return;
    }
    final result = await ByokOnboardingSheet.show(
      context: context,
      initial: initial,
    );
    if (!mounted || result == null) {
      return;
    }
    await _applyByokResult(result);
  }

  @override
  void dispose() {
    _byokSubscription.close();
    super.dispose();
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
  late final ProviderSubscription<ReaderIntent?> _intentSubscription;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: 'Menin aeide');
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
        ref.read(readerIntentProvider.notifier).set(null);
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

  void _openTextRangePicker() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const TextRangePickerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisControllerProvider);
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ProgressDashboard(),
            const SizedBox(height: 12),
            Surface(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _openTextRangePicker,
                child: Padding(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(spacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.menu_book,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                      ),
                      SizedBox(width: spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Learn from Famous Texts',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: spacing.xs),
                            Text(
                              'Master vocabulary from classic passages',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Hero(
              tag: 'greek-text-${_controller.text}',
              child: Material(
                type: MaterialType.transparency,
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 3,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Greek text',
                    hintText: 'Menin aeide, thea',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
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

    // Pre-compute lexicon lookup map for O(1) access instead of O(n) per item
    // This fixes the O(n²) performance issue when rendering large token lists
    final lemmaMap = {
      for (final entry in result.lexicon)
        entry.lemma.toLowerCase(): entry
    };

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: tokens.length,
      itemBuilder: (context, index) {
        final token = tokens[index];
        final lemma = token.lemma?.trim();
        final morph = token.morph?.trim();

        // O(1) lookup instead of O(n) firstWhere
        LexiconEntry? match;
        if (lemma != null && lemma.isNotEmpty) {
          match = lemmaMap[lemma.toLowerCase()];
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (match != null)
                        Chip(
                          label: Text('LSJ: ${match.lemma}'),
                          labelStyle: Theme.of(context).textTheme.labelSmall,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      if (result.grammar.isNotEmpty)
                        for (final topic in result.grammar.take(3))
                          ActionChip(
                            label: Text('Smyth §${topic.anchor}'),
                            labelStyle: Theme.of(context).textTheme.labelSmall,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                            onPressed: () {},
                          ),
                    ],
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
        style: GoogleFonts.robotoMono(fontSize: 13, letterSpacing: 0.5),
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
