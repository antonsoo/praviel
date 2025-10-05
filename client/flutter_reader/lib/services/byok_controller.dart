import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ByokSettings {
  const ByokSettings({
    this.apiKey = '',
    this.lessonProvider = 'echo',
    this.lessonModel,
    this.ttsProvider = 'echo',
    this.ttsModel,
    this.chatProvider = 'echo',
    this.chatModel,
  });

  final String apiKey;
  final String lessonProvider;
  final String? lessonModel;
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
    'ttsProvider': ttsProvider,
    if (ttsModel != null) 'ttsModel': ttsModel,
    'chatProvider': chatProvider,
    if (chatModel != null) 'chatModel': chatModel,
  };

  factory ByokSettings.fromJson(Map<String, dynamic> json) {
    final rawLessonModel = (json['lessonModel'] as String?)?.trim();
    final rawTtsModel = (json['ttsModel'] as String?)?.trim();
    final rawChatModel = (json['chatModel'] as String?)?.trim();
    return ByokSettings(
      apiKey: (json['apiKey'] as String? ?? '').trim(),
      lessonProvider: (json['lessonProvider'] as String? ?? 'echo').trim(),
      lessonModel: rawLessonModel == null || rawLessonModel.isEmpty
          ? null
          : rawLessonModel,
      ttsProvider: (json['ttsProvider'] as String? ?? 'echo').trim(),
      ttsModel: rawTtsModel == null || rawTtsModel.isEmpty ? null : rawTtsModel,
      chatProvider: (json['chatProvider'] as String? ?? 'echo').trim(),
      chatModel: rawChatModel == null || rawChatModel.isEmpty
          ? null
          : rawChatModel,
    );
  }
}

abstract class ByokKeyStore {
  Future<ByokSettings?> read();
  Future<void> write(ByokSettings settings);
  Future<void> delete();
}

class SecureStorageKeyStore implements ByokKeyStore {
  SecureStorageKeyStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _settingsKey = 'byok.settings';
  static const _legacyKey = 'byok.apiKey';

  @override
  Future<ByokSettings?> read() async {
    final raw = await _storage.read(key: _settingsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return ByokSettings.fromJson(map);
      } on FormatException {
        // Fall back to legacy key if parsing fails
      }
    }

    final legacy = await _storage.read(key: _legacyKey);
    if (legacy != null && legacy.trim().isNotEmpty) {
      return ByokSettings(apiKey: legacy.trim());
    }
    return null;
  }

  @override
  Future<void> write(ByokSettings settings) async {
    await _storage.write(
      key: _settingsKey,
      value: jsonEncode(settings.toJson()),
    );
    if (!settings.hasKey) {
      await _storage.delete(key: _legacyKey);
    }
  }

  @override
  Future<void> delete() async {
    await _storage.delete(key: _settingsKey);
    await _storage.delete(key: _legacyKey);
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
  return SecureStorageKeyStore();
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
    final normalizedLessonProvider = settings.lessonProvider.trim().isEmpty
        ? 'echo'
        : settings.lessonProvider.trim();
    final normalizedTtsProvider = settings.ttsProvider.trim().isEmpty
        ? 'echo'
        : settings.ttsProvider.trim();
    final normalizedChatProvider = settings.chatProvider.trim().isEmpty
        ? 'echo'
        : settings.chatProvider.trim();
    final shouldClearLessonModel =
        trimmedLessonModel == null ||
        trimmedLessonModel.isEmpty ||
        normalizedLessonProvider == 'echo';
    final shouldClearChatModel =
        trimmedChatModel == null ||
        trimmedChatModel.isEmpty ||
        normalizedChatProvider == 'echo';
    final normalized = settings.copyWith(
      apiKey: settings.apiKey.trim(),
      lessonProvider: normalizedLessonProvider,
      lessonModel: trimmedLessonModel,
      clearLessonModel: shouldClearLessonModel,
      ttsProvider: normalizedTtsProvider,
      ttsModel: trimmedTtsModel,
      clearTtsModel: trimmedTtsModel == null || trimmedTtsModel.isEmpty,
      chatProvider: normalizedChatProvider,
      chatModel: trimmedChatModel,
      clearChatModel: shouldClearChatModel,
    );
    _current = normalized;
    await _storage.write(normalized);
    state = AsyncValue.data(normalized);
  }

  Future<void> saveKey(String key) async {
    await saveSettings(_current.copyWith(apiKey: key.trim()));
  }

  Future<void> clear() async {
    _current = const ByokSettings();
    await _storage.delete();
    state = const AsyncValue.data(ByokSettings());
  }
}
