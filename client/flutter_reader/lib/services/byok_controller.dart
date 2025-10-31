import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/model_registry.dart';

class ByokSettings {
  const ByokSettings({
    this.apiKey = '',
    this.lessonProvider = 'openai',
    this.lessonModel,
    this.useDemoLessonKey = false,
    this.ttsProvider = 'openai',
    this.ttsModel,
    this.chatProvider = 'openai',
    this.chatModel,
  });

  final String apiKey;
  final String lessonProvider;
  final String? lessonModel;
  final bool useDemoLessonKey;
  final String ttsProvider;
  final String? ttsModel;
  final String chatProvider;
  final String? chatModel;

  bool get hasKey => apiKey.trim().isNotEmpty;

  ByokSettings copyWith({
    String? apiKey,
    String? lessonProvider,
    String? lessonModel,
    bool clearLessonModel = false,
    bool? useDemoLessonKey,
    String? ttsProvider,
    String? ttsModel,
    bool clearTtsModel = false,
    String? chatProvider,
    String? chatModel,
    bool clearChatModel = false,
  }) {
    return ByokSettings(
      apiKey: apiKey ?? this.apiKey,
      lessonProvider: lessonProvider ?? this.lessonProvider,
      lessonModel: clearLessonModel ? null : (lessonModel ?? this.lessonModel),
      useDemoLessonKey: useDemoLessonKey ?? this.useDemoLessonKey,
      ttsProvider: ttsProvider ?? this.ttsProvider,
      ttsModel: clearTtsModel ? null : (ttsModel ?? this.ttsModel),
      chatProvider: chatProvider ?? this.chatProvider,
      chatModel: clearChatModel ? null : (chatModel ?? this.chatModel),
    );
  }

  Map<String, dynamic> toJson() => {
    'apiKey': apiKey,
    'lessonProvider': lessonProvider,
    if (lessonModel != null) 'lessonModel': lessonModel,
    'useDemoLessonKey': useDemoLessonKey,
    'ttsProvider': ttsProvider,
    if (ttsModel != null) 'ttsModel': ttsModel,
    'chatProvider': chatProvider,
    if (chatModel != null) 'chatModel': chatModel,
  };

  factory ByokSettings.fromJson(Map<String, dynamic> json) {
    final rawLessonModel = (json['lessonModel'] as String?)?.trim();
    final rawTtsModel = (json['ttsModel'] as String?)?.trim();
    final rawChatModel = (json['chatModel'] as String?)?.trim();
    final rawLessonProvider = (json['lessonProvider'] as String? ?? 'openai')
        .trim();
    final rawTtsProvider = (json['ttsProvider'] as String? ?? 'openai').trim();
    final rawChatProvider = (json['chatProvider'] as String? ?? 'openai')
        .trim();
    final useDemoLessonKey = json['useDemoLessonKey'] is bool
        ? json['useDemoLessonKey'] as bool
        : false;
    final lessonProvider = rawLessonProvider.isEmpty
        ? 'openai'
        : rawLessonProvider;
    final ttsProvider = rawTtsProvider.isEmpty ? 'openai' : rawTtsProvider;
    final chatProvider = rawChatProvider.isEmpty ? 'openai' : rawChatProvider;
    final preferredLessonModel =
        kPreferredLessonModels[lessonProvider] ?? 'gpt-5-nano';
    final preferredChatModel =
        kPreferredLessonModels[chatProvider] ?? 'gpt-5-nano';

    return ByokSettings(
      apiKey: (json['apiKey'] as String? ?? '').trim(),
      lessonProvider: lessonProvider,
      lessonModel: lessonProvider == 'echo'
          ? null
          : (rawLessonModel == null || rawLessonModel.isEmpty
                ? preferredLessonModel
                : rawLessonModel),
      useDemoLessonKey: useDemoLessonKey,
      ttsProvider: ttsProvider,
      ttsModel: rawTtsModel == null || rawTtsModel.isEmpty ? null : rawTtsModel,
      chatProvider: chatProvider,
      chatModel: chatProvider == 'echo'
          ? null
          : (rawChatModel == null || rawChatModel.isEmpty
                ? preferredChatModel
                : rawChatModel),
    );
  }
}

abstract class ByokKeyStore {
  Future<ByokSettings?> read();
  Future<void> write(ByokSettings settings);
  Future<void> delete();
}

class SharedPrefsKeyStore implements ByokKeyStore {
  SharedPrefsKeyStore({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _settingsKey = 'byok.settings';
  static const _legacyKey = 'byok.apiKey';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<ByokSettings?> read() async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_settingsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return ByokSettings.fromJson(map);
      } on FormatException {
        // Fall back to legacy key if parsing fails
      }
    }

