import "package:flutter/material.dart";

import '../models/model_registry.dart';
import '../services/byok_controller.dart';
import '../theme/professional_theme.dart';
import '../theme/vibrant_animations.dart';
import 'layout/section_header.dart';

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
  late final TextEditingController _keyController;
  late String _provider;
  late String _modelId;
  bool _hideKey = true;

  ByokSettings get _initial => widget.initial;

  LessonProvider get _currentProvider {
    return kLessonProviders.firstWhere(
      (p) => p.id == _provider,
      orElse: () => kLessonProviders.first,
    );
  }

  bool get _requiresKey => _currentProvider.requiresKey;
  bool get _requiresModel => _provider != 'echo';

  List<LessonModelPreset> get _availableModels {
    return kLessonModelPresets
        .where((preset) => preset.provider == _provider)
        .toList();
  }

  String get _defaultModelForProvider {
    final available = _availableModels;
    if (available.isEmpty) {
      return kLessonModelPresets.first.id;
    }
    return available.first.id;
  }

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
      return _defaultModelForProvider;
    }
    final match = kLessonModelPresets.firstWhere(
      (preset) => preset.id == requested && preset.provider == _provider,
      orElse: () => _availableModels.isNotEmpty
          ? _availableModels.first
          : kLessonModelPresets.first,
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
    final colorScheme = theme.colorScheme;

    return AnimatedPadding(
      duration: VibrantDuration.quick,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: colorScheme.surface,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              ProSpacing.xl,
              ProSpacing.xl,
              ProSpacing.xl,
              ProSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeader(
                  title: 'Configure BYOK',
                  subtitle:
                      'Store your key locally and choose defaults for premium providers.',
                  icon: Icons.vpn_key_outlined,
                  dense: true,
                  action: IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Dismiss',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: ProSpacing.lg),
                _buildProviderCard(theme, colorScheme),
                const SizedBox(height: ProSpacing.lg),
                _buildApiKeyCard(theme, colorScheme),
                const SizedBox(height: ProSpacing.lg),
                _buildModelCard(theme, colorScheme),
                const SizedBox(height: ProSpacing.lg),
                _buildActionsCard(theme, colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard(ThemeData theme, ColorScheme colorScheme) {
    return PulseCard(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(ProRadius.xl),
      padding: const EdgeInsets.all(ProSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1 · Choose provider',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ProSpacing.sm),
          Text(
            'Pick which lesson generator should power BYOK lessons.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ProSpacing.md),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Lesson provider',
              helperText: 'Select your AI provider',
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _provider,
                isExpanded: true,
                items: [
                  for (final provider in kLessonProviders)
                    DropdownMenuItem<String>(
                      value: provider.id,
                      child: Text(provider.label),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _provider = value;
                    _modelId = _defaultModelForProvider;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyCard(ThemeData theme, ColorScheme colorScheme) {
    return PulseCard(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(ProRadius.xl),
      padding: const EdgeInsets.all(ProSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2 · API key ${_requiresKey ? "(required)" : "(not needed)"}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ProSpacing.sm),
          Text(
            _requiresKey
                ? 'Keys stay on this device and are sent only with BYOK requests.'
                : 'Echo uses a built-in sandbox so no key is required.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ProSpacing.md),
          TextField(
            controller: _keyController,
            obscureText: _hideKey,
            autocorrect: false,
            enableSuggestions: false,
            enabled: _requiresKey,
            decoration: InputDecoration(
              labelText: '${_currentProvider.label} API key',
              helperText: _requiresKey
                  ? 'Stored locally only; used when contacting ${_currentProvider.label}.'
                  : 'Key entry disabled for echo provider.',
              suffixIcon: _requiresKey
                  ? IconButton(
                      icon: Icon(
                        _hideKey ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _hideKey = !_hideKey),
                      tooltip: _hideKey ? 'Show key' : 'Hide key',
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelCard(ThemeData theme, ColorScheme colorScheme) {
    return PulseCard(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(ProRadius.xl),
      padding: const EdgeInsets.all(ProSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3 · Choose model',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ProSpacing.sm),
          Text(
            _requiresModel
                ? 'Select the default model to request from ${_currentProvider.label}.'
                : 'Echo runs with fixed logic so model selection is skipped.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ProSpacing.md),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Lesson model',
              helperText: _requiresModel
                  ? 'Applied to generated lessons when BYOK is active.'
                  : 'Model selection disabled for echo provider.',
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _modelId,
                isExpanded: true,
                items: [
                  for (final preset in _availableModels)
                    DropdownMenuItem<String>(
                      value: preset.id,
                      enabled: _requiresModel,
                      child: Text(preset.label),
                    ),
                ],
                onChanged: !_requiresModel
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _modelId = value);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(ThemeData theme, ColorScheme colorScheme) {
    final stepLabel = _requiresModel ? 'Step 4' : 'Step 3';

    return PulseCard(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(ProRadius.xl),
      padding: const EdgeInsets.all(ProSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$stepLabel · Save or test',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: ProSpacing.sm),
          Text(
            'These preferences apply only on this device. Try a sample lesson to validate quality before saving.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ProSpacing.md),
          Wrap(
            spacing: ProSpacing.sm,
            runSpacing: ProSpacing.sm,
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
    );
  }
}
