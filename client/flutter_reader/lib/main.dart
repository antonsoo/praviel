import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/reader_api.dart';
import 'app_providers.dart';
import 'localization/strings_lessons_en.dart';
import 'models/app_config.dart';
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
import 'pages/achievements_page_enhanced.dart';
import 'pages/text_library_page.dart';
import 'services/byok_controller.dart';
import 'services/theme_controller.dart';
import 'services/music_service.dart';
import 'services/language_preferences.dart';
import 'theme/vibrant_theme.dart';
import 'theme/vibrant_animations.dart';
import 'widgets/byok_onboarding_sheet.dart';
import 'pages/premium_onboarding_2025.dart';
import 'pages/onboarding/auth_choice_screen.dart';
import 'widgets/layout/reader_shell.dart';
import 'widgets/layout/section_header.dart';
import 'widgets/layout/vibrant_background.dart';
import 'widgets/premium_card.dart';
import 'widgets/compact_language_selector.dart';

const bool kIntegrationTestMode = bool.fromEnvironment('INTEGRATION_TEST');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final config = await AppConfig.load();

  // Initialize music service
  await MusicService.instance.initialize();

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

final readerIntentProvider =
    NotifierProvider<_ReaderIntentNotifier, ReaderIntent?>(
      _ReaderIntentNotifier.new,
    );

class ReaderIntent {
  ReaderIntent({
    required this.text,
    this.includeLsj = true,
    this.includeSmyth = true,
    this.language,
  });

