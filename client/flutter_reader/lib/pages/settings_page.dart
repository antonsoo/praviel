import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;
import '../models/model_registry.dart';
import '../models/language.dart';
import '../services/byok_controller.dart';
import '../services/lesson_history_store.dart';
import '../services/progress_store.dart';
import '../services/theme_controller.dart';
import '../services/language_controller.dart';
import '../theme/professional_theme.dart';
import '../theme/vibrant_animations.dart';
import '../widgets/layout/section_header.dart';
import '../widgets/ancient_label.dart';
import 'support_page.dart';

class SettingsPage extends frp.ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  frp.ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends frp.ConsumerState<SettingsPage> {
  late TextEditingController _apiKeyController;
  bool _hideApiKey = true;
  bool _hasUnsavedApiKey = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    // Load initial API key value
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final settings = await ref.read(byokControllerProvider.future);
      if (mounted) {
        _apiKeyController.text = settings.apiKey;
      }
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final currentSettings = await ref.read(byokControllerProvider.future);
    final newSettings = currentSettings.copyWith(
      apiKey: _apiKeyController.text.trim(),
    );
    await ref.read(byokControllerProvider.notifier).saveSettings(newSettings);
    if (mounted) {
      setState(() => _hasUnsavedApiKey = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('API key saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(themeControllerProvider);
    final themeMode = themeModeAsync.value ?? ThemeMode.light;
    final settingsAsync = ref.watch(byokControllerProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(ProSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: ProSpacing.md),
              Text('Error loading settings: $err', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (settings) => ListView(
        padding: const EdgeInsets.all(ProSpacing.md),
        children: [
          PulseCard(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            padding: const EdgeInsets.all(ProSpacing.lg),
            margin: const EdgeInsets.only(bottom: ProSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bring your own key',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: ProSpacing.sm),
                Text(
                  'Add Anthropic, OpenAI, or Google keys to unlock premium providers while keeping requests local to your device.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: ProSpacing.md),
                Wrap(
                  spacing: ProSpacing.sm,
                  runSpacing: ProSpacing.xs,
                  children: [
                    _SettingsBadgeChip(
                      label: settings.apiKey.trim().isEmpty
                          ? 'No key saved yet'
                          : 'Key stored securely',
                    ),
                    const _SettingsBadgeChip(label: 'BYOK requests only'),
                  ],
                ),
              ],
            ),
          ),
          const SectionHeader(
            title: 'API configuration',
            subtitle: 'Manage provider credentials and defaults.',
            icon: Icons.settings_ethernet,
          ),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ProRadius.xl),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(ProSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your API key is stored securely on this device and is only sent with BYOK requests.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: ProSpacing.md),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _hideApiKey,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      helperText:
                          'Used for all AI providers (Anthropic, OpenAI, Google)',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _hideApiKey ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () =>
                            setState(() => _hideApiKey = !_hideApiKey),
                        tooltip: _hideApiKey ? 'Show key' : 'Hide key',
                      ),
                    ),
                    onChanged: (_) => setState(() => _hasUnsavedApiKey = true),
                  ),
                  const SizedBox(height: ProSpacing.md),
                  FilledButton.icon(
                    onPressed: _hasUnsavedApiKey ? _saveApiKey : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Save API Key'),
                  ),
                  const SizedBox(height: ProSpacing.lg),
                  _ProviderModelSection(
                    key: ValueKey(
                      'lesson_${settings.lessonProvider}_${settings.lessonModel}',
                    ),
                    title: 'Lesson Generation',
                    provider: settings.lessonProvider,
                    model: settings.lessonModel,
                    onProviderChanged: (provider, defaultModel) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newSettings = settings.copyWith(
                        lessonProvider: provider,
                        lessonModel: defaultModel,
                        clearLessonModel: defaultModel == null,
                      );
                      await ref
                          .read(byokControllerProvider.notifier)
                          .saveSettings(newSettings);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Lesson provider changed to ${_getProviderLabel(provider)}',
                            ),
                          ),
                        );
                      }
                    },
                    onModelChanged: (model) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newSettings = settings.copyWith(
                        lessonModel: model,
                        clearLessonModel: model == null,
                      );
                      await ref
                          .read(byokControllerProvider.notifier)
                          .saveSettings(newSettings);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Lesson model updated')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: ProSpacing.md),
                  _ProviderModelSection(
                    key: ValueKey(
                      'chat_${settings.chatProvider}_${settings.chatModel}',
                    ),
                    title: 'Chat (Conversational AI)',
                    provider: settings.chatProvider,
                    model: settings.chatModel,
                    providers: kChatProviders,
                    onProviderChanged: (provider, defaultModel) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newSettings = settings.copyWith(
                        chatProvider: provider,
                        chatModel: defaultModel,
                        clearChatModel: defaultModel == null,
                      );
                      await ref
                          .read(byokControllerProvider.notifier)
                          .saveSettings(newSettings);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Chat provider changed to ${_getProviderLabel(provider)}',
                            ),
                          ),
                        );
                      }
                    },
                    onModelChanged: (model) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newSettings = settings.copyWith(
                        chatModel: model,
                        clearChatModel: model == null,
                      );
                      await ref
                          .read(byokControllerProvider.notifier)
                          .saveSettings(newSettings);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Chat model updated')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: ProSpacing.md),
                  _ProviderModelSection(
                    key: ValueKey(
                      'tts_${settings.ttsProvider}_${settings.ttsModel}',
                    ),
                    title: 'Text-to-Speech',
                    provider: settings.ttsProvider,
                    model: settings.ttsModel,
                    providers: kTtsProviders,
                    modelPresets: kTtsModelPresets,
                    onProviderChanged: (provider, defaultModel) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newSettings = settings.copyWith(
                        ttsProvider: provider,
                        ttsModel: defaultModel,
                        clearTtsModel: defaultModel == null,
                      );
                      await ref
                          .read(byokControllerProvider.notifier)
                          .saveSettings(newSettings);
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'TTS provider changed to ${_getProviderLabel(provider)}',
                            ),
                          ),
                        );
                      }
                    },
                    onModelChanged: (model) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final newSettings = settings.copyWith(
                        ttsModel: model,
                        clearTtsModel: model == null,
                      );
                      await ref
                          .read(byokControllerProvider.notifier)
                          .saveSettings(newSettings);
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('TTS model updated')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: ProSpacing.lg),
          const SectionHeader(
            title: 'Learning preferences',
            subtitle: 'Choose which ancient language you want to learn.',
            icon: Icons.language_outlined,
          ),
          _buildLanguageSelector(ref, Theme.of(context)),
          const SizedBox(height: ProSpacing.lg),
          const SectionHeader(
            title: 'Appearance',
            subtitle: 'Switch between light, dark, or auto themes.',
            icon: Icons.palette_outlined,
          ),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ProRadius.xl),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme'),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode, size: 16),
                        label: Text('Light'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode, size: 16),
                        label: Text('Dark'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.brightness_auto, size: 16),
                        label: Text('Auto'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selected) {
                      ref
                          .read(themeControllerProvider.notifier)
                          .setTheme(selected.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ProSpacing.lg),
          const SectionHeader(
            title: 'Data management',
            subtitle: 'Reset history or progress stored on this device.',
            icon: Icons.storage_outlined,
          ),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ProRadius.xl),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear history'),
                  subtitle: const Text('Delete all lesson history'),
                  onTap: () => _showClearHistoryDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reset progress'),
                  subtitle: const Text('Clear XP and streak data'),
                  onTap: () => _showResetProgressDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: ProSpacing.lg),
          const SectionHeader(
            title: 'About',
            subtitle: 'Project details and ways to support the roadmap.',
            icon: Icons.info_outline,
          ),
          Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(ProRadius.xl),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Support This Project'),
                  subtitle: const Text(
                    'Help keep AncientLanguages free and open',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SupportPage()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Open source'),
                  subtitle: const Text('Built with Flutter'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Could open GitHub repo
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderLabel(String providerId) {
    final combinedProviders = [
      ...kLessonProviders,
      ...kChatProviders,
      ...kTtsProviders,
    ];
    final provider = combinedProviders.firstWhere(
      (p) => p.id == providerId,
      orElse: () => combinedProviders.first,
    );
    return provider.label;
  }

  Future<void> _showClearHistoryDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This will permanently delete all lesson history. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await LessonHistoryStore().clear();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('History cleared')));
      }
    }
  }

  Future<void> _showResetProgressDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text(
          'This will reset your XP and streak to zero. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ProgressStore().reset();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Progress reset')));
      }
    }
  }

  Widget _buildLanguageSelector(frp.WidgetRef ref, ThemeData theme) {
    final languageAsync = ref.watch(languageControllerProvider);

    return languageAsync.when(
      data: (currentLanguage) {
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ProRadius.xl),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < AncientLanguage.values.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _buildLanguageTile(
                  ref,
                  theme,
                  AncientLanguage.values[i],
                  currentLanguage,
                ),
              ],
            ],
          ),
        );
      },
      loading: () => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProRadius.xl),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(ProSpacing.xl),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (error, stack) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ProRadius.xl),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.08),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ProSpacing.xl),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 32,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: ProSpacing.sm),
                Text(
                  'Unable to load languages',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    frp.WidgetRef ref,
    ThemeData theme,
    AncientLanguage language,
    AncientLanguage currentLanguage,
  ) {
    final isSelected = language == currentLanguage;

    // Get the LanguageInfo from availableLanguages
    final languageInfo = availableLanguages.firstWhere(
      (lang) => lang.code == language.code,
      orElse: () => availableLanguages.first,
    );

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(ProRadius.sm),
        ),
        alignment: Alignment.center,
        child: Text(
          language.code.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      title: Text(languageInfo.name),
      subtitle: AncientLabel(
        language: languageInfo,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.start,
        showTooltip: false,
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      onTap: () {
        ref.read(languageControllerProvider.notifier).setLanguage(language);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Language changed to ${languageInfo.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

class _SettingsBadgeChip extends StatelessWidget {
  const _SettingsBadgeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProviderModelSection extends StatefulWidget {
  const _ProviderModelSection({
    super.key,
    required this.title,
    required this.provider,
    required this.model,
    required this.onProviderChanged,
    required this.onModelChanged,
    this.providers = kLessonProviders,
    this.modelPresets = kLessonModelPresets,
  });

  final String title;
  final String provider;
  final String? model;
  final Function(String, String?) onProviderChanged;
  final Function(String?) onModelChanged;
  final List<LessonProvider> providers;
  final List<LessonModelPreset> modelPresets;

  @override
  State<_ProviderModelSection> createState() => _ProviderModelSectionState();
}

class _ProviderModelSectionState extends State<_ProviderModelSection> {
  late String _currentProvider;
  late String? _currentModel;

  @override
  void initState() {
    super.initState();
    _currentProvider = widget.provider;
    _currentModel = widget.model;

    // Auto-correct invalid providers and models after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // First validate the provider
      final validatedProvider = _validateProvider(_currentProvider);
      final providerChanged = validatedProvider != _currentProvider;

      // Then validate the model (using the validated provider)
      final validatedModel = _validateModel(_currentModel, validatedProvider);
      final modelChanged = validatedModel != _currentModel;

      if (providerChanged || modelChanged) {
        // Provider or model was invalid, auto-save the corrected ones
        setState(() {
          _currentProvider = validatedProvider;
          _currentModel = validatedModel;
        });

        if (providerChanged) {
          // If provider changed, call onProviderChanged which also updates the model
          widget.onProviderChanged(validatedProvider, validatedModel);
        } else if (modelChanged) {
          // Only model changed
          widget.onModelChanged(validatedModel);
        }
      }
    });
  }

  @override
  void didUpdateWidget(_ProviderModelSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when widget props change (from parent rebuild)
    if (oldWidget.provider != widget.provider ||
        oldWidget.model != widget.model) {
      setState(() {
        _currentProvider = widget.provider;
        _currentModel = widget.model;
      });
    }
  }

  List<LessonModelPreset> get _availableModels {
    return widget.modelPresets
        .where((m) => m.provider == _currentProvider)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Validate provider and model for safe rendering
    final validatedProvider = _validateProvider(_currentProvider);
    final validatedModel = _validateModel(_currentModel, validatedProvider);

    final currentProvider = widget.providers.firstWhere(
      (p) => p.id == validatedProvider,
      orElse: () => widget.providers.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: ProSpacing.xs),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Provider',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: validatedProvider,
                    isExpanded: true,
                    isDense: true,
                    items: widget.providers.map((p) {
                      return DropdownMenuItem(
                        value: p.id,
                        child: Text(p.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null && value != _currentProvider) {
                        final defaultModel = _getDefaultModelForProvider(value);
                        setState(() {
                          _currentProvider = value;
                          // Reset model when provider changes
                          _currentModel = defaultModel;
                        });
                        widget.onProviderChanged(value, defaultModel);
                      }
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: ProSpacing.sm),
            Expanded(
              flex: 3,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Model',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: validatedModel,
                    isExpanded: true,
                    isDense: true,
                    items:
                        _currentProvider == 'echo' || _availableModels.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Server default'),
                            ),
                          ]
                        : _availableModels.map((m) {
                            return DropdownMenuItem(
                              value: m.id,
                              child: Text(m.label),
                            );
                          }).toList(),
                    onChanged:
                        _currentProvider == 'echo' || _availableModels.isEmpty
                        ? null
                        : (value) {
                            if (value != _currentModel) {
                              setState(() => _currentModel = value);
                              widget.onModelChanged(value);
                            }
                          },
                  ),
                ),
              ),
            ),
          ],
        ),
        if (currentProvider.requiresKey && currentProvider.id != 'echo')
          Padding(
            padding: const EdgeInsets.only(top: ProSpacing.xs),
            child: Row(
              children: [
                Icon(Icons.key, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: ProSpacing.xs),
                Text(
                  'Requires API key configured above',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _validateProvider(String provider) {
    // Check if provider exists in the allowed providers list
    final providerExists = widget.providers.any((p) => p.id == provider);
    if (!providerExists) {
      // Fall back to first provider (usually 'echo')
      return widget.providers.first.id;
    }
    return provider;
  }

  String? _validateModel(String? model, String provider) {
    if (provider == 'echo') return null;
    if (model == null) return _getDefaultModelForProvider(provider);

    // Check if model exists for this provider
    final modelsForProvider = widget.modelPresets
        .where((m) => m.provider == provider)
        .toList();
    final modelExists = modelsForProvider.any((m) => m.id == model);
    if (!modelExists) {
      return _getDefaultModelForProvider(provider);
    }
    return model;
  }

  String? _getDefaultModelForProvider(String provider) {
    if (provider == 'echo') return null;
    final models = widget.modelPresets
        .where((m) => m.provider == provider)
        .toList();
    return models.isEmpty ? null : models.first.id;
  }
}
