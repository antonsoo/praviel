import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_providers.dart';
import '../localization/strings_lessons_en.dart';

import '../services/byok_controller.dart';

import '../models/lesson.dart';

import '../services/lesson_api.dart';

import '../widgets/exercises/alphabet_exercise.dart';

import '../widgets/exercises/cloze_exercise.dart';

import '../widgets/exercises/match_exercise.dart';

import '../widgets/exercises/translate_exercise.dart';

class LessonsPage extends ConsumerStatefulWidget {
  const LessonsPage({super.key, required this.api, required this.openReader});

  final LessonApi api;

  final void Function(ClozeTask task) openReader;

  @override
  ConsumerState<LessonsPage> createState() => _LessonsPageState();
}

enum _LessonsStatus { idle, loading, ready, error, disabled }

class _LessonsPageState extends ConsumerState<LessonsPage> {
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

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _probeEnabled().whenComplete(_maybeAutogen);
    });
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
      setState(() {
        _status = _LessonsStatus.error;
        _error = L10nLessons.keyNeeded;
      });
      return;
    }

    setState(() {
      _status = _LessonsStatus.loading;
      _error = null;
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
      });
      if (fellBack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Lesson provider unavailable; using offline provider.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
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

  void _next() {
    if (_lesson == null) return;

    if (_index >= _lesson!.tasks.length - 1) {
      return;
    }

    setState(() => _index++);
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _LessonsStatus.disabled) {
      return Center(child: Text(L10nLessons.disabled));
    }

    return Column(
      children: [
        _buildGenerator(context),

        const Divider(height: 1),

        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildGenerator(BuildContext context) {
    final theme = Theme.of(context);
    final settingsAsync = ref.watch(byokControllerProvider);
    final settings = settingsAsync.value ?? const ByokSettings();

    return Padding(
      padding: const EdgeInsets.all(12),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Wrap(
            spacing: 8,

            runSpacing: 8,

            crossAxisAlignment: WrapCrossAlignment.center,

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

              Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(
                    L10nLessons.canonical,

                    style: theme.textTheme.bodyMedium,
                  ),

                  IconButton(
                    icon: const Icon(Icons.remove),

                    onPressed: _kCanon > 0
                        ? () => setState(() => _kCanon--)
                        : null,
                  ),

                  Text('$_kCanon'),

                  IconButton(
                    icon: const Icon(Icons.add),

                    onPressed: () => setState(() => _kCanon++),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,

            runSpacing: 8,

            children: [
              CheckboxMenuButton(
                value: _exAlphabet,

                onChanged: (value) =>
                    setState(() => _exAlphabet = value ?? _exAlphabet),

                child: const Text('Alphabet'),
              ),

              CheckboxMenuButton(
                value: _exMatch,

                onChanged: (value) =>
                    setState(() => _exMatch = value ?? _exMatch),

                child: const Text('Match'),
              ),

              CheckboxMenuButton(
                value: _exCloze,

                onChanged: (value) =>
                    setState(() => _exCloze = value ?? _exCloze),

                child: const Text('Cloze'),
              ),

              CheckboxMenuButton(
                value: _exTranslate,

                onChanged: (value) =>
                    setState(() => _exTranslate = value ?? _exTranslate),

                child: const Text('Translate'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lesson provider: ${settings.lessonProvider}',
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
              ElevatedButton(
                onPressed: _status == _LessonsStatus.loading ? null : _generate,
                child: const Text(L10nLessons.generate),
              ),
            ],
          ),

          if (_status == _LessonsStatus.error && _error != null) ...[
            const SizedBox(height: 8),

            Text(
              _error!,

              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
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
          return _lessonView();
        }

        return Center(child: Text(_error ?? 'Error'));

      case _LessonsStatus.ready:
        return _lessonView();

      case _LessonsStatus.disabled:
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
    }
  }

  Widget _lessonView() {
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _taskView(task, ttsEnabled: ttsEnabled)),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text('Task  of '),

              ElevatedButton(
                onPressed: _index == lesson.tasks.length - 1 ? null : _next,

                child: Text(
                  _index == lesson.tasks.length - 1
                      ? L10nLessons.finish
                      : L10nLessons.next,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taskView(Task task, {required bool ttsEnabled}) {
    if (task is AlphabetTask) {
      return AlphabetExercise(task: task);
    }

    if (task is MatchTask) {
      return MatchExercise(task: task);
    }

    if (task is ClozeTask) {
      return ClozeExercise(
        task: task,
        onOpenInReader: () => widget.openReader(task),
        ttsEnabled: ttsEnabled,
      );
    }

    if (task is TranslateTask) {
      return TranslateExercise(task: task, ttsEnabled: ttsEnabled);
    }

    return const Text('Unsupported task');
  }
}
