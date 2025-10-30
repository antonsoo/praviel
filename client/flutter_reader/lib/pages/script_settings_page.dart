import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/script_preferences_api.dart';
import '../models/script_preferences.dart';
import '../app_providers.dart';
import '../theme/professional_theme.dart';
import '../services/haptic_service.dart';
import '../widgets/premium_snackbars.dart';

/// Script preferences settings page for configuring authentic ancient script display.
///
/// Allows users to toggle:
/// - Master "Authentic Mode"
/// - Per-language settings (Latin, Classical Greek, Koine Greek):
///   - Scriptio continua (continuous writing)
///   - Interpuncts (· for word separation)
///   - Iota adscript (ΑΙ instead of ᾳ for Greek)
///   - Nomina sacra (sacred name abbreviations with overlines for Koine)
///   - Modern punctuation removal
class ScriptSettingsPage extends ConsumerStatefulWidget {
  const ScriptSettingsPage({super.key});

  @override
  ConsumerState<ScriptSettingsPage> createState() => _ScriptSettingsPageState();
}

class _ScriptSettingsPageState extends ConsumerState<ScriptSettingsPage>
    with SingleTickerProviderStateMixin {
  late ScriptPreferencesAPI _api;
  ScriptPreferences? _preferences;
  bool _isLoading = true;
  String? _error;
  bool _isSaving = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const String _localStorageKey = 'script_preferences_guest';

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
    _initializeApi();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _initializeApi() async {
    final config = ref.read(appConfigProvider);
    final authService = ref.read(authServiceProvider);

    // Initialize API with proper config
    _api = ScriptPreferencesAPI(baseUrl: config.apiBaseUrl);

    // Set auth token if authenticated
    if (authService.isAuthenticated) {
      final headers = await authService.getAuthHeaders();
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      _api.setAuthToken(token);
    }

    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (authService.isAuthenticated) {
        // Authenticated users: load from backend
        final prefs = await _api.getScriptPreferences();
        setState(() {
          _preferences = prefs;
          _isLoading = false;
        });
      } else {
        // Bug fix #5: Guest users load from local storage
        final localPrefs = await SharedPreferences.getInstance();
        final storedJson = localPrefs.getString(_localStorageKey);

        if (storedJson != null) {
          try {
            final decoded = jsonDecode(storedJson) as Map<String, dynamic>;
            setState(() {
              _preferences = ScriptPreferences.fromJson(decoded);
              _isLoading = false;
            });
          } catch (e) {
            // Corrupted data, use defaults
            setState(() {
              _preferences = const ScriptPreferences();
              _isLoading = false;
            });
          }
        } else {
          // No stored preferences, use defaults
          setState(() {
            _preferences = const ScriptPreferences();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Fallback to default preferences if backend fails
      // Don't show error for guest users - just use defaults
      setState(() {
        _preferences = const ScriptPreferences();
        _isLoading = false;
        _error = null; // Clear any error - guests don't need to see API errors
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final authService = ref.read(authServiceProvider);

      if (authService.isAuthenticated) {
        // Authenticated users: save to backend
        final updated = await _api.updateScriptPreferences(_preferences!);
        setState(() {
          _preferences = updated;
          _isSaving = false;
        });
      } else {
        // Bug fix #5: Guest users save to local storage
        final localPrefs = await SharedPreferences.getInstance();
        final jsonString = jsonEncode(_preferences!.toJson());
        await localPrefs.setString(_localStorageKey, jsonString);

        setState(() {
          _isSaving = false;
        });
      }

      if (mounted) {
        HapticService.success();
        PremiumSnackBar.success(
          context,
          message: authService.isAuthenticated
              ? 'Script preferences saved'
              : 'Script preferences saved locally (sign in to sync across devices)',
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        HapticService.error();
        PremiumSnackBar.error(
          context,
          message: 'Failed to save: $e',
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    try {
      setState(() {
        _isSaving = true;
      });

      final defaults = await _api.resetScriptPreferences();
      setState(() {
        _preferences = defaults;
        _isSaving = false;
      });

      if (mounted) {
        HapticService.success();
        PremiumSnackBar.success(
          context,
          message: 'Reset to defaults',
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        HapticService.error();
        PremiumSnackBar.error(
          context,
          message: 'Failed to reset: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Script Preferences'),
        actions: [
          if (_preferences != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset to defaults',
              onPressed: _isSaving ? null : _resetToDefaults,
            ),
          if (_preferences != null)
            Padding(
              padding: const EdgeInsets.only(right: ProSpacing.md),
              child: TextButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save'),
                onPressed: _isSaving ? null : _savePreferences,
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: ProSpacing.md),
              ElevatedButton(
                onPressed: _loadPreferences,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_preferences == null) {
      return const Center(child: Text('No preferences loaded'));
    }

    return ListView(
      padding: const EdgeInsets.all(ProSpacing.md),
      children: [
        _buildInfoCard(),
        const SizedBox(height: ProSpacing.lg),
        _buildAuthenticModeToggle(),
        const SizedBox(height: ProSpacing.md),
        _buildLanguageSection('Classical Latin', 'lat', _preferences!.latin),
        const SizedBox(height: ProSpacing.sm),
        _buildLanguageSection('Classical Greek', 'grc-cls', _preferences!.greekClassical),
        const SizedBox(height: ProSpacing.sm),
        _buildLanguageSection('Koine Greek', 'grc-koi', _preferences!.greekKoine),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(ProSpacing.md),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: ProSpacing.md),
            Expanded(
              child: Text(
                'Configure how ancient texts are displayed using historically accurate conventions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticModeToggle() {
    return Card(
      child: SwitchListTile(
        title: const Text(
          'Authentic Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Enable historically accurate script rendering (uppercase, no accents)',
        ),
        value: _preferences!.authenticMode,
        onChanged: (value) {
          setState(() {
            _preferences = _preferences!.copyWith(authenticMode: value);
          });
        },
      ),
    );
  }

  Widget _buildLanguageSection(
    String title,
    String languageCode,
    ScriptDisplayMode mode,
  ) {
    return Card(
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getLanguageSummary(mode),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          _buildScriptOption(
            'Scriptio Continua',
            'Remove all word spaces (continuous writing)',
            mode.useScriptioContinua,
            (value) => _updateMode(languageCode, mode.copyWith(useScriptioContinua: value)),
          ),
          _buildScriptOption(
            'Interpuncts',
            'Replace spaces with interpuncts (·) for word separation',
            mode.useInterpuncts,
            (value) => _updateMode(languageCode, mode.copyWith(useInterpuncts: value)),
          ),
          if (languageCode == 'grc-cls' || languageCode == 'grc-koi')
            _buildScriptOption(
              'Iota Adscript',
              'Convert iota subscripts to full iota (ᾳ → ΑΙ)',
              mode.useIotaAdscript,
              (value) => _updateMode(languageCode, mode.copyWith(useIotaAdscript: value)),
            ),
          if (languageCode == 'grc-koi')
            _buildScriptOption(
              'Nomina Sacra',
              'Use sacred name abbreviations with overlines (Θ͞Σ͞)',
              mode.useNominaSacra,
              (value) => _updateMode(languageCode, mode.copyWith(useNominaSacra: value)),
            ),
          _buildScriptOption(
            'Remove Modern Punctuation',
            'Strip modern punctuation marks (?, !, commas)',
            mode.removeModernPunctuation,
            (value) => _updateMode(languageCode, mode.copyWith(removeModernPunctuation: value)),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ProSpacing.lg,
        vertical: ProSpacing.xs,
      ),
    );
  }

  void _updateMode(String languageCode, ScriptDisplayMode newMode) {
    setState(() {
      if (languageCode == 'lat') {
        _preferences = _preferences!.copyWith(latin: newMode);
      } else if (languageCode == 'grc-cls') {
        _preferences = _preferences!.copyWith(greekClassical: newMode);
      } else if (languageCode == 'grc-koi') {
        _preferences = _preferences!.copyWith(greekKoine: newMode);
      }
    });
  }

  String _getLanguageSummary(ScriptDisplayMode mode) {
    final features = <String>[];
    if (mode.useScriptioContinua) features.add('continua');
    if (mode.useInterpuncts) features.add('interpuncts');
    if (mode.useIotaAdscript) features.add('iota adscript');
    if (mode.useNominaSacra) features.add('nomina sacra');
    if (mode.removeModernPunctuation) features.add('no punctuation');

    if (features.isEmpty) return 'Default settings';
    return features.join(', ');
  }
}
