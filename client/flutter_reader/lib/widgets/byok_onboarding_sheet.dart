import "package:flutter/material.dart";

import '../../models/model_registry.dart';
import '../../services/byok_controller.dart';
import '../../theme/app_theme.dart';

class ByokOnboardingResult {
  const ByokOnboardingResult({required this.settings, required this.trySample});

  final ByokSettings settings;
  final bool trySample;
}

class ByokOnboardingSheet extends StatefulWidget {
  const ByokOnboardingSheet({super.key, required this.initial});

  static Future<ByokOnboardingResult?> show({
    required BuildContext context,
    required ByokSettings initial,
  }) {
    return showModalBottomSheet<ByokOnboardingResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ByokOnboardingSheet(initial: initial),
    );
  }

  final ByokSettings initial;

  @override
  State<ByokOnboardingSheet> createState() => _ByokOnboardingSheetState();
}

class _ByokOnboardingSheetState extends State<ByokOnboardingSheet> {
  static const String _defaultLessonModelId = 'gpt-5-mini';

  late final TextEditingController _keyController;
  late String _provider;
  late String _modelId;
  bool _hideKey = true;

  ByokSettings get _initial => widget.initial;

  bool get _requiresModel => _provider != 'echo';

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: _initial.apiKey);
    final normalizedProvider = _initial.lessonProvider.trim().isEmpty
        ? 'echo'
        : _initial.lessonProvider.trim();
    _provider = normalizedProvider;
    _modelId = _resolveInitialModel(_initial.lessonModel);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  String _resolveInitialModel(String? candidate) {
    final requested = candidate?.trim();
    if (requested == null || requested.isEmpty) {
      return _defaultLessonModelId;
    }
    final match = kLessonModelPresets.firstWhere(
      (preset) => preset.id == requested,
      orElse: () => kLessonModelPresets.first,
    );
    return match.id;
  }

  void _close({required bool trySample}) {
    final trimmedKey = _keyController.text.trim();
    final provider = _provider;
    final normalized = _initial.copyWith(
      apiKey: trimmedKey,
      lessonProvider: provider,
      lessonModel: _requiresModel ? _modelId : null,
      clearLessonModel: !_requiresModel,
    );
    Navigator.of(
      context,
    ).pop(ByokOnboardingResult(settings: normalized, trySample: trySample));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final spacing = ReaderTheme.spacingOf(context);
    final typography = ReaderTheme.typographyOf(context);

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: colors.surface,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              spacing.lg,
              spacing.lg,
              spacing.lg,
              spacing.lg + spacing.xs,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configure BYOK',
                              style: typography.uiTitle.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            SizedBox(height: spacing.xs),
                            Text(
                              'Provide an API key and choose a model preset for on-demand lessons. Keys stay on device and are sent only for BYOK requests.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Dismiss',
                      ),
                    ],
                  ),
                  SizedBox(height: spacing.lg),
                  Text(
                    'Step 1: API key (optional)',
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: spacing.xs),
                  TextField(
                    controller: _keyController,
                    obscureText: _hideKey,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'OpenAI API key',
                      helperText:
                          'Stored locally only; used for BYOK requests when enabled.',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hideKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _hideKey = !_hideKey),
                        tooltip: _hideKey ? 'Show key' : 'Hide key',
                      ),
                    ),
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: spacing.lg),
                  Text(
                    'Step 2: Choose provider & model',
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: spacing.xs),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'echo',
                        label: Text('Hosted echo'),
                      ),
                      ButtonSegment<String>(
                        value: 'openai',
                        label: Text('OpenAI BYOK'),
                      ),
                    ],
                    selected: {_provider},
                    onSelectionChanged: (values) {
                      final selection = values.first;
                      setState(() {
                        _provider = selection;
                        if (!_requiresModel) {
                          _modelId = _defaultLessonModelId;
                        }
                      });
                    },
                  ),
                  SizedBox(height: spacing.sm),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Lesson model',
                      helperText: _requiresModel
                          ? 'Your selected preset is passed directly to the OpenAI adapter.'
                          : 'Echo runs offline and ignores model presets.',
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _requiresModel
                            ? _modelId
                            : _defaultLessonModelId,
                        isExpanded: true,
                        items: [
                          for (final preset in kLessonModelPresets)
                            DropdownMenuItem<String>(
                              value: preset.id,
                              enabled: _requiresModel,
                              child: Text(preset.label),
                            ),
                        ],
                        onChanged: !_requiresModel
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() => _modelId = value);
                              },
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.lg),
                  Text(
                    'Step 3: Run a sample',
                    style: theme.textTheme.titleSmall,
                  ),
                  SizedBox(height: spacing.xs),
                  Text(
                    'These preferences apply only on this device. Samples let you verify lesson quality before saving.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Wrap(
                    spacing: spacing.sm,
                    runSpacing: spacing.xs,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _close(trySample: true),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Try a sample lesson'),
                      ),
                      OutlinedButton(
                        onPressed: () => _close(trySample: false),
                        child: const Text('Save settings'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Skip for now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
