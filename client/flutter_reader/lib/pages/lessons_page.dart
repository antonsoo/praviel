import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;

import '../app_providers.dart';
import '../localization/strings_lessons_en.dart';
import '../models/lesson.dart';
import '../services/byok_controller.dart';
import '../services/lesson_api.dart';
import '../widgets/exercises/alphabet_exercise.dart';
import '../widgets/exercises/cloze_exercise.dart';
import '../widgets/exercises/exercise_control.dart';
import '../widgets/exercises/match_exercise.dart';
import '../widgets/exercises/translate_exercise.dart';
import '../widgets/surface.dart';

class LessonsPage extends frp.ConsumerStatefulWidget {
  const LessonsPage({super.key, required this.api, required this.openReader});

  final LessonApi api;
  final void Function(ClozeTask task) openReader;

  @override
  frp.ConsumerState<LessonsPage> createState() => _LessonsPageState();
}

enum _LessonsStatus { idle, loading, ready, error, disabled }

class _LessonsPageState extends frp.ConsumerState<LessonsPage> {
  bool _srcDaily = true;
  bool _srcCanon = true;
  bool _exAlphabet = true;
  bool _exMatch = true;
  bool _exCloze = true;
  bool _exTranslate = true;
  int _kCanon = 2;

  LessonResponse? _lesson;
  int _index = 0;
  _LessonsStatus _status = _LessonsStatus.idle;
  String? _error;
  bool _autogenTriggered = false;
  bool _missingKeyNotified = false;
  String? _fallbackBanner;

  final LessonExerciseHandle _exerciseHandle = LessonExerciseHandle();
  final ScrollController _scrollController = ScrollController();
  LessonCheckFeedback? _lastFeedback;
  Color? _highlightColor;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _probeEnabled().whenComplete(_maybeAutogen);
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollController.dispose();
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
    if (_autogenTriggered || !kDebugMode || !kIsWeb || !mounted) {
      return;
    }
    if (_status == _LessonsStatus.disabled) {
      return;
    }
    if (Uri.base.queryParameters['autogen'] != '1') {
      return;
    }
    _autogenTriggered = true;
    _generate();
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
      );

      final response = await widget.api.generate(params, settings);
      final fellBack =
          provider != 'echo' && response.meta.provider.toLowerCase() == 'echo';
      final fallbackMessage = _fallbackMessageForNote(response.meta.note);

      if (!mounted) return;
      setState(() {
        _lesson = response.tasks.isEmpty ? null : response;
        _index = 0;
        _status = response.tasks.isEmpty
            ? _LessonsStatus.error
            : _LessonsStatus.ready;
        if (response.tasks.isEmpty) {
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
      highlight = theme.colorScheme.primaryContainer;
    } else if (feedback.correct == false) {
      highlight = theme.colorScheme.errorContainer;
    }

    setState(() {
      _lastFeedback = feedback;
      _highlightColor = highlight;
    });

    if (feedback.correct != null) {
      _highlightTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _highlightColor = null);
      });
    }
  }

  void _handleNext() {
    if (_lesson == null) {
      return;
    }
    if (_index >= _lesson!.tasks.length - 1) {
      return;
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

    return Column(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: showProgress
              ? const LinearProgressIndicator(minHeight: 3)
              : const SizedBox(height: 3),
        ),
        Expanded(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildGenerator(context)),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                sliver: SliverFillRemaining(
                  hasScrollBody: true,
                  child: _buildBody(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenerator(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(byokControllerProvider);
    final settings = settingsAsync.value ?? const ByokSettings();
    final trimmedProvider = settings.lessonProvider.trim();
    final provider = trimmedProvider.isEmpty
        ? 'echo'
        : trimmedProvider.toLowerCase();
    final missingKey = provider != 'echo' && !settings.hasKey;
    final disableGenerate = _status == _LessonsStatus.loading || missingKey;

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
          Text('Sources', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 16),
          Text('Exercises', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
          const SizedBox(height: 20),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.vpn_key, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
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
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: disableGenerate ? null : _generate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text(L10nLessons.generate),
              ),
            ],
          ),
          if (missingKey)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Add your OpenAI key to enable BYOK generation.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (_status == _LessonsStatus.error && _error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
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

  Widget _buildBody(BuildContext context) {
    switch (_status) {
      case _LessonsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case _LessonsStatus.error:
        if (_lesson != null) {
          return _lessonView(context);
        }
        return Center(child: Text(_error ?? 'Error generating lesson.'));
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
    final ttsEnabled = flagsAsync.maybeWhen(
      data: (flags) => flags.ttsEnabled,
      orElse: () => false,
    );

    final theme = Theme.of(context);
    final total = lesson.tasks.length;
    final progress = (total == 0) ? 0.0 : (_index + 1) / total;
    final highlightColor = _highlightColor == null
        ? null
        : Color.lerp(theme.colorScheme.surface, _highlightColor, 0.28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_fallbackBanner != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              padding: const EdgeInsets.all(12),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 16),
              _lessonHeader(task, theme),
              const SizedBox(height: 16),
              _taskView(task, ttsEnabled: ttsEnabled),
              const SizedBox(height: 20),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: _status == _LessonsStatus.loading
                        ? null
                        : _handleCheck,
                    child: const Text('Check'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _index == lesson.tasks.length - 1
                        ? null
                        : _handleNext,
                    child: Text(
                      _index == lesson.tasks.length - 1
                          ? L10nLessons.finish
                          : L10nLessons.next,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Task ${_index + 1} of ${lesson.tasks.length}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              if (_lastFeedback?.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
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
      ],
    );
  }

  Widget _lessonHeader(Task task, ThemeData theme) {
    final (iconData, title) = switch (task) {
      AlphabetTask _ => (Icons.spellcheck, 'Alphabet drill'),
      MatchTask _ => (Icons.grid_view, 'Match the pairs'),
      ClozeTask _ => (Icons.short_text, 'Cloze exercise'),
      TranslateTask _ => (Icons.translate, 'Translate'),
      _ => (Icons.help_outline, 'Lesson'),
    };

    return Row(
      children: [
        Icon(iconData, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleLarge),
      ],
    );
  }

  Widget _taskView(Task task, {required bool ttsEnabled}) {
    if (task is AlphabetTask) {
      return AlphabetExercise(task: task, handle: _exerciseHandle);
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
    return 'OpenAI $detail ($code) — using offline echo.';
  }
}