    final legacy = prefs.getString(_legacyKey);
    if (legacy != null && legacy.trim().isNotEmpty) {
      return ByokSettings(apiKey: legacy.trim());
    }
    return null;
  }

  @override
  Future<void> write(ByokSettings settings) async {
    final prefs = await _getPrefs();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
    if (!settings.hasKey) {
      await prefs.remove(_legacyKey);
    }
  }

  @override
  Future<void> delete() async {
    final prefs = await _getPrefs();
    await prefs.remove(_settingsKey);
    await prefs.remove(_legacyKey);
  }
}

class SessionKeyStore implements ByokKeyStore {
  const SessionKeyStore();

  static ByokSettings? _session;

  @override
  Future<ByokSettings?> read() async => _session;

  @override
  Future<void> write(ByokSettings settings) async {
    _session = settings;
  }

  @override
  Future<void> delete() async {
    _session = null;
  }
}

final byokStorageProvider = Provider<ByokKeyStore>((_) {
  if (kIsWeb) {
    return const SessionKeyStore();
  }
  return SharedPrefsKeyStore();
});

final byokControllerProvider =
    AsyncNotifierProvider<ByokController, ByokSettings>(ByokController.new);

class ByokController extends AsyncNotifier<ByokSettings> {
  late final ByokKeyStore _storage;
  late ByokSettings _current;

  ByokSettings get current => _current;

  @override
  Future<ByokSettings> build() async {
    _storage = ref.watch(byokStorageProvider);
    _current = await _storage.read() ?? const ByokSettings();
    return _current;
  }

  Future<void> saveSettings(ByokSettings settings) async {
    final trimmedLessonModel = settings.lessonModel?.trim();
    final trimmedTtsModel = settings.ttsModel?.trim();
    final trimmedChatModel = settings.chatModel?.trim();
    final trimmedApiKey = settings.apiKey.trim();
    final normalizedLessonProvider = settings.lessonProvider.trim().isEmpty
        ? 'openai'
        : settings.lessonProvider.trim();
    final normalizedTtsProvider = settings.ttsProvider.trim().isEmpty
        ? 'openai'
        : settings.ttsProvider.trim();
    final normalizedChatProvider = settings.chatProvider.trim().isEmpty
        ? 'openai'
        : settings.chatProvider.trim();

    final hasLessonModel =
        trimmedLessonModel != null && trimmedLessonModel.isNotEmpty;
    String? resolvedLessonModel = hasLessonModel ? trimmedLessonModel : null;
    if (resolvedLessonModel == null && normalizedLessonProvider != 'echo') {
      resolvedLessonModel =
          kPreferredLessonModels[normalizedLessonProvider] ?? 'gpt-5-nano';
    }
    final hasChatModel =
        trimmedChatModel != null && trimmedChatModel.isNotEmpty;
    String? resolvedChatModel = hasChatModel ? trimmedChatModel : null;
    if (resolvedChatModel == null && normalizedChatProvider != 'echo') {
      resolvedChatModel =
          kPreferredLessonModels[normalizedChatProvider] ?? 'gpt-5-nano';
    }

    final normalizedUseDemoLessonKey =
        settings.useDemoLessonKey &&
        trimmedApiKey.isEmpty &&
        normalizedLessonProvider != 'echo';

    final shouldClearLessonModel = normalizedLessonProvider == 'echo';
    final shouldClearChatModel = normalizedChatProvider == 'echo';
    final normalized = settings.copyWith(
      apiKey: trimmedApiKey,
      lessonProvider: normalizedLessonProvider,
      lessonModel: resolvedLessonModel,
      clearLessonModel: shouldClearLessonModel,
      useDemoLessonKey: normalizedUseDemoLessonKey,
      ttsProvider: normalizedTtsProvider,
      ttsModel: trimmedTtsModel,
      clearTtsModel: trimmedTtsModel == null || trimmedTtsModel.isEmpty,
      chatProvider: normalizedChatProvider,
      chatModel: resolvedChatModel,
      clearChatModel: shouldClearChatModel,
    );
    _current = normalized;
    await _storage.write(normalized);
    state = AsyncValue.data(normalized);
  }

  Future<void> saveKey(String key) async {
    await saveSettings(
      _current.copyWith(apiKey: key.trim(), useDemoLessonKey: false),
    );
  }

  Future<void> clear() async {
    _current = const ByokSettings();
    await _storage.delete();
    state = const AsyncValue.data(ByokSettings());
  }
}
