import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;
import '../models/lesson.dart';
import '../services/byok_controller.dart';
import '../services/haptic_service.dart';
import '../services/lesson_api.dart';
import '../theme/professional_theme.dart';
import '../widgets/premium_button.dart';
import '../widgets/premium_snackbars.dart';

/// PROFESSIONAL lessons page - no clutter, maximum clarity
/// Inspired by Apple's design language
class ProLessonsPage extends frp.ConsumerStatefulWidget {
  const ProLessonsPage({super.key, required this.api});

  final LessonApi api;

  @override
  frp.ConsumerState<ProLessonsPage> createState() => _ProLessonsPageState();
}

enum _Status { idle, loading, ready, error }

class _ProLessonsPageState extends frp.ConsumerState<ProLessonsPage> {
  LessonResponse? _lesson;
  int _index = 0;
  _Status _status = _Status.idle;
  String? _error;
  List<bool?> _taskResults = [];

  final bool _srcDaily = true;
  final bool _srcCanon = true;
  final bool _exAlphabet = true;
  final bool _exMatch = false;
  final bool _exCloze = true;
  final bool _exTranslate = true;
  final int _kCanon = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _generate();
    });
  }

  Future<void> _generate() async {
    setState(() {
      _status = _Status.loading;
      _error = null;
    });

    try {
      final settings = await ref.read(byokControllerProvider.future);
      final provider = settings.lessonProvider.trim().isEmpty
          ? 'echo'
          : settings.lessonProvider.trim();

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

      if (!mounted) return;
      final tasks = response.tasks;
      setState(() {
        _lesson = tasks.isEmpty ? null : response;
        _taskResults = tasks.isEmpty
            ? []
            : List<bool?>.filled(tasks.length, null, growable: false);
        _index = 0;
        _status = tasks.isEmpty ? _Status.error : _Status.ready;
        if (tasks.isEmpty) {
          _error = 'No exercises generated. Try different settings.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _error = error.toString();
      });
      PremiumSnackBar.error(
        context,
        message: 'Failed to generate lesson',
        title: 'Error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Text('Lessons', style: theme.textTheme.titleLarge),
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: colorScheme.outline),
        ),
      ),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    switch (_status) {
      case _Status.loading:
        return _buildLoadingState(theme);
      case _Status.error:
        if (_lesson != null) {
          return _buildLessonView(theme, colorScheme);
        }
        return _buildErrorState(theme, colorScheme);
      case _Status.ready:
        return _buildLessonView(theme, colorScheme);
      case _Status.idle:
        return _buildEmptyState(theme, colorScheme);
    }
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: ProSpacing.lg),
          Text(
            'Generating lesson...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: ProSpacing.lg),
            Text(
              'Unable to generate lesson',
              style: theme.textTheme.titleMedium,
            ),
            if (_error != null) ...[
              const SizedBox(height: ProSpacing.md),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: ProSpacing.xl),
            PremiumButton(
              onPressed: () {
                HapticService.medium();
                _generate();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, size: 48, color: colorScheme.primary),
            const SizedBox(height: ProSpacing.lg),
            Text('Ready to learn', style: theme.textTheme.titleMedium),
            const SizedBox(height: ProSpacing.md),
            Text(
              'Generate a lesson to begin',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonView(ThemeData theme, ColorScheme colorScheme) {
    final lesson = _lesson;
    if (lesson == null || lesson.tasks.isEmpty) {
      return _buildErrorState(theme, colorScheme);
    }

    // Bounds check to prevent index out of range
    if (_index < 0 || _index >= lesson.tasks.length) {
      return _buildErrorState(theme, colorScheme);
    }

    final task = lesson.tasks[_index];
    final total = lesson.tasks.length;
    final correct = _taskResults.where((r) => r == true).length;
    final progress = _index / total;

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(ProSpacing.xl),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outline, width: 1),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_index + 1} of $total',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '$correct correct',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ProSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(ProRadius.sm),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Task content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ProSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Task type indicator
                Row(
                  children: [
                    Icon(
                      _getIconForTask(task),
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: ProSpacing.sm),
                    Text(
                      _getTitleForTask(task),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: ProSpacing.xxl),

                // Task content would go here
                Text(
                  'Exercise content placeholder',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(ProSpacing.xl),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              top: BorderSide(color: colorScheme.outline, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Expanded(
                  child: PremiumOutlineButton(
                    onPressed: _status == _Status.loading ? null : () {
                      HapticService.medium();
                      _generate();
                    },
                    child: const Text('New Lesson'),
                  ),
                ),
                const SizedBox(width: ProSpacing.md),
                Expanded(
                  child: PremiumButton(
                    onPressed: () {
                      HapticService.medium();
                      _handleNext();
                    },
                    child: Text(_index == total - 1 ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleNext() {
    final lesson = _lesson;
    if (lesson == null) return;

    if (_index >= lesson.tasks.length - 1) {
      // Show completion
      _generate();
    } else {
      setState(() => _index++);
    }
  }

  IconData _getIconForTask(Task task) {
    if (task is AlphabetTask) return Icons.spellcheck;
    if (task is MatchTask) return Icons.grid_view;
    if (task is ClozeTask) return Icons.text_fields;
    if (task is TranslateTask) return Icons.translate;
    return Icons.help_outline;
  }

  String _getTitleForTask(Task task) {
    if (task is AlphabetTask) return 'Alphabet Drill';
    if (task is MatchTask) return 'Match Pairs';
    if (task is ClozeTask) return 'Fill in the Blank';
    if (task is TranslateTask) return 'Translation';
    return 'Exercise';
  }
}
