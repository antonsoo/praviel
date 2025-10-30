import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as frp;
import '../models/model_registry.dart';
import '../models/language.dart';
import '../services/byok_controller.dart';
import '../services/haptic_service.dart';
import '../services/lesson_history_store.dart';
import '../services/progress_store.dart';
import '../services/theme_controller.dart';
import '../services/language_controller.dart';
import '../services/sound_preferences.dart';
import '../services/sound_service.dart';
import '../services/music_service.dart';
import '../theme/professional_theme.dart';
import '../theme/vibrant_animations.dart';
import '../theme/vibrant_theme.dart';
import '../widgets/layout/section_header.dart';
import '../widgets/ancient_label.dart';
import '../widgets/premium_snackbars.dart';
import '../widgets/premium_micro_interactions.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/glassmorphism_card.dart';
import '../widgets/feedback/bug_report_sheet.dart';
import 'support_page.dart';
import 'script_settings_page.dart';

class SettingsPage extends frp.ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  frp.ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends frp.ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late TextEditingController _apiKeyController;
  bool _hideApiKey = true;
  bool _hasUnsavedApiKey = false;
  final ScrollController _settingsScrollController = ScrollController();
  final FocusNode _apiKeyFocusNode = FocusNode();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
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
    _fadeController.dispose();
    _apiKeyController.dispose();
    _apiKeyFocusNode.dispose();
    _settingsScrollController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    HapticService.medium();
    final currentSettings = await ref.read(byokControllerProvider.future);
    final newSettings = currentSettings.copyWith(
      apiKey: _apiKeyController.text.trim(),
    );
    await ref.read(byokControllerProvider.notifier).saveSettings(newSettings);
    if (mounted) {
      setState(() => _hasUnsavedApiKey = false);
      PremiumSnackBar.success(
        context,
        message: 'API key saved successfully',
        title: 'Success',
      );
    }
  }

  void _focusApiKeyField() {
    HapticService.light();
    if (_settingsScrollController.hasClients) {
      _settingsScrollController.animateTo(
        _settingsScrollController.position.minScrollExtent,
        duration: VibrantDuration.moderate,
        curve: VibrantCurve.smooth,
      );
    }
    Future.delayed(VibrantDuration.fast, () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_apiKeyFocusNode);
      }
    });
  }

  Widget _buildSettingsHero({
    required BuildContext context,
    required ByokSettings settings,
    required ThemeMode themeMode,
  }) {
    final theme = Theme.of(context);
    final hasApiKey = settings.apiKey.trim().isNotEmpty;
    final themeLabel = switch (themeMode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      _ => 'Auto',
    };

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        padding: const EdgeInsets.all(VibrantSpacing.lg),
        decoration: const BoxDecoration(gradient: VibrantTheme.auroraGradient),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings & Preferences',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: VibrantSpacing.xs),
                Text(
                  'Fine-tune your learning environment, providers, and audio experience.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: VibrantSpacing.md),
                Wrap(
                  spacing: VibrantSpacing.sm,
                  runSpacing: VibrantSpacing.sm,
                  children: [
                    _SettingsHeroChip(
                      icon: hasApiKey
                          ? Icons.verified_user_rounded
                          : Icons.vpn_key_rounded,
                      label: hasApiKey
                          ? 'API key connected'
                          : 'Add your AI key',
                    ),
                    _SettingsHeroChip(
                      icon: Icons.palette_rounded,
                      label: 'Theme: $themeLabel',
                    ),
                    _SettingsHeroChip(
                      icon: Icons.library_books_rounded,
                      label: '46 languages available',
                    ),
                  ],
                ),
                const SizedBox(height: VibrantSpacing.lg),
                Wrap(
                  spacing: VibrantSpacing.sm,
                  runSpacing: VibrantSpacing.sm,
                  children: [
                    _SettingsHeroAction(
                      icon: Icons.vpn_key_rounded,
                      label: hasApiKey ? 'Update API key' : 'Add API key',
                      onTap: _focusApiKeyField,
                    ),
                    _SettingsHeroAction(
                      icon: Icons.text_fields_rounded,
                      label: 'Script preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ScriptSettingsPage(),
                          ),
                        );
                      },
                    ),
                    _SettingsHeroAction(
                      icon: Icons.favorite_rounded,
                      label: 'Support roadmap',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupportPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(themeControllerProvider);
    final themeMode = themeModeAsync.value ?? ThemeMode.light;
    final settingsAsync = ref.watch(byokControllerProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: settingsAsync.when(
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
                Text(
                  'Error loading settings: $err',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (settings) => ListView(
          controller: _settingsScrollController,
          padding: const EdgeInsets.fromLTRB(
            VibrantSpacing.lg,
            VibrantSpacing.lg,
            VibrantSpacing.lg,
            VibrantSpacing.xxxl,
          ),
          children: [
            _buildSettingsHero(
              context: context,
              settings: settings,
              themeMode: themeMode,
            ),
            const SizedBox(height: VibrantSpacing.lg),
            const SectionHeader(
              title: 'API configuration',
              subtitle: 'Manage provider credentials and defaults.',
              icon: Icons.settings_ethernet,
            ),
            GlassmorphismCard(
              blur: 18,
              borderRadius: 28,
              opacity: 0.16,
              borderOpacity: 0.22,
              padding: const EdgeInsets.all(VibrantSpacing.lg),
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
                    focusNode: _apiKeyFocusNode,
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
                  ShimmerButton(
                    onPressed: _hasUnsavedApiKey ? _saveApiKey : null,
                    shimmerDuration: const Duration(milliseconds: 1800),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.save, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Save API Key',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
            GlassmorphismCard(
              blur: 18,
              borderRadius: 28,
              opacity: 0.16,
              borderOpacity: 0.22,
              padding: EdgeInsets.zero,
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
              title: 'Script display',
              subtitle: 'Customize how ancient texts are rendered.',
              icon: Icons.text_fields,
            ),
            GlassmorphismCard(
              blur: 18,
              borderRadius: 28,
              opacity: 0.16,
              borderOpacity: 0.22,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Script preferences'),
                    subtitle: const Text('Configure authentic script display'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScriptSettingsPage(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: ProSpacing.lg),
            const SectionHeader(
              title: 'Audio & Music',
              subtitle:
                  'Configure background music, sound effects, and volume.',
              icon: Icons.music_note_outlined,
            ),
            _buildAudioSection(ref, Theme.of(context)),
            const SizedBox(height: ProSpacing.lg),
            const SectionHeader(
              title: 'Data management',
              subtitle: 'Reset history or progress stored on this device.',
              icon: Icons.storage_outlined,
            ),
            GlassmorphismCard(
              blur: 18,
              borderRadius: 28,
              opacity: 0.16,
              borderOpacity: 0.22,
              padding: EdgeInsets.zero,
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
              title: 'Support & feedback',
              subtitle: 'Let us know when something breaks or feels off.',
              icon: Icons.support_agent_outlined,
            ),
            GlassmorphismCard(
              blur: 18,
              borderRadius: 28,
              opacity: 0.16,
              borderOpacity: 0.22,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Report a bug'),
                    subtitle: const Text(
                      'Send a quick note to support@praviel.com',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => BugReportSheet.show(context),
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
            GlassmorphismCard(
              blur: 18,
              borderRadius: 28,
              opacity: 0.16,
              borderOpacity: 0.22,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.favorite),
                    title: const Text('Support This Project'),
                    subtitle: const Text('Help keep PRAVIEL free and open'),
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
                    subtitle: const Text('Alpha Test – Oct 2025'),
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
        ), // ListView closes here (data: case)
      ), // when() closes here
    ); // FadeTransition closes here
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
    final languageCodeAsync = ref.watch(languageControllerProvider);
    final sections = ref.watch(languageMenuSectionsProvider);

    return languageCodeAsync.when(
      data: (currentLanguageCode) {
        final ordered = sections.allOrdered;
        if (ordered.isEmpty) {
          return const SizedBox.shrink();
        }
        final selectable = sections.available;
        final currentLanguage = ordered.firstWhere(
          (lang) => lang.code == currentLanguageCode,
          orElse: () =>
              selectable.isNotEmpty ? selectable.first : ordered.first,
        );
        final quickSwitch = selectable.take(8).toList();

        Future<void> updateLanguage(LanguageInfo language) async {
          await ref
              .read(languageControllerProvider.notifier)
              .setLanguage(language.code);
          if (mounted) {
            PremiumSnackBar.success(
              context,
              message: 'Language changed to ${language.name}',
              title: '${language.flag} Language updated',
              duration: const Duration(seconds: 2),
            );
          }
        }

        Future<void> openPicker() async {
          final selected = await LanguagePickerSheet.show(
            context: context,
            currentLanguageCode: currentLanguageCode,
          );
          if (selected != null && selected.isAvailable) {
            await updateLanguage(selected);
          }
        }

        final status = _languageStatusText(currentLanguage);

        return GlassmorphismCard(
          blur: 18,
          borderRadius: 28,
          opacity: 0.16,
          borderOpacity: 0.22,
          child: Padding(
            padding: const EdgeInsets.all(ProSpacing.lg),
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
                            'Current language',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: ProSpacing.xs),
                          Text(
                            '${currentLanguage.name} (${currentLanguage.code.toUpperCase()})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: ProSpacing.xs),
                          AncientLabel(
                            language: currentLanguage,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.start,
                            showTooltip: false,
                          ),
                          if (status != null) ...[
                            const SizedBox(height: ProSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: theme.colorScheme.secondary,
                                ),
                                const SizedBox(width: ProSpacing.xs),
                                Expanded(
                                  child: Text(
                                    status,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: ProSpacing.md),
                    FilledButton.icon(
                      onPressed: openPicker,
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Change language'),
                    ),
                  ],
                ),
                if (quickSwitch.isNotEmpty) ...[
                  const SizedBox(height: ProSpacing.lg),
                  Text(
                    'Quick switch',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: ProSpacing.sm),
                  Wrap(
                    spacing: ProSpacing.sm,
                    runSpacing: ProSpacing.sm,
                    children: [
                      for (final language in quickSwitch)
                        FilterChip(
                          label: Text(language.name),
                          selected: language.code == currentLanguageCode,
                          onSelected: (_) {
                            if (language.code != currentLanguageCode) {
                              updateLanguage(language);
                            }
                          },
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: ProSpacing.xs),
                Text(
                  'Tap "Change language" to browse the full list of 46 languages in release order.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => GlassmorphismCard(
        blur: 18,
        borderRadius: 28,
        opacity: 0.16,
        borderOpacity: 0.22,
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
      error: (error, stack) => GlassmorphismCard(
        blur: 18,
        borderRadius: 28,
        opacity: 0.16,
        borderOpacity: 0.22,
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

  String? _languageStatusText(LanguageInfo language) {
    if (!language.isAvailable) {
      return language.comingSoon
          ? 'Coming soon — this course will unlock after the public beta.'
          : 'Planned release — follow our roadmap for updates.';
    }
    if (!language.isFullCourse) {
      return 'Partial course — inscription drills and reader support available.';
    }
    return null;
  }

  Widget _buildAudioSection(frp.WidgetRef ref, ThemeData theme) {
    final soundPrefsAsync = ref.watch(soundPreferencesProvider);
    final musicService = MusicService.instance;

    return soundPrefsAsync.when(
      data: (soundPrefs) {
        return ListenableBuilder(
          listenable: musicService,
          builder: (context, _) {
            return GlassmorphismCard(
              blur: 18,
              borderRadius: 28,
              opacity: 0.16,
              borderOpacity: 0.22,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  // Background Music toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.music_note),
                    title: const Text('Background music'),
                    subtitle: Text(
                      musicService.musicEnabled && !musicService.muteAll
                          ? 'Playing ambient music'
                          : 'Add music files to assets/music/ to enable',
                    ),
                    value: musicService.musicEnabled,
                    onChanged: musicService.muteAll
                        ? null
                        : (enabled) async {
                            await musicService.toggleMusic();
                            if (enabled) {
                              HapticService.light();
                            }
                          },
                  ),
                  const Divider(height: 1),
                  // Sound Effects toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.volume_up),
                    title: const Text('Sound effects'),
                    subtitle: const Text('Haptic feedback and UI sounds'),
                    value: soundPrefs.enabled,
                    onChanged: musicService.muteAll
                        ? null
                        : (enabled) {
                            ref
                                .read(soundPreferencesProvider.notifier)
                                .setEnabled(enabled);
                            // Play a test sound when enabling (but not when disabling)
                            if (enabled) {
                              // Brief delay to ensure the preference is saved
                              Future.delayed(
                                const Duration(milliseconds: 150),
                                () {
                                  SoundService.instance.success();
                                },
                              );
                            }
                          },
                  ),
                  const Divider(height: 1),
                  // Mute All toggle
                  SwitchListTile(
                    secondary: Icon(
                      musicService.muteAll
                          ? Icons.volume_off
                          : Icons.volume_mute,
                    ),
                    title: const Text('Mute all'),
                    subtitle: const Text('Disable all audio and music'),
                    value: musicService.muteAll,
                    onChanged: (muted) async {
                      await musicService.toggleMuteAll();
                      HapticService.light();
                    },
                  ),
                  if (soundPrefs.enabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        ProSpacing.md,
                        ProSpacing.md,
                        ProSpacing.md,
                        ProSpacing.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.volume_down, size: 20),
                              Expanded(
                                child: Slider(
                                  value: soundPrefs.volume,
                                  min: 0.0,
                                  max: 1.0,
                                  divisions: 10,
                                  label:
                                      '${(soundPrefs.volume * 100).round()}%',
                                  onChanged: (volume) {
                                    ref
                                        .read(soundPreferencesProvider.notifier)
                                        .setVolume(volume);
                                  },
                                ),
                              ),
                              const Icon(Icons.volume_up, size: 20),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Volume: ${(soundPrefs.volume * 100).round()}%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {
                                  SoundService.instance.success();
                                },
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('Test sound'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => GlassmorphismCard(
        blur: 18,
        borderRadius: 28,
        opacity: 0.16,
        borderOpacity: 0.22,
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
      error: (error, stack) => GlassmorphismCard(
        blur: 18,
        borderRadius: 28,
        opacity: 0.16,
        borderOpacity: 0.22,
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
                  'Unable to load sound preferences',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsHeroChip extends StatelessWidget {
  const _SettingsHeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassmorphismCard(
      blur: 16,
      borderRadius: 24,
      opacity: 0.2,
      borderOpacity: 0.35,
      padding: const EdgeInsets.symmetric(
        horizontal: VibrantSpacing.sm,
        vertical: VibrantSpacing.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: VibrantSpacing.xs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeroAction extends StatelessWidget {
  const _SettingsHeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedScaleButton(
      onTap: onTap,
      child: GlassmorphismCard(
        blur: 20,
        borderRadius: 26,
        opacity: 0.22,
        borderOpacity: 0.35,
        padding: const EdgeInsets.symmetric(
          horizontal: VibrantSpacing.md,
          vertical: VibrantSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: VibrantSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
    final preferred = kPreferredLessonModels[provider];
    if (preferred != null) {
      for (final model in models) {
        if (model.id == preferred) {
          return model.id;
        }
      }
    }
    return models.isEmpty ? null : models.first.id;
  }
}