  final String text;
  final bool includeLsj;
  final bool includeSmyth;
  final String? language;
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
    required String language,
    required bool includeLsj,
    required bool includeSmyth,
  }) async {
    final query = raw.trim();
    if (query.isEmpty) {
      state = AsyncValue.error('Enter text to analyze.', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final result = await _api.analyze(
        query,
        language: language,
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

class _ReaderHomePageState extends ConsumerState<ReaderHomePage>
    with WidgetsBindingObserver {
  int _tabIndex = 0;
  final GlobalKey<ReaderTabState> _readerKey = GlobalKey<ReaderTabState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
        final readerLanguage = params['reader_lang'];
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
                  language: readerLanguage,
                ),
              );
          if (_tabIndex != 3) {
            setState(() => _tabIndex = 3); // Reader is now index 3
          }
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_triggerProgressSync());
    }
  }

  Future<void> _triggerProgressSync() async {
    try {
      final service = await ref.read(progressServiceProvider.future);
      await service.processPendingQueue(force: true);
    } catch (e) {
      debugPrint('[ReaderHomePage] Failed to process queued progress: $e');
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
            MaterialPageRoute(
              builder: (context) => const AchievementsPageEnhanced(),
            ),
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
      const ProChatPage(),
      ReaderTab(key: _readerKey),
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
        icon: Icons.chat_bubble_outline,
        selectedIcon: Icons.chat_bubble,
        label: 'Chat',
      ),
      ReaderShellDestination(
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
        label: 'Reader',
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
      'Chat',
      'Reader',
      'History',
      'Profile',
    ];
    final tickerAwareTabs = List.generate(
      tabs.length,
      (index) => TickerMode(
        enabled: _tabIndex == index,
        child: tabs[index],
      ),
    );

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
      body: IndexedStack(index: _tabIndex, children: tickerAwareTabs),
    );
  }

  Future<void> _checkFirstLaunch() async {
    if (kIntegrationTestMode) return;

    final prefs = await SharedPreferences.getInstance();
    final hasCompletedOnboarding = prefs.getBool('onboarding_complete') ?? false;

    if (!hasCompletedOnboarding && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showAuthAndOnboarding();
      });
    }
  }

  Future<void> _showAuthAndOnboarding() async {
    if (kIntegrationTestMode) return;

    if (!mounted) return;

    // Show auth choice screen first (signup, login, or guest)
    final shouldShowOnboarding = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthChoiceScreenWithOnboarding(),
        fullscreenDialog: true,
      ),
    );

    if (!mounted) return;

    // If user signed up or chose to see onboarding, show it
    if (shouldShowOnboarding == true) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PremiumOnboarding2025(),
          fullscreenDialog: true,
        ),
      );

      if (!mounted) return;

    }
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
      final language = (result['language'] as String?)?.trim();
      if (language != null && language.isNotEmpty) {
        final currentLanguage = ref.read(selectedLanguageProvider);
        if (language != currentLanguage) {
          await ref
              .read(selectedLanguageProvider.notifier)
              .setLanguage(language);
          if (!mounted) {
            return;
          }
        }
      }
      final intent = ReaderIntent(
        text: result['text'] as String,
        includeLsj: result['includeLsj'] is bool
            ? result['includeLsj'] as bool
            : true,
        includeSmyth: result['includeSmyth'] is bool
            ? result['includeSmyth'] as bool
            : true,
        language: language,
      );
      ref.read(readerIntentProvider.notifier).set(intent);
      setState(() => _tabIndex = 3);
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
    final notifier = ref.read(byokControllerProvider.notifier);
    await notifier.saveSettings(result.settings);
    if (result.trySample) {
      setState(() => _tabIndex = 1); // Lessons tab
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class ReaderTab extends ConsumerStatefulWidget {
  const ReaderTab({super.key});

  @override
  ReaderTabState createState() => ReaderTabState();
}

class _HeroBadgeData {
  const _HeroBadgeData(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _ReaderLanguageProfile {
  const _ReaderLanguageProfile({
    required this.code,
    required this.displayName,
    required this.sampleText,
    required this.inputLabel,
    required this.inputHint,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.badges,
    required this.analysisPlaceholder,
    required this.analysisSubtitle,
    this.lexiconToggleLabel,
    this.lexiconReferenceName,
    this.lexiconSource,
    this.grammarToggleLabel,
    this.grammarReferenceName,
    this.grammarSource,
  });

  final String code;
  final String displayName;
  final String sampleText;
  final String inputLabel;
  final String inputHint;
  final String heroTitle;
  final String heroSubtitle;
  final List<_HeroBadgeData> badges;
  final String analysisPlaceholder;
  final String analysisSubtitle;
  final String? lexiconToggleLabel;
  final String? lexiconReferenceName;
  final String? lexiconSource;
  final String? grammarToggleLabel;
  final String? grammarReferenceName;
  final String? grammarSource;
}

const _ReaderLanguageProfile _defaultReaderProfile = _ReaderLanguageProfile(
  code: 'default',
  displayName: 'your chosen language',
  sampleText: '',
  inputLabel: 'Reader input',
  inputHint: 'Paste a passage to analyze vocabulary and morphology.',
  heroTitle: 'Explore authentic literature',
  heroSubtitle:
      'Paste a passage to receive morphology, vocabulary help, and cross references suited to the text.',
  badges: [
    _HeroBadgeData(Icons.auto_awesome_rounded, 'Smart morphology'),
    _HeroBadgeData(Icons.book_outlined, 'Lexicon lookups'),
  ],
  analysisPlaceholder:
      'Paste a passage to inspect words, lemmas, and helpful notes.',
  analysisSubtitle:
      'Paste a passage to analyze or load a curated excerpt. Toggle reference materials before running the analysis.',
);

const Map<String, _ReaderLanguageProfile> _readerProfiles = {
  'grc-cls': _ReaderLanguageProfile(
    code: 'grc-cls',
    displayName: 'Classical Greek',
    sampleText: 'Μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος.',
    inputLabel: 'Classical Greek text',
    inputHint: 'Paste Homer, Plato, drama, or Attic prose.',
    heroTitle: 'Analyze Classical Greek like a scholar',
    heroSubtitle:
        'LSJ glosses, Smyth grammar anchors, and adaptive hints keep you grounded in Greek syntax.',
    badges: [
      _HeroBadgeData(Icons.menu_book_outlined, 'LSJ crosslinks'),
      _HeroBadgeData(Icons.school_outlined, 'Smyth syntax'),
      _HeroBadgeData(Icons.auto_awesome_rounded, 'Smart morphology'),
    ],
    analysisPlaceholder:
        'Paste Iliad 1.1–1.10 to inspect lemmas, morphology, and Smyth references.',
    analysisSubtitle:
        'Paste Homer, Plato, or Attic prose, or load curated excerpts with LSJ and Smyth support.',
    lexiconToggleLabel: 'Include LSJ entries',
    lexiconReferenceName: 'LSJ',
    lexiconSource: 'Liddell–Scott–Jones (Perseus)',
    grammarToggleLabel: 'Include Smyth grammar',
    grammarReferenceName: 'Smyth',
    grammarSource: 'Smyth, Greek Grammar',
  ),
  'grc-koi': _ReaderLanguageProfile(
    code: 'grc-koi',
    displayName: 'Koine Greek',
    sampleText: 'Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν.',
    inputLabel: 'Koine Greek text',
    inputHint: 'Paste New Testament, Septuagint, or early Christian prose.',
    heroTitle: 'Study Koine passages with confidence',
    heroSubtitle:
        'Rapid morphology, lexical glosses, and contextual hints keep scripture approachable.',
    badges: [
      _HeroBadgeData(Icons.menu_book_outlined, 'Lexicon glosses'),
      _HeroBadgeData(Icons.auto_awesome_rounded, 'Morphology breakdown'),
    ],
    analysisPlaceholder:
        'Paste John 1.1–1.5 or another Koine passage to inspect lemmas and vocabulary.',
    analysisSubtitle:
        'Paste New Testament, Septuagint, or Hellenistic prose and include lexicon notes before analyzing.',
    lexiconToggleLabel: 'Include lexicon notes',
    lexiconReferenceName: 'Lexicon',
    lexiconSource: 'Praviel Koine lexicon',
  ),
  'lat': _ReaderLanguageProfile(
    code: 'lat',
    displayName: 'Classical Latin',
    sampleText: 'Gallia est omnis divisa in partes tres.',
    inputLabel: 'Latin text',
    inputHint: 'Paste Caesar, Cicero, Vergil, or late antique prose.',
    heroTitle: 'Unlock Latin prose and poetry',
    heroSubtitle:
        'Inline morphology and vocabulary glosses guide you through Caesar, Cicero, and beyond.',
    badges: [
      _HeroBadgeData(Icons.manage_search_rounded, 'Morphology lookup'),
      _HeroBadgeData(Icons.brightness_5_outlined, 'Vocabulary hints'),
    ],
    analysisPlaceholder:
        'Paste Aeneid 1.1–1.7 or another passage to inspect morphology and vocabulary.',
    analysisSubtitle:
        'Paste Caesar, Cicero, Vergil, or other Latin passages and toggle glosses before running analysis.',
  ),
  'hbo': _ReaderLanguageProfile(
    code: 'hbo',
    displayName: 'Biblical Hebrew',
    sampleText: 'בְּרֵאשִׁית בָּרָא אֱלֹהִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ.',
    inputLabel: 'Biblical Hebrew text',
    inputHint: 'Paste Torah, Prophets, or Writings in pointed Hebrew.',
    heroTitle: 'Parse Biblical Hebrew with clarity',
    heroSubtitle:
        'Smart segmentation, vocabulary hints, and regex-based roots help you track Biblical forms.',
    badges: [
      _HeroBadgeData(Icons.auto_fix_high_outlined, 'Root detection'),
      _HeroBadgeData(Icons.menu_book_outlined, 'Vocabulary glosses'),
    ],
    analysisPlaceholder:
        'Paste Genesis 1.1–1.3 or another passage to inspect shoresh, morphology, and glosses.',
    analysisSubtitle:
        'Paste Torah, Prophets, or Writings passages to inspect morphology, roots, and vocabulary hints.',
  ),
  'san': _ReaderLanguageProfile(
    code: 'san',
    displayName: 'Classical Sanskrit',
    sampleText: 'धर्मक्षेत्रे कुरुक्षेत्रे समवेता युयुत्सवः।',
    inputLabel: 'Sanskrit text',
    inputHint: 'Paste Bhagavad Gita, Ramayana, or classical poetry.',
    heroTitle: 'Decode Sanskrit verses and prose',
    heroSubtitle:
        'Sandhi resolution, morphological hints, and vocabulary help stay within reach.',
    badges: [
      _HeroBadgeData(Icons.auto_fix_high, 'Sandhi helper'),
      _HeroBadgeData(Icons.menu_book, 'Glossed vocab'),
    ],
    analysisPlaceholder:
        'Paste Bhagavad Gita 1.1–1.3 or another passage to inspect morphology and glosses.',
    analysisSubtitle:
        'Paste Bhagavad Gita, Ramayana, or classical poetry to analyze sandhi, morphology, and vocabulary support.',
  ),
  'lzh': _ReaderLanguageProfile(
    code: 'lzh',
    displayName: 'Classical Chinese',
    sampleText: '子曰：「學而時習之，不亦說乎？」',
    inputLabel: 'Classical Chinese text',
    inputHint: 'Paste Analects, Mencius, or historical prose.',
    heroTitle: 'Illuminate Classical Chinese',
    heroSubtitle:
        'Parallel glosses, segmentation hints, and contextual notes guide you through concise prose.',
    badges: [
      _HeroBadgeData(Icons.segment, 'Segmentation hints'),
      _HeroBadgeData(Icons.menu_book_outlined, 'Gloss notes'),
    ],
    analysisPlaceholder:
        'Paste Analects 1.1 or another passage to explore segmentation and glosses.',
    analysisSubtitle:
        'Paste Analects, Mencius, or historical prose to segment text and surface concise gloss notes.',
  ),
};

class ReaderTabState extends ConsumerState<ReaderTab> {
  late final TextEditingController _controller;
  late String _currentLanguageCode;
  bool _includeLsj = true;
  bool _includeSmyth = true;
  late final ProviderSubscription<ReaderIntent?> _intentSubscription;
  final ScrollController _scrollController = ScrollController();

  _ReaderLanguageProfile get _profile =>
      _readerProfiles[_currentLanguageCode] ?? _defaultReaderProfile;

  @override
  void initState() {
    super.initState();
    _currentLanguageCode = ref.read(selectedLanguageProvider);
    final profile = _profile;
    _controller = TextEditingController(text: profile.sampleText);
    _includeLsj = profile.lexiconToggleLabel != null;
    _includeSmyth = profile.grammarToggleLabel != null;
    _intentSubscription = ref.listenManual<ReaderIntent?>(
      readerIntentProvider,
      (previous, next) {
        if (next == null) {
          return;
        }
        final requestedLanguage = next.language?.trim();
        if (requestedLanguage != null &&
            requestedLanguage.isNotEmpty &&
            requestedLanguage != _currentLanguageCode) {
          unawaited(
            ref
                .read(selectedLanguageProvider.notifier)
                .setLanguage(requestedLanguage),
          );
        }
        _controller.text = next.text;
        setState(() {
          _includeLsj = next.includeLsj;
          _includeSmyth = next.includeSmyth;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _onAnalyze(
              languageOverride: requestedLanguage ?? _currentLanguageCode,
            );
          }
        });
        ref.read(readerIntentProvider.notifier).set(null);
      },
    );

    ref.listen<String>(selectedLanguageProvider, (previous, next) {
      if (next == previous) {
        return;
      }
      final newProfile = _readerProfiles[next] ?? _defaultReaderProfile;
      setState(() {
        final previousProfile = previous == null
            ? null
            : _readerProfiles[previous] ?? _defaultReaderProfile;
        final previousSample = previousProfile?.sampleText ?? '';
        final trimmed = _controller.text.trim();
        _currentLanguageCode = next;
        if (trimmed.isEmpty || trimmed == previousSample) {
          _controller.text = newProfile.sampleText;
        }
        _includeLsj = newProfile.lexiconToggleLabel != null;
        _includeSmyth = newProfile.grammarToggleLabel != null;
      });
    });
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

  void _openTextLibrary() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TextLibraryPage()));
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisControllerProvider);
    final languageCode = ref.watch(selectedLanguageProvider);
    if (languageCode != _currentLanguageCode) {
      _currentLanguageCode = languageCode;
    }
    final profile = _profile;
    final analysisDetails = () {
      final parts = <String>['lemmas and morphology'];
      if (profile.lexiconReferenceName != null) {
        parts.add('${profile.lexiconReferenceName} references');
      }
      if (profile.grammarReferenceName != null) {
        parts.add('${profile.grammarReferenceName} notes');
      }
      final joined = parts.join(', ');
      return 'Tap any token to inspect $joined.';
    }();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return VibrantBackground(
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                VibrantSpacing.lg,
                VibrantSpacing.xl,
                VibrantSpacing.lg,
                VibrantSpacing.lg,
              ),
              sliver: SliverToBoxAdapter(
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
                            profile.heroTitle,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.sm),
                          Text(
                            profile.heroSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: VibrantSpacing.md),
                          Wrap(
                            spacing: VibrantSpacing.sm,
                            runSpacing: VibrantSpacing.sm,
                            children: [
                              for (final badge in profile.badges)
                                _HeroBadge(
                                  icon: badge.icon,
                                  label: badge.label,
                                ),
                            ],
                          ),
                          const SizedBox(height: VibrantSpacing.lg),
                          TextButton.icon(
                            onPressed: _openTextLibrary,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: VibrantSpacing.lg,
                                vertical: VibrantSpacing.sm,
                              ),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.18,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  VibrantRadius.lg,
                                ),
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
                      subtitle: profile.analysisSubtitle,
                      icon: Icons.edit_note,
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    GlassCard(
                      padding: const EdgeInsets.all(VibrantSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag:
                                'reader-text-$_currentLanguageCode-${_controller.text.hashCode}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: TextField(
                                controller: _controller,
                                minLines: 3,
                                maxLines: 6,
                                style: theme.textTheme.bodyLarge,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                  labelText: profile.inputLabel,
                                  hintText: profile.inputHint,
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
                          if (profile.lexiconToggleLabel != null ||
                              profile.grammarToggleLabel != null)
                            Wrap(
                              spacing: VibrantSpacing.md,
                              runSpacing: VibrantSpacing.sm,
                              children: [
                                if (profile.lexiconToggleLabel != null)
                                  FilterChip(
                                    selected: _includeLsj,
                                    avatar: const Icon(
                                      Icons.book_outlined,
                                      size: 18,
                                    ),
                                    label: Text(profile.lexiconToggleLabel!),
                                    onSelected: (value) =>
                                        setState(() => _includeLsj = value),
                                  ),
                                if (profile.grammarToggleLabel != null)
                                  FilterChip(
                                    selected: _includeSmyth,
                                    avatar: const Icon(
                                      Icons.library_books_outlined,
                                      size: 18,
                                    ),
                                    label: Text(profile.grammarToggleLabel!),
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
                            onPressed: analysis.isLoading
                                ? null
                                : () => _onAnalyze(),
                            icon: analysis.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.auto_awesome),
                            label: Text(
                              analysis.isLoading
                                  ? 'Analyzing...'
                                  : 'Analyze text',
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
                          onPressed: analysis.isLoading
                              ? null
                              : _openTextRangePicker,
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
                      subtitle: analysisDetails,
                      icon: Icons.analytics_outlined,
                    ),
                    const SizedBox(height: VibrantSpacing.md),
                    AnimatedSwitcher(
                      duration: VibrantDuration.normal,
                      switchInCurve: VibrantCurve.smooth,
                      switchOutCurve: VibrantCurve.smooth,
                      child: analysis.when(
                        data: (result) {
                          if (result == null) {
                            return _PlaceholderMessage(
                              message: profile.analysisPlaceholder,
                            );
                          }
                          return _TokenList(
                            controller: _scrollController,
                            result: result,
                            profile: profile,
                            onTap: (token) => _showTokenSheet(
                              context,
                              token,
                              result,
                              profile,
                            ),
                          );
                        },
                        loading: () => const _LoadingAnalysis(),
                        error: (error, _) => _ErrorMessage(error: error),
                      ),
                    ),
                    const SizedBox(height: VibrantSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onAnalyze({String? languageOverride}) {
    final language = languageOverride ?? _currentLanguageCode;
    ref
        .read(analysisControllerProvider.notifier)
        .analyze(
          _controller.text,
          language: language,
          includeLsj: _includeLsj,
          includeSmyth: _includeSmyth,
        );
  }

  void _showTokenSheet(
    BuildContext context,
    AnalyzeToken token,
    AnalyzeResult result,
    _ReaderLanguageProfile profile,
  ) {
    final lemma = token.lemma?.trim();
    final lexiconMatches = lemma == null || lemma.isEmpty
        ? const <LexiconEntry>[]
        : result.lexicon
              .where(
                (entry) => entry.lemma.toLowerCase() == lemma.toLowerCase(),
              )
              .toList(growable: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final lexiconTitle =
        profile.lexiconReferenceName ??
        profile.lexiconToggleLabel ??
        'Lexicon notes';
    final grammarTitle =
        profile.grammarReferenceName ??
        profile.grammarToggleLabel ??
        'Grammar notes';
    final lexiconSource = profile.lexiconSource;
    final grammarSource = profile.grammarSource;
    final displayLemma = token.lemma?.trim().isNotEmpty == true
        ? token.lemma!.trim()
        : '—';
    final displayMorph = token.morph?.trim().isNotEmpty == true
        ? token.morph!.trim()
        : '—';

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(token.text, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text('Lemma: $displayLemma'),
                Text('Morphology: $displayMorph'),
                if (lexiconMatches.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(lexiconTitle, style: theme.textTheme.titleMedium),
                  for (final entry in lexiconMatches) ...[
                    const SizedBox(height: 8),
                    if (entry.gloss != null && entry.gloss!.isNotEmpty)
                      Text(entry.gloss!),
                    if (entry.citation != null && entry.citation!.isNotEmpty)
                      Text(
                        entry.citation!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                  ],
                  if (lexiconSource != null && lexiconSource.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Source: $lexiconSource',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
                ],
                if (result.grammar.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(grammarTitle, style: theme.textTheme.titleMedium),
                  for (final topic in result.grammar.take(5)) ...[
                    const SizedBox(height: 8),
                    Text(topic.title),
                    Text(
                      topic.anchor,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                  if (grammarSource != null && grammarSource.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Source: $grammarSource',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                  ],
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
    required this.profile,
    required this.onTap,
  });

  final ScrollController controller;
  final AnalyzeResult result;
  final _ReaderLanguageProfile profile;
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
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
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
        final detailMessage = () {
          final parts = <String>[];
          if (profile.lexiconReferenceName != null) {
            parts.add(profile.lexiconReferenceName!);
          }
          if (profile.grammarReferenceName != null) {
            parts.add(profile.grammarReferenceName!);
          }
          if (parts.isEmpty) {
            return 'Tap to open detailed notes.';
          }
          final joined = parts.join(' & ');
          return 'Tap to open $joined notes.';
        }();

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
                (gloss != null && gloss.isNotEmpty) ? gloss : detailMessage,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: VibrantSpacing.sm),
              Wrap(
                spacing: VibrantSpacing.sm,
                runSpacing: VibrantSpacing.sm,
                children: [
                  if (match != null && profile.lexiconReferenceName != null)
                    _MetaPill(
                      icon: Icons.menu_book_outlined,
                      label: '${profile.lexiconReferenceName} ${match.lemma}',
                      color: Theme.of(context).colorScheme.primary,
                      background: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.35),
                    ),
                  if (result.grammar.isNotEmpty &&
                      profile.grammarReferenceName != null)
                    ...result.grammar
                        .take(5)
                        .map(
                          (topic) => _MetaPill(
                            icon: Icons.school_outlined,
                            label:
                                '${profile.grammarReferenceName} §${topic.anchor}',
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
