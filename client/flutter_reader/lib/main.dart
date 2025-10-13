import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/reader_api.dart';
import 'app_providers.dart';
import 'localization/strings_lessons_en.dart';
import 'models/app_config.dart';
import 'pages/lessons_page.dart';
import 'pages/settings_page.dart';
import 'pages/text_range_picker_page.dart';
import 'pages/pro_chat_page.dart';
import 'pages/pro_history_page.dart';
import 'pages/vibrant_home_page.dart';
import 'pages/vibrant_lessons_page.dart';
import 'pages/vibrant_profile_page.dart';
import 'pages/skill_tree_page.dart';
import 'pages/srs_decks_page.dart';
import 'pages/quests_page.dart';
import 'pages/search_page.dart';
import 'pages/achievements_page.dart';
import 'services/byok_controller.dart';
import 'services/theme_controller.dart';
import 'theme/vibrant_theme.dart';
import 'theme/vibrant_animations.dart';
import 'widgets/byok_onboarding_sheet.dart';
import 'widgets/onboarding/onboarding_flow.dart';
import 'widgets/onboarding/account_prompt_page.dart';
import 'widgets/layout/reader_shell.dart';
import 'widgets/layout/section_header.dart';
import 'widgets/layout/vibrant_background.dart';
import 'widgets/premium_card.dart';
import 'widgets/compact_language_selector.dart';

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
      theme: VibrantTheme.light(), // New vibrant theme!
      darkTheme: VibrantTheme.dark(),
      themeMode: themeModeAsync.value ?? ThemeMode.system,
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

    // Check for first launch and show welcome onboarding
    _checkFirstLaunch();
    if (kIsWeb) {
      final params = Uri.base.queryParameters;
      if (params['tab'] == 'lessons') {
        _tabIndex = 1; // Lessons is now index 1
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
          if (_tabIndex != 2) {
            setState(() => _tabIndex = 2); // Reader is now index 2
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessonApi = ref.watch(lessonApiProvider);
    final tabs = [
      VibrantHomePage(
        onStartLearning: () {
          setState(() => _tabIndex = 1); // Navigate to Lessons (now index 1)
        },
        onViewHistory: () =>
            setState(() => _tabIndex = 4), // Navigate to History
        onViewAchievements: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AchievementsPage()),
          );
        },
        onViewSkillTree: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SkillTreePage()),
          );
        },
        onViewSrsFlashcards: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SrsDecksPage(srsApi: ref.read(srsApiProvider)),
            ),
          );
        },
        onViewQuests: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuestsPage(questsApi: ref.read(questsApiProvider)),
            ),
          );
        },
      ),
      VibrantLessonsPage(api: lessonApi),
      ReaderTab(key: _readerKey),
      const ProChatPage(),
      const ProHistoryPage(),
      const VibrantProfilePage(),
    ];
    final destinations = const [
      ReaderShellDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
      ),
      ReaderShellDestination(
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        label: 'Lessons',
      ),
      ReaderShellDestination(
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
        label: 'Reader',
      ),
      ReaderShellDestination(
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        label: 'Chat',
      ),
      ReaderShellDestination(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history,
        label: 'History',
      ),
      ReaderShellDestination(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: 'Profile',
      ),
    ];
    final titles = [
      'Home',
      L10nLessons.tabTitle,
      'Reader',
      'Chat',
      'History',
      'Profile',
    ];

    return ReaderShell(
      title: titles[_tabIndex],
      actions: [
        const CompactLanguageSelector(),
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search library',
          onPressed: _openSearch,
        ),
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
      destinations: destinations,
      selectedIndex: _tabIndex,
      onDestinationSelected: (index) => setState(() => _tabIndex = index),
      body: IndexedStack(index: _tabIndex, children: tabs),
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
      setState(() => _tabIndex = 1); // Lessons is now index 1
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lessonsKey.currentState?.runSampleLesson();
      });
    }
  }

  Future<void> _checkFirstLaunch() async {
    if (kIntegrationTestMode) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;

    if (!hasSeenWelcome && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showWelcomeOnboarding();
      });
    }
  }

  Future<void> _showWelcomeOnboarding() async {
    if (kIntegrationTestMode) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_welcome', true);

    if (!mounted) return;

    // Show main onboarding flow
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OnboardingFlow(
          onComplete: () async {
            // After onboarding, show account creation prompt
            Navigator.pop(context);

            if (!mounted) return;

            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountPromptPage(
                  onContinueAsGuest: () {
                    Navigator.pop(context);
                  },
                  onAccountCreated: () {
                    Navigator.pop(context);
                  },
                ),
                fullscreenDialog: true,
              ),
            );
          },
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _openSearch() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
    if (!mounted || result == null) {
      return;
    }
    if (result['target'] == 'reader' && result['text'] is String) {
      final intent = ReaderIntent(
        text: result['text'] as String,
        includeLsj: result['includeLsj'] is bool ? result['includeLsj'] as bool : true,
        includeSmyth: result['includeSmyth'] is bool ? result['includeSmyth'] as bool : true,
      );
      ref.read(readerIntentProvider.notifier).set(intent);
      setState(() => _tabIndex = 2);
    }
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
    final colorScheme = theme.colorScheme;

    return VibrantBackground(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VibrantSpacing.lg,
            VibrantSpacing.xl,
            VibrantSpacing.lg,
            VibrantSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PulseCard(
                gradient: VibrantTheme.heroGradient,
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                onTap: _openTextRangePicker,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refine your reading practice',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.sm),
                    Text(
                      'We surface LSJ glosses, Smyth grammar notes, and adaptive hints automatically. Tap to browse curated Homeric passages if you need inspiration.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    Wrap(
                      spacing: VibrantSpacing.sm,
                      runSpacing: VibrantSpacing.sm,
                      children: const [
                        _HeroBadge(
                          icon: Icons.flash_on,
                          label: 'Instant morphology',
                        ),
                        _HeroBadge(
                          icon: Icons.menu_book_outlined,
                          label: 'LSJ crosslinks',
                        ),
                        _HeroBadge(
                          icon: Icons.school_outlined,
                          label: 'Grammar callouts',
                        ),
                      ],
                    ),
                    const SizedBox(height: VibrantSpacing.lg),
                    TextButton.icon(
                      onPressed: _openTextRangePicker,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: VibrantSpacing.lg,
                          vertical: VibrantSpacing.sm,
                        ),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VibrantRadius.lg),
                        ),
                      ),
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('Browse curated passages'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VibrantSpacing.xl),
              SectionHeader(
                title: 'Analyze a passage',
                subtitle:
                    'Paste a paragraph of Classical Greek or load a curated excerpt. Toggle reference materials before running the analysis.',
                icon: Icons.edit_note,
              ),
              const SizedBox(height: VibrantSpacing.md),
              GlassCard(
                padding: const EdgeInsets.all(VibrantSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Hero(
                      tag: 'greek-text-${_controller.text}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: TextField(
                          controller: _controller,
                          minLines: 3,
                          maxLines: 6,
                          style: theme.textTheme.bodyLarge,
                          textInputAction: TextInputAction.newline,
                          decoration: InputDecoration(
                            labelText: 'Greek text',
                            hintText: 'μῆνιν ἄειδε θεά Πηληϊάδεω Ἀχιλῆος',
                            alignLabelWithHint: true,
                            filled: true,
                            fillColor: colorScheme.surface.withValues(
                              alpha: 0.6,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    Wrap(
                      spacing: VibrantSpacing.md,
                      runSpacing: VibrantSpacing.sm,
                      children: [
                        FilterChip(
                          selected: _includeLsj,
                          avatar: const Icon(Icons.book_outlined, size: 18),
                          label: const Text('Include LSJ glosses'),
                          onSelected: (value) =>
                              setState(() => _includeLsj = value),
                        ),
                        FilterChip(
                          selected: _includeSmyth,
                          avatar: const Icon(
                            Icons.library_books_outlined,
                            size: 18,
                          ),
                          label: const Text('Include Smyth grammar'),
                          onSelected: (value) =>
                              setState(() => _includeSmyth = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: VibrantSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: analysis.isLoading ? null : _onAnalyze,
                      icon: analysis.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        analysis.isLoading ? 'Analyzing...' : 'Analyze text',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: VibrantSpacing.md,
                        ),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: VibrantSpacing.md),
                  OutlinedButton.icon(
                    onPressed: analysis.isLoading ? null : _openTextRangePicker,
                    icon: const Icon(Icons.browse_gallery_outlined),
                    label: const Text('Load sample'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: VibrantSpacing.lg,
                        vertical: VibrantSpacing.md - 4,
                      ),
                      textStyle: theme.textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.xl),
              SectionHeader(
                title: 'Analysis results',
                subtitle:
                    'Tap any token to inspect lemmas, LSJ entries, and Smyth anchors.',
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: VibrantSpacing.md),
              Expanded(
                child: AnimatedSwitcher(
                  duration: VibrantDuration.normal,
                  switchInCurve: VibrantCurve.smooth,
                  switchOutCurve: VibrantCurve.smooth,
                  child: analysis.when(
                    data: (result) {
                      if (result == null) {
                        return const _PlaceholderMessage(
                          message:
                              'Paste Iliad 1.1-1.10 and tap Analyze to inspect lemma, morphology, and references.',
                        );
                      }
                      return _TokenList(
                        controller: _scrollController,
                        result: result,
                        onTap: (token) =>
                            _showTokenSheet(context, token, result),
                      );
                    },
                    loading: () => const _LoadingAnalysis(),
                    error: (error, _) => _ErrorMessage(error: error),
                  ),
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

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: VibrantSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingAnalysis extends StatelessWidget {
  const _LoadingAnalysis();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: PulseCard(
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.xl,
          vertical: VibrantSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'Analyzing passage...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
      for (final entry in result.lexicon) entry.lemma.toLowerCase(): entry,
    };

    return ListView.separated(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: VibrantSpacing.xxl),
      itemCount: tokens.length,
      separatorBuilder: (context, _) =>
          const SizedBox(height: VibrantSpacing.md),
      itemBuilder: (context, index) {
        final token = tokens[index];
        final lemma = token.lemma?.trim();
        final morph = token.morph?.trim();

        LexiconEntry? match;
        if (lemma != null && lemma.isNotEmpty) {
          match = lemmaMap[lemma.toLowerCase()];
        }
        final gloss = match?.gloss?.trim();

        return PulseCard(
          onTap: () => onTap(token),
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.all(VibrantSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      token.text,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (morph != null && morph.isNotEmpty)
                    _MorphChip(label: morph),
                ],
              ),
              if (lemma != null && lemma.isNotEmpty) ...[
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  lemma,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: VibrantSpacing.xs),
              Text(
                (gloss != null && gloss.isNotEmpty)
                    ? gloss
                    : 'Tap to open lexicon details and grammar notes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Wrap(
                spacing: VibrantSpacing.sm,
                runSpacing: VibrantSpacing.sm,
                children: [
                  if (match != null)
                    _MetaPill(
                      icon: Icons.menu_book_outlined,
                      label: 'LSJ ${match.lemma}',
                      color: Theme.of(context).colorScheme.primary,
                      background: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                    ),
                  if (result.grammar.isNotEmpty)
                    ...result.grammar
                        .take(2)
                        .map(
                          (topic) => _MetaPill(
                            icon: Icons.school_outlined,
                            label: 'Smyth §${topic.anchor}',
                            color: Theme.of(context).colorScheme.tertiary,
                            background: Theme.of(context)
                                .colorScheme
                                .tertiaryContainer
                                .withValues(alpha: 0.45),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  Icons.unfold_more,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(VibrantRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: VibrantSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.md,
        vertical: VibrantSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(VibrantRadius.md),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondaryContainer.withValues(alpha: 0.75),
            colorScheme.secondaryContainer.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.robotoMono(
          fontSize: 13,
          letterSpacing: 0.5,
          color: colorScheme.secondary,
          fontWeight: FontWeight.w600,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: PulseCard(
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.xl,
          vertical: VibrantSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_outlined, size: 42, color: colorScheme.primary),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: PulseCard(
        color: colorScheme.errorContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.xl,
          vertical: VibrantSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 42, color: colorScheme.error),
            const SizedBox(height: VibrantSpacing.sm),
            Text(
              'Unable to analyze',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: VibrantSpacing.xs),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
