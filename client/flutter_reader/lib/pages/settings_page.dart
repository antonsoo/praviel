import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;
import '../models/model_registry.dart';
import '../services/byok_controller.dart';
import '../services/lesson_history_store.dart';
import '../services/progress_store.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
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
    final spacing = ReaderTheme.spacingOf(context);
    final themeModeAsync = ref.watch(themeControllerProvider);
    final themeMode = themeModeAsync.value ?? ThemeMode.light;
    final settingsAsync = ref.watch(byokControllerProvider);

    return settingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(height: spacing.md),
              Text('Error loading settings: $err', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
      data: (settings) => ListView(
        padding: EdgeInsets.all(spacing.md),
        children: [
          _SectionHeader(title: 'API Configuration', spacing: spacing),
          Card(
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your API key is stored securely on this device and is only sent with BYOK requests.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: spacing.md),
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
                  SizedBox(height: spacing.md),
                  FilledButton.icon(
                    onPressed: _hasUnsavedApiKey ? _saveApiKey : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Save API Key'),
                  ),
                  SizedBox(height: spacing.lg),
                  _ProviderModelSection(
                    key: ValueKey(
                      'lesson_${settings.lessonProvider}_${settings.lessonModel}',
                    ),
                    title: 'Lesson Generation',
                    provider: settings.lessonProvider,
                    model: settings.lessonModel,
                    onProviderChanged: (provider) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final defaultModel = _getDefaultModelForProvider(
                        provider,
                      );
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
                    spacing: spacing,
                  ),
                  SizedBox(height: spacing.md),
                  _ProviderModelSection(
                    key: ValueKey(
                      'chat_${settings.chatProvider}_${settings.chatModel}',
                    ),
                    title: 'Chat (Conversational AI)',
                    provider: settings.chatProvider,
                    model: settings.chatModel,
                    providers: kChatProviders,
                    onProviderChanged: (provider) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final defaultModel = _getDefaultModelForProvider(
                        provider,
                      );
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
                    spacing: spacing,
                  ),
                  SizedBox(height: spacing.md),
                  _ProviderModelSection(
                    key: ValueKey(
                      'tts_${settings.ttsProvider}_${settings.ttsModel}',
                    ),
                    title: 'Text-to-Speech',
                    provider: settings.ttsProvider,
                    model: settings.ttsModel,
                    onProviderChanged: (provider) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final defaultModel = _getDefaultModelForProvider(
                        provider,
                      );
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
                    spacing: spacing,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing.lg),
          _SectionHeader(title: 'Appearance', spacing: spacing),
          Card(
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
          SizedBox(height: spacing.lg),
          _SectionHeader(title: 'Data', spacing: spacing),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear history'),
                  subtitle: const Text('Delete all lesson history'),
                  onTap: () => _showClearHistoryDialog(context, spacing),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Reset progress'),
                  subtitle: const Text('Clear XP and streak data'),
                  onTap: () => _showResetProgressDialog(context, spacing),
                ),
              ],
            ),
          ),
          SizedBox(height: spacing.lg),
          _SectionHeader(title: 'About', spacing: spacing),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.favorite),
                  title: const Text('Support This Project'),
                  subtitle: const Text('Help keep AncientLanguages free and open'),
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

  String? _getDefaultModelForProvider(String provider) {
    if (provider == 'echo') return null;
    final models = kLessonModelPresets
        .where((m) => m.provider == provider)
        .toList();
    return models.isEmpty ? null : models.first.id;
  }

  String _getProviderLabel(String providerId) {
    final provider = kLessonProviders.firstWhere(
      (p) => p.id == providerId,
      orElse: () => kLessonProviders.first,
    );
    return provider.label;
  }

  Future<void> _showClearHistoryDialog(
    BuildContext context,
    ReaderSpacing spacing,
  ) async {
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

  Future<void> _showResetProgressDialog(
    BuildContext context,
    ReaderSpacing spacing,
  ) async {
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
}

class _ProviderModelSection extends StatefulWidget {
  const _ProviderModelSection({
    super.key,
    required this.title,
    required this.provider,
    required this.model,
    required this.onProviderChanged,
    required this.onModelChanged,
    required this.spacing,
    this.providers = kLessonProviders,
  });

  final String title;
  final String provider;
  final String? model;
  final Function(String) onProviderChanged;
  final Function(String?) onModelChanged;
  final ReaderSpacing spacing;
  final List<LessonProvider> providers;

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
    return kLessonModelPresets
        .where((m) => m.provider == _currentProvider)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentProvider = widget.providers.firstWhere(
      (p) => p.id == _currentProvider,
      orElse: () => widget.providers.first,
    );

    // Validate that current model exists for current provider
    final validatedModel = _validateModel(_currentModel, _currentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: widget.spacing.xs),
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
                    value: _currentProvider,
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
                        setState(() {
                          _currentProvider = value;
                          // Reset model when provider changes
                          _currentModel = _getDefaultModelForProvider(value);
                        });
                        widget.onProviderChanged(value);
                      }
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: widget.spacing.sm),
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
            padding: EdgeInsets.only(top: widget.spacing.xs),
            child: Row(
              children: [
                Icon(Icons.key, size: 16, color: theme.colorScheme.primary),
                SizedBox(width: widget.spacing.xs),
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

  String? _validateModel(String? model, String provider) {
    if (provider == 'echo') return null;
    if (model == null) return _getDefaultModelForProvider(provider);

    // Check if model exists for this provider
    final modelExists = _availableModels.any((m) => m.id == model);
    if (!modelExists) {
      return _getDefaultModelForProvider(provider);
    }
    return model;
  }

  String? _getDefaultModelForProvider(String provider) {
    if (provider == 'echo') return null;
    final models = kLessonModelPresets
        .where((m) => m.provider == provider)
        .toList();
    return models.isEmpty ? null : models.first.id;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.spacing});

  final String title;
  final ReaderSpacing spacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: spacing.sm,
        bottom: spacing.xs,
        top: spacing.xs,
      ),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
