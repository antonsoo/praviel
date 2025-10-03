import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;

import '../app_providers.dart';
import '../localization/strings_lessons_en.dart';
import '../models/lesson.dart';
import '../services/byok_controller.dart';
import '../services/lesson_api.dart';
import '../services/lesson_history_store.dart';
import '../services/lesson_preferences.dart';
import '../services/progress_store.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/byok_onboarding_sheet.dart';
import '../widgets/exercises/alphabet_exercise.dart';
import '../widgets/celebration.dart';
import '../widgets/exercises/cloze_exercise.dart';
import '../widgets/exercises/exercise_control.dart';
import '../widgets/exercises/match_exercise.dart';
import '../widgets/exercises/translate_exercise.dart';
import '../widgets/shimmer.dart';
import '../widgets/surface.dart';

const bool kIntegrationTestMode = bool.fromEnvironment('INTEGRATION_TEST');

class LessonsPage extends frp.ConsumerStatefulWidget {
  const LessonsPage({super.key, required this.api, required this.openReader});

  final LessonApi api;
  final void Function(ClozeTask task) openReader;

  @override
  frp.ConsumerState<LessonsPage> createState() => LessonsPageState();
}

enum _LessonsStatus { idle, loading, ready, error, disabled }

class LessonsPageState extends frp.ConsumerState<LessonsPage> {
  static const _buttonMotion = Duration(milliseconds: 180);

  bool _srcDaily = true;
  bool _srcCanon = true;
  bool _exAlphabet = true;
  bool _exMatch = true;
  bool _exCloze = true;
  bool _exTranslate = true;
  bool _includeAudio = false;
  int _kCanon = 2;
  String _register = 'literary';

  LessonResponse? _lesson;
  int _index = 0;
  _LessonsStatus _status = _LessonsStatus.idle;
  String? _error;
  bool _autogenTriggered = false;
  bool _missingKeyNotified = false;
  String? _fallbackBanner;
  List<bool?> _taskResults = <bool?>[];

  bool _onboardingPrompted = false;
  bool _onboardingDismissed = false;
  bool _onboardingOpen = false;

  final LessonExerciseHandle _exerciseHandle = LessonExerciseHandle();
  final ScrollController _scrollController = ScrollController();
  LessonCheckFeedback? _lastFeedback;
  late final frp.ProviderSubscription<frp.AsyncValue<ByokSettings>>
  _byokSubscription;
  Color? _highlightColor;
  Timer? _highlightTimer;
  final ProgressStore _progressStore = ProgressStore();
  final LessonHistoryStore _historyStore = LessonHistoryStore();
  bool _showCelebration = false;

