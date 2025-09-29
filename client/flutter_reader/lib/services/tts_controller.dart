import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'byok_controller.dart';
import 'tts_api.dart';

class TtsPlaybackResult {
  const TtsPlaybackResult({
    required this.fellBack,
    required this.provider,
    this.note,
  });

  final bool fellBack;
  final String provider;
  final String? note;
}

class TtsController {
  TtsController({required this.ref, required this.api}) {
    _player = AudioPlayer(playerId: 'tts-player');
  }

  final Ref ref;
  final TtsApi api;
  late final AudioPlayer _player;
  final Map<String, _CachedClip> _cache = <String, _CachedClip>{};
  bool _disposed = false;

  Future<TtsPlaybackResult> speak(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw StateError('Nothing to play.');
    }

    final settings = await ref.read(byokControllerProvider.future);
    final requestedProvider = settings.ttsProvider.trim().isEmpty
        ? 'echo'
        : settings.ttsProvider.trim();
    final requestedModel = settings.ttsModel?.trim();
    var provider = requestedProvider;
    final key = settings.apiKey.trim();
    if (provider.toLowerCase() != 'echo' && key.isEmpty) {
      provider = 'echo';
    }
    final model = provider.toLowerCase() == 'echo' ? null : requestedModel;

    final cacheKey = _cacheKey(provider: provider, model: model, text: trimmed);
    final cached = _cache[cacheKey];
    if (cached != null) {
      await _play(cached.audio);
      final fellBack =
          cached.provider.toLowerCase() != requestedProvider.toLowerCase();
      return TtsPlaybackResult(
        fellBack: fellBack,
        provider: cached.provider,
        note: null,
      );
    }

    final response = await api.speak(
      text: trimmed,
      provider: provider,
      model: model,
      apiKey: key,
    );

    final actualProvider = response.meta.provider;
    final fellBack =
        actualProvider.toLowerCase() != requestedProvider.toLowerCase();
    if (!fellBack) {
      _cache[cacheKey] = _CachedClip(
        audio: response.audio,
        provider: actualProvider,
        model: response.meta.model,
      );
    }

    await _play(response.audio);
    return TtsPlaybackResult(
      fellBack: fellBack,
      provider: actualProvider,
      note: response.meta.note,
    );
  }

  Future<void> _play(Uint8List audio) async {
    if (_disposed) {
      return;
    }
    await _player.stop();
    await _player.play(BytesSource(audio));
  }

  String _cacheKey({
    required String provider,
    String? model,
    required String text,
  }) {
    final normalizedProvider = provider.toLowerCase();
    final normalizedModel = (model ?? 'default').toLowerCase();
    return '$normalizedProvider|$normalizedModel|$text';
  }

  Future<void> dispose() async {
    _disposed = true;
    await _player.dispose();
  }
}

class _CachedClip {
  const _CachedClip({
    required this.audio,
    required this.provider,
    required this.model,
  });

  final Uint8List audio;
  final String provider;
  final String model;
}
