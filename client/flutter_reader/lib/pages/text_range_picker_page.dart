import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;

import '../app_providers.dart';
import '../models/lesson.dart';
import '../services/byok_controller.dart';
import '../services/lesson_api.dart';
import '../theme/app_theme.dart';
import '../widgets/surface.dart';

class TextRangePickerPage extends frp.ConsumerStatefulWidget {
  const TextRangePickerPage({super.key});

  @override
  frp.ConsumerState<TextRangePickerPage> createState() =>
      _TextRangePickerPageState();
}

class _TextRangePickerPageState extends frp.ConsumerState<TextRangePickerPage> {
  final _textRanges = [
    {
      'title': 'Iliad 1.1-1.10 (Opening)',
      'subtitle': 'μῆνιν ἄειδε θεὰ Πηληϊάδεω Ἀχιλῆος',
      'ref_start': 'Il.1.1',
      'ref_end': 'Il.1.10',
    },
    {
      'title': 'Iliad 1.20-1.50 (Chryses)',
      'subtitle': 'Χρύσην ἀρητῆρα Διὸς',
      'ref_start': 'Il.1.20',
      'ref_end': 'Il.1.50',
    },
    {
      'title': 'Iliad 1.50-1.100 (Apollo\'s Wrath)',
      'subtitle': 'ἔκλαγξαν δ᾽ ἄρ᾽ ὀϊστοὶ',
      'ref_start': 'Il.1.50',
      'ref_end': 'Il.1.100',
    },
    {
      'title': 'Iliad 1.100-1.200 (Assembly)',
      'subtitle': 'ἀγορὴν δὲ καλέσσατο',
      'ref_start': 'Il.1.100',
      'ref_end': 'Il.1.200',
    },
    {
      'title': 'Iliad Book 1 (Complete)',
      'subtitle': '611 lines of epic glory',
      'ref_start': 'Il.1.1',
      'ref_end': 'Il.1.611',
    },
  ];

  bool _isLoading = false;
  String? _error;

  Future<void> _generateFromRange(
    String refStart,
    String refEnd,
    String title,
  ) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final lessonApi = ref.read(lessonApiProvider);
      final settings = await ref.read(byokControllerProvider.future);
      final provider = settings.lessonProvider.trim().isEmpty
          ? 'echo'
          : settings.lessonProvider.trim();

      if (provider != 'echo' && !settings.hasKey) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add your OpenAI key to enable BYOK generation.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final params = GeneratorParams(
        language: 'grc',
        profile: 'beginner',
        sources: const ['canon'],
        exerciseTypes: const ['match', 'cloze', 'translate'],
        kCanon: 0,
        provider: provider,
        model: settings.lessonModel,
        textRange: TextRange(
          refStart: refStart,
          refEnd: refEnd,
        ),
      );

      final response = await lessonApi.generate(params, settings);

      if (!mounted) return;

      if (response.tasks.isEmpty) {
        setState(() {
          _error = 'No tasks generated from selected text range.';
          _isLoading = false;
        });
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _TextRangeLessonPage(
            lesson: response,
            title: title,
            refStart: refStart,
            refEnd: refEnd,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn from Famous Texts'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(spacing.lg),
              children: [
                Surface(
                  padding: EdgeInsets.all(spacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: spacing.md),
                      Text(
                        'Master Vocabulary from Classic Passages',
                        style: theme.textTheme.titleLarge,
                      ),
                      SizedBox(height: spacing.sm),
                      Text(
                        'Choose a passage from Homer\'s Iliad to generate targeted vocabulary lessons.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: spacing.lg),
                if (_error != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.md),
                    child: Surface(
                      backgroundColor: theme.colorScheme.errorContainer,
                      padding: EdgeInsets.all(spacing.md),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: theme.colorScheme.error,
                          ),
                          SizedBox(width: spacing.sm),
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ..._textRanges.map((range) {
                  final title = range['title'] as String;
                  final subtitle = range['subtitle'] as String;
                  final refStart = range['ref_start'] as String;
                  final refEnd = range['ref_end'] as String;

                  return Padding(
                    padding: EdgeInsets.only(bottom: spacing.md),
                    child: Surface(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isLoading
                            ? null
                            : () => _generateFromRange(refStart, refEnd, title),
                        child: Padding(
                          padding: EdgeInsets.all(spacing.lg),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: typography.uiTitle.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    SizedBox(height: spacing.xs),
                                    Text(
                                      subtitle,
                                      style: typography.greekBody.copyWith(
                                        fontSize: 16,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
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
                  );
                }),
              ],
            ),
    );
  }
}

class _TextRangeLessonPage extends StatelessWidget {
  const _TextRangeLessonPage({
    required this.lesson,
    required this.title,
    required this.refStart,
    required this.refEnd,
  });

  final LessonResponse lesson;
  final String title;
  final String refStart;
  final String refEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = ReaderTheme.spacingOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: ListView(
        padding: EdgeInsets.all(spacing.lg),
        children: [
          Surface(
            backgroundColor: theme.colorScheme.primaryContainer,
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: spacing.sm),
                Expanded(
                  child: Text(
                    'Generated from $refStart–$refEnd',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.lg),
          Text(
            'Lesson contains ${lesson.tasks.length} exercises',
            style: theme.textTheme.titleMedium,
          ),
          SizedBox(height: spacing.md),
          Text(
            'This lesson has been generated based on vocabulary from the selected passage. Return to the Lessons tab to practice.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: spacing.lg),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.school),
            label: const Text('Go to Lessons'),
          ),
        ],
      ),
    );
  }
}