  Widget _animatedButton({required Key key, required Widget child}) {
    return AnimatedSwitcher(
      duration: _buttonMotion,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (widget, animation) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            child: widget,
          ),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      child: SizedBox(key: key, child: child),
    );
  }

  void _applyQueryOverrides() {
    if (!kIsWeb) {
      return;
    }
    if (kIntegrationTestMode) {
      debugPrint('[smoke] uri: ${Uri.base}');
    }
    final params = Uri.base.queryParameters;

    bool? parseBool(String name) {
      final raw = params[name];
      if (raw == null) {
        return null;
      }
      final normalized = raw.toLowerCase();
      if (normalized == '1' || normalized == 'true' || normalized == 'yes') {
        return true;
      }
      if (normalized == '0' || normalized == 'false' || normalized == 'no') {
        return false;
      }
      return null;
    }

    void applyBool(bool? value, void Function(bool) apply) {
      if (value != null) {
        apply(value);
      }
    }

    final daily = parseBool('daily');
    applyBool(daily, (value) => _srcDaily = value);

    final canon = parseBool('canon');
    applyBool(canon, (value) => _srcCanon = value);

    final alphabet = parseBool('alphabet');
    applyBool(alphabet, (value) => _exAlphabet = value);

    final match = parseBool('match');
    applyBool(match, (value) => _exMatch = value);

    final cloze = parseBool('cloze');
    applyBool(cloze, (value) => _exCloze = value);

    final translate = parseBool('translate');
    applyBool(translate, (value) => _exTranslate = value);

    final audio = parseBool('audio');
    applyBool(audio, (value) => _includeAudio = value);

    final kCanonParam = params['kcanon'];
    if (kCanonParam != null) {
      final parsed = int.tryParse(kCanonParam);
      if (parsed != null && parsed >= 0) {
        _kCanon = parsed;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _applyQueryOverrides();
    _byokSubscription = ref.listenManual<frp.AsyncValue<ByokSettings>>(
      byokControllerProvider,
      (previous, next) {
        final settings = next.asData?.value;
        if (settings != null) {
          _handleByokSettings(settings);
        }
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      // Load register preference
      try {
        final prefs = await ref.read(lessonPreferencesProvider.future);
        if (mounted) {
          setState(() {
            _register = prefs.register;
          });
        }
      } catch (_) {
        // Ignore errors, use default
      }

      final settings = await ref.read(byokControllerProvider.future);
      if (!mounted) {
        return;
      }
      _handleByokSettings(settings);
      _probeEnabled().whenComplete(_maybeAutogen);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
    _byokSubscription.close();
    _exerciseHandle.detach();
    super.dispose();
  }

  Future<void> _probeEnabled() async {
    setState(() => _status = _LessonsStatus.loading);

    try {
      final flags = await ref.read(featureFlagsProvider.future);
      if (!flags.lessonsEnabled) {
        if (!mounted) return;
        setState(() => _status = _LessonsStatus.disabled);
        return;
      }

      await widget.api.generate(
        const GeneratorParams(
          sources: ['daily'],
          exerciseTypes: ['alphabet'],
          kCanon: 0,
          provider: 'echo',
        ),
        const ByokSettings(),
      );

      if (!mounted) return;
      setState(() => _status = _LessonsStatus.idle);
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = _LessonsStatus.disabled);
    }
  }

  void _maybeAutogen() {
    if (_autogenTriggered || !mounted) {
      return;
    }
    if (_status == _LessonsStatus.disabled) {
      return;
    }
    _autogenTriggered = true;
    _generate();
  }

  void _handleByokSettings(ByokSettings settings) {
    if (_onboardingPrompted || _onboardingDismissed || kIntegrationTestMode) {
      return;
    }
    if (!settings.hasKey) {
      _onboardingPrompted = true;
      _scheduleByokOnboarding();
    }
  }

  void _scheduleByokOnboarding() {
    if (!mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _onboardingOpen) {
        return;
      }
      await _openByokOnboarding();
    });
  }

  Future<void> _openByokOnboarding() async {
    if (!mounted || _onboardingOpen) {
      return;
    }
    setState(() {
      _onboardingOpen = true;
    });
    try {
      final settings = await ref.read(byokControllerProvider.future);
      if (!mounted) {
        return;
      }
      final result = await ByokOnboardingSheet.show(
        context: context,
        initial: settings,
      );
      if (!mounted) {
        return;
      }
      if (result == null) {
        setState(() {
          _onboardingDismissed = true;
        });
        return;
      }
      final controller = ref.read(byokControllerProvider.notifier);
      await controller.saveSettings(result.settings);
      if (!mounted) {
        return;
      }
      setState(() {
        _onboardingDismissed = false;
      });
      if (result.trySample) {
        await _generate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _onboardingOpen = false;
        });
      }
    }
  }

  Future<void> runSampleLesson() async {
    final controller = ref.read(byokControllerProvider.notifier);
    final currentSettings = await ref.read(byokControllerProvider.future);
    final needsOverride =
        currentSettings.lessonProvider != 'echo' ||
        (currentSettings.lessonModel != null &&
            currentSettings.lessonModel!.isNotEmpty);
    if (needsOverride) {
      await controller.saveSettings(
        currentSettings.copyWith(
          lessonProvider: 'echo',
          clearLessonModel: true,
        ),
      );
    }
    setState(() {
      _srcDaily = true;
      _srcCanon = true;
      _exAlphabet = true;
      _exMatch = false;
      _exCloze = true;
      _exTranslate = true;
      _kCanon = 1;
    });
    await _generate();
    if (!mounted) {
      return;
    }
    if (needsOverride) {
      await controller.saveSettings(currentSettings);
    }
  }

  Future<void> _generate() async {
    if (!_canGenerate()) {
      setState(() {
        _status = _LessonsStatus.error;
        _error = 'Pick at least one source and exercise.';
      });
      return;
    }

    final settings = await ref.read(byokControllerProvider.future);
    final provider = settings.lessonProvider.trim().isEmpty
        ? 'echo'
        : settings.lessonProvider.trim();
    if (provider != 'echo' && !settings.hasKey) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(L10nLessons.missingKeySnack),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      setState(() {
        _status = _LessonsStatus.idle;
        _error = null;
      });
      return;
    }

    setState(() {
      _status = _LessonsStatus.loading;
      _error = null;
      _lastFeedback = null;
      _highlightColor = null;
      _fallbackBanner = null;
    });

    try {
      final params = GeneratorParams(
        language: 'grc',
        profile: 'beginner',
        sources: [if (_srcDaily) 'daily', if (_srcCanon) 'canon'],
        exerciseTypes: [
          if (_exAlphabet) 'alphabet',
          if (_exMatch) 'match',
          if (_exCloze) 'cloze',
          if (_exTranslate) 'translate',
        ],
        kCanon: _kCanon,
        provider: provider,
        model: settings.lessonModel,
        register: _register,
      );

      final response = await widget.api.generate(params, settings);
      final fellBack =
          provider != 'echo' && response.meta.provider.toLowerCase() == 'echo';
      final fallbackMessage = _fallbackMessageForNote(response.meta.note);

      if (!mounted) return;
      final tasks = response.tasks;
      setState(() {
        _lesson = tasks.isEmpty ? null : response;
        _taskResults = tasks.isEmpty
            ? <bool?>[]
            : List<bool?>.filled(tasks.length, null, growable: false);
        _index = 0;
        _status = tasks.isEmpty ? _LessonsStatus.error : _LessonsStatus.ready;
        if (tasks.isEmpty) {
          _error = 'Lesson returned no tasks.';
        }
        _fallbackBanner = fellBack ? fallbackMessage : null;
      });

      if (fellBack && fallbackMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(fallbackMessage),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      unawaited(
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _LessonsStatus.error;
        _error = error.toString();
      });
    }
  }

  bool _canGenerate() {
    final hasSource = _srcDaily || _srcCanon;
    final hasExercise = _exAlphabet || _exMatch || _exCloze || _exTranslate;
    return hasSource && hasExercise;
  }

  void _handleCheck() {
    final feedback = _exerciseHandle.check();
    final theme = Theme.of(context);
    _highlightTimer?.cancel();

    Color? highlight;
    if (feedback.correct == true) {
      highlight = theme.colorScheme.successContainer;
      HapticFeedback.lightImpact();
    } else if (feedback.correct == false) {
      highlight = theme.colorScheme.errorContainer;
      HapticFeedback.mediumImpact();
    }

    setState(() {
      _lastFeedback = feedback;
      _highlightColor = highlight;
      if (feedback.correct != null &&
          _lesson != null &&
          _index < _taskResults.length) {
        _taskResults[_index] = feedback.correct;
      }
    });

    if (feedback.correct != null) {
      _highlightTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _highlightColor = null);
      });
    }

    // Track progress when lesson completes
    if (_isLessonComplete) {
      HapticFeedback.heavyImpact();
      setState(() => _showCelebration = true);
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          setState(() => _showCelebration = false);
        }
      });
      _updateProgress();
    }
  }

  Future<void> _updateProgress() async {
    try {
      final lesson = _lesson;
      if (lesson == null) return;

      final progress = await _progressStore.load();
      final correct = _correctTasks;
      final total = lesson.tasks.length;
      final score = correct / total;
      final lessonXP = (score * 100).round();

      progress['xpTotal'] = (progress['xpTotal'] as int? ?? 0) + lessonXP;
      progress['lastLessonAt'] = DateTime.now().toIso8601String();

      // Update streak logic (simplified: +1 if same day or next day)
      final lastAt = progress['lastLessonAt'] as String?;
      if (lastAt != null) {
        final lastDate = DateTime.parse(lastAt);
        final now = DateTime.now();
        final daysDiff = now.difference(lastDate).inDays;
        if (daysDiff <= 1) {
          progress['streakDays'] = (progress['streakDays'] as int? ?? 0) + 1;
        } else {
          progress['streakDays'] = 1;
        }
      } else {
        progress['streakDays'] = 1;
      }

      await _progressStore.save(progress);

      // Save lesson history
      String textSnippet = 'Lesson ${lesson.meta.profile}';
      if (lesson.tasks.isNotEmpty) {
        final firstTask = lesson.tasks.first;
        if (firstTask is ClozeTask) {
          textSnippet = firstTask.text;
        } else if (firstTask is TranslateTask) {
          textSnippet = firstTask.text;
        } else if (firstTask is AlphabetTask) {
          textSnippet = firstTask.prompt;
        }
      }

      final historyEntry = LessonHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        textSnippet: textSnippet.length > 60
            ? '${textSnippet.substring(0, 57)}...'
            : textSnippet,
        totalTasks: total,
        correctCount: correct,
        score: score,
      );

      await _historyStore.add(historyEntry);

      // Dev export
      if (kDebugMode) {
        debugPrint('[ProgressStore] Updated: $progress');
      }
    } catch (error) {
      debugPrint('[ProgressStore] Error updating progress: $error');
    }
  }

  void _handleNext() {
    if (_lesson == null) {
      return;
    }
    if (_index >= _lesson!.tasks.length - 1) {
      return;
    }
    if (_index < _taskResults.length && _taskResults[_index] == null) {
      _taskResults[_index] = false;
    }
    _exerciseHandle.reset();
    _highlightTimer?.cancel();
    setState(() {
      _index++;
      _lastFeedback = null;
      _highlightColor = null;
    });
    unawaited(
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _LessonsStatus.disabled) {
      return Center(child: Text(L10nLessons.disabled));
    }

    final showProgress = _status == _LessonsStatus.loading;
    final bindings = <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.enter): _onEnterShortcut,
      const SingleActivator(LogicalKeyboardKey.keyN): _onNextShortcut,
    };

    return CallbackShortcuts(
      bindings: bindings,
      child: Stack(
        children: [
          FocusTraversalGroup(
            child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showProgress
                  ? const LinearProgressIndicator(minHeight: 3)
                  : const SizedBox(height: 3),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  HapticFeedback.selectionClick();
                  await _generate();
                },
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(child: _buildGenerator(context)),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: _buildBody(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
          ),
          if (_showCelebration)
            Positioned.fill(
              child: IgnorePointer(
                child: CelebrationOverlay(
                  onComplete: () {},
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerator(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final flagsAsync = ref.watch(featureFlagsProvider);
    final ttsSupported = flagsAsync.maybeWhen(
      data: (flags) => flags.ttsEnabled,
      orElse: () => false,
    );
    final settingsAsync = ref.watch(byokControllerProvider);
    final settings = settingsAsync.value ?? const ByokSettings();
    final trimmedProvider = settings.lessonProvider.trim();
    final provider = trimmedProvider.isEmpty
        ? 'echo'
        : trimmedProvider.toLowerCase();
    final missingKey = provider != 'echo' && !settings.hasKey;
    final isLoading = _status == _LessonsStatus.loading;
    final disableGenerate = isLoading || missingKey;

    if (missingKey &&
        !_missingKeyNotified &&
        settingsAsync is frp.AsyncData<ByokSettings>) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(L10nLessons.missingKeySnack),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() => _missingKeyNotified = true);
      });
    } else if (!missingKey && _missingKeyNotified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _missingKeyNotified = false);
      });
    }

    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.source,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(width: spacing.sm),
              Text(
                'Sources',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: [
              FilterChip(
                label: const Text('Daily'),
                selected: _srcDaily,
                onSelected: (value) => setState(() => _srcDaily = value),
              ),
              FilterChip(
                label: const Text('Canonical'),
                selected: _srcCanon,
                onSelected: (value) => setState(() => _srcCanon = value),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${L10nLessons.canonical}: $_kCanon',
                      style: theme.textTheme.bodyMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: _kCanon > 0
                          ? () => setState(() => _kCanon--)
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _kCanon++),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 20,
                  color: theme.colorScheme.secondary,
                ),
              ),
              SizedBox(width: spacing.sm),
              Text(
                'Exercises',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Wrap(
            spacing: spacing.xs,
            runSpacing: spacing.xs,
            children: [
              FilterChip(
                label: const Text('Alphabet'),
                selected: _exAlphabet,
                onSelected: (value) => setState(() => _exAlphabet = value),
              ),
              FilterChip(
                label: const Text('Match'),
                selected: _exMatch,
                onSelected: (value) => setState(() => _exMatch = value),
              ),
              FilterChip(
                label: const Text('Cloze'),
                selected: _exCloze,
                onSelected: (value) => setState(() => _exCloze = value),
              ),
              FilterChip(
                label: const Text('Translate'),
                selected: _exTranslate,
                onSelected: (value) => setState(() => _exTranslate = value),
              ),
            ],
          ),
          if (ttsSupported) ...[
            SizedBox(height: spacing.md),
            SwitchListTile.adaptive(
              value: _includeAudio,
              onChanged: disableGenerate
                  ? null
                  : (value) => setState(() => _includeAudio = value),
              contentPadding: EdgeInsets.zero,
              title: const Text('Include audio'),
              subtitle: Text(
                'Prefetch BYOK/echo audio for daily drills.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
          SizedBox(height: spacing.lg),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.language,
                  size: 20,
                  color: theme.colorScheme.tertiary,
                ),
              ),
              SizedBox(width: spacing.sm),
              Text(
                'Language Style',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'literary',
                label: Text('Literary'),
                icon: Icon(Icons.auto_stories),
              ),
              ButtonSegment(
                value: 'colloquial',
                label: Text('Everyday'),
                icon: Icon(Icons.chat_bubble_outline),
              ),
            ],
            selected: {_register},
            onSelectionChanged: (Set<String> selected) async {
              final newRegister = selected.first;
              setState(() => _register = newRegister);

              // Persist preference
              try {
                await ref
                    .read(lessonPreferencesProvider.notifier)
                    .setRegister(newRegister);
              } catch (_) {
                // Ignore persistence errors
              }
            },
          ),
          SizedBox(height: spacing.lg),
          Divider(color: theme.colorScheme.outlineVariant),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Icon(Icons.vpn_key, color: theme.colorScheme.primary),
              SizedBox(width: spacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson provider: ${settings.lessonProvider.isEmpty ? 'echo' : settings.lessonProvider}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'Lesson model: ${settings.lessonModel ?? 'server default'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TTS provider: ${settings.ttsProvider}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'TTS model: ${settings.ttsModel ?? 'echo:v0'}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: disableGenerate ? null : _generate,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.auto_awesome, size: 24),
              label: Text(
                L10nLessons.generate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(height: spacing.sm),
          Wrap(
            spacing: spacing.sm,
            runSpacing: spacing.xs,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  if (!mounted || _onboardingOpen) {
                    return;
                  }
                  setState(() {
                    _onboardingPrompted = true;
                    _onboardingDismissed = false;
                  });
                  await _openByokOnboarding();
                },
                icon: const Icon(Icons.vpn_key),
                label: const Text('Configure BYOK'),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        await runSampleLesson();
                      },
                child: const Text('Try sample lesson'),
              ),
            ],
          ),
          if (missingKey)
            Padding(
              padding: EdgeInsets.only(top: spacing.xs),
              child: Text(
                'Add your OpenAI key to enable BYOK generation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (_status == _LessonsStatus.error && _error != null)
            Padding(
              padding: EdgeInsets.only(top: spacing.sm),
              child: Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            SizedBox(height: spacing.md),
            Text(
              'Something went wrong',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            SizedBox(height: spacing.sm),
            Text(
              _error ?? 'Failed to generate lesson. Please try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: spacing.lg),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_status) {
      case _LessonsStatus.loading:
        return _buildLoadingShimmer(context);
      case _LessonsStatus.error:
        if (_lesson != null) {
          return _lessonView(context);
        }
        return _buildErrorState(context);
      case _LessonsStatus.ready:
        return _lessonView(context);
      case _LessonsStatus.idle:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10nLessons.emptyTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(L10nLessons.emptyBody),
            ],
          ),
        );
      case _LessonsStatus.disabled:
        return const SizedBox.shrink();
    }
  }

  Widget _lessonView(BuildContext context) {
    final lesson = _lesson;
    if (lesson == null || lesson.tasks.isEmpty) {
      return Center(child: Text(_error ?? L10nLessons.emptyBody));
    }
    final task = lesson.tasks[_index];
    final flagsAsync = ref.watch(featureFlagsProvider);
    final ttsSupported = flagsAsync.maybeWhen(
      data: (flags) => flags.ttsEnabled,
      orElse: () => false,
    );
    final allowAudio = ttsSupported && _includeAudio;

    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final total = lesson.tasks.length;
    final correct = _correctTasks;
    final rawProgress = _lessonProgress;
    final progress = rawProgress.clamp(0.0, 1.0);
    final highlightColor = _highlightColor == null
        ? null
        : Color.lerp(theme.colorScheme.surface, _highlightColor, 0.28);
    final canCheck = _canCheckCurrentTask();
    final canNext = _canGoNext();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        if (_fallbackBanner != null)
          Padding(
            padding: EdgeInsets.only(bottom: spacing.sm),
            child: Surface(
              padding: EdgeInsets.all(spacing.sm),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  SizedBox(width: spacing.xs),
                  Expanded(
                    child: Text(
                      _fallbackBanner!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        Surface(
          backgroundColor: highlightColor,
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Task ${_index + 1} of $total',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  if (total > 0)
                    _buildScoreChip(context, correct: correct, total: total),
                ],
              ),
              SizedBox(height: spacing.sm),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              SizedBox(height: spacing.md),
              _lessonHeader(context, task),
              SizedBox(height: spacing.md),
              _taskView(
                task,
                ttsEnabled: allowAudio && _allowsAudioForTask(task),
              ),
              SizedBox(height: spacing.lg),
              Divider(color: theme.colorScheme.outlineVariant),
              SizedBox(height: spacing.sm),
              Row(
                children: [
                  _animatedButton(
                    key: ValueKey<bool>(canCheck),
                    child: FilledButton(
                      onPressed: canCheck ? _handleCheck : null,
                      child: const Text('Check'),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  _animatedButton(
                    key: ValueKey<String>(
                      'next-$canNext-${_index == lesson.tasks.length - 1}',
                    ),
                    child: OutlinedButton(
                      onPressed: canNext ? _handleNext : null,
                      child: Text(
                        _index == lesson.tasks.length - 1
                            ? L10nLessons.finish
                            : L10nLessons.next,
                      ),
                    ),
                  ),
                ],
              ),
              if (_lastFeedback?.message != null)
                Padding(
                  padding: EdgeInsets.only(top: spacing.xs),
                  child: Text(
                    _lastFeedback!.message!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _lastFeedback!.correct == false
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_isLessonComplete && total > 0)
          Padding(
            padding: EdgeInsets.only(top: spacing.sm),
            child: Surface(
              key: const Key('lesson-summary'),
              padding: EdgeInsets.all(spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    correct == total
                        ? L10nLessons.summaryPerfect
                        : L10nLessons.summaryComplete,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    correct == total
                        ? L10nLessons.summaryAllCorrect
                        : L10nLessons.summaryPartial(correct, total),
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.md),
                  Wrap(
                    spacing: spacing.sm,
                    runSpacing: spacing.xs,
                    children: [
                      FilledButton.icon(
                        onPressed: _status == _LessonsStatus.loading
                            ? null
                            : _generate,
                        icon: const Icon(Icons.refresh),
                        label: const Text(L10nLessons.tryAnother),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canCheckCurrentTask() {
    if (_status == _LessonsStatus.loading) {
      return false;
    }
    return _lesson != null;
  }

  bool _canGoNext() {
    final lesson = _lesson;
    if (lesson == null) {
      return false;
    }
    return _index < lesson.tasks.length - 1;
  }

  bool _isEditingTextField() {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null) {
      return false;
    }
    return focused.context?.widget is EditableText;
  }

  void _onEnterShortcut() {
    if (_isEditingTextField()) {
      return;
    }
    if (_canCheckCurrentTask()) {
      _handleCheck();
    }
  }

  void _onNextShortcut() {
    if (_isEditingTextField()) {
      return;
    }
    if (_canGoNext()) {
      _handleNext();
    }
  }

  int get _completedTasks =>
      _taskResults.where((value) => value != null).length;

  int get _correctTasks => _taskResults.where((value) => value == true).length;

  double get _lessonProgress {
    final total = _lesson?.tasks.length ?? 0;
    if (total == 0) {
      return 0;
    }
    return _completedTasks / total;
  }

  bool get _isLessonComplete {
    final lesson = _lesson;
    if (lesson == null || lesson.tasks.isEmpty) {
      return false;
    }
    return !_taskResults.contains(null) &&
        _taskResults.length == lesson.tasks.length;
  }

  Widget _buildScoreChip(
    BuildContext context, {
    required int correct,
    required int total,
  }) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final labelColor = theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spacing.sm,
        vertical: spacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            L10nLessons.scoreLabel(correct, total),
            style: theme.textTheme.labelMedium?.copyWith(color: labelColor),
          ),
        ],
      ),
    );
  }

  Widget _lessonHeader(BuildContext context, Task task) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);
    final (iconData, title) = switch (task) {
      AlphabetTask _ => (Icons.spellcheck, 'Alphabet drill'),
      MatchTask _ => (Icons.grid_view, 'Match the pairs'),
      ClozeTask _ => (Icons.short_text, 'Cloze exercise'),
      TranslateTask _ => (Icons.translate, 'Translate'),
      _ => (Icons.help_outline, 'Lesson'),
    };

    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(spacing.xs),
            child: Icon(iconData, color: colors.primary),
          ),
        ),
        SizedBox(width: spacing.sm),
        Text(
          title,
          style: typography.uiTitle.copyWith(color: colors.onSurface),
        ),
      ],
    );
  }

  bool _allowsAudioForTask(Task task) {
    if (task is AlphabetTask) {
      return true;
    }
    if (task is MatchTask) {
      return true;
    }
    if (task is ClozeTask) {
      return task.sourceKind != 'canon';
    }
    if (task is TranslateTask) {
      return true;
    }
    return false;
  }

  Widget _taskView(Task task, {required bool ttsEnabled}) {
    if (task is AlphabetTask) {
      return AlphabetExercise(
        task: task,
        ttsEnabled: ttsEnabled,
        handle: _exerciseHandle,
      );
    }

    if (task is MatchTask) {
      return MatchExercise(task: task, handle: _exerciseHandle);
    }

    if (task is ClozeTask) {
      return ClozeExercise(
        task: task,
        onOpenInReader: () => widget.openReader(task),
        ttsEnabled: ttsEnabled,
        handle: _exerciseHandle,
      );
    }

    if (task is TranslateTask) {
      return TranslateExercise(
        task: task,
        ttsEnabled: ttsEnabled,
        handle: _exerciseHandle,
      );
    }

    return const Text('Unsupported task');
  }

  String? _fallbackMessageForNote(String? note) {
    if (note == null) {
      return null;
    }
    switch (note) {
      case 'byok_missing_fell_back_to_echo':
        return L10nLessons.missingKeySnack;
      case 'byok_failed_fell_back_to_echo':
        return L10nLessons.fallbackDowngrade;
      case 'openai_401':
        return _openAiFallback('rejected the key', note);
      case 'openai_403':
        return _openAiFallback('blocked the request', note);
      case 'openai_404_model':
        return _openAiFallback('model not found', note);
      case 'openai_timeout':
        return _openAiFallback('timed out', note);
      case 'openai_network':
        return _openAiFallback('was unreachable', note);
      case 'openai_bad_payload':
        return _openAiFallback('returned malformed data', note);
    }
    const httpPrefix = 'openai_http_';
    if (note.startsWith(httpPrefix)) {
      final suffix = note.substring(httpPrefix.length);
      final httpDetail = int.tryParse(suffix) != null
          ? 'returned HTTP $suffix'
          : 'returned an HTTP error';
      return _openAiFallback(httpDetail, note);
    }
    if (note.startsWith('openai_')) {
      return _openAiFallback('encountered an error', note);
    }
    return L10nLessons.fallbackDowngrade;
  }

  String _openAiFallback(String detail, String code) {
    return 'OpenAI $detail ($code) -- using offline echo.';
  }

  Widget _buildLoadingShimmer(BuildContext context) {
    final spacing = ReaderTheme.spacingOf(context);
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Surface(
            padding: EdgeInsets.all(spacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ShimmerLoading(height: 40, width: 40),
                    SizedBox(width: spacing.sm),
                    ShimmerLoading(height: 24, width: 150),
                  ],
                ),
                SizedBox(height: spacing.lg),
                ShimmerLoading(height: 60, width: double.infinity),
                SizedBox(height: spacing.md),
                ShimmerLoading(height: 60, width: double.infinity),
                SizedBox(height: spacing.md),
                ShimmerLoading(height: 60, width: double.infinity),
                SizedBox(height: spacing.lg),
                Row(
                  children: [
                    ShimmerLoading(height: 42, width: 100),
                    SizedBox(width: spacing.sm),
                    ShimmerLoading(height: 42, width: 100),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.sm),
          Center(
            child: Text(
              'Generating your lesson...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
