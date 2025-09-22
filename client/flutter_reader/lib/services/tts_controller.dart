import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'byok_controller.dart';
import 'tts_api.dart';

class TtsPlaybackResult {
  const TtsPlaybackResult({required this.fellBack});

  final bool fellBack;
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
    final provider = (settings.ttsProvider).trim().isEmpty
        ? 'echo'
        : settings.ttsProvider.trim();
    final model = settings.ttsModel?.trim();
    final needsKey = provider.toLowerCase() != 'echo';
    if (needsKey && !settings.hasKey) {
      throw StateError('Add a BYOK key to use the $provider voice.');
    }

    final cacheKey = _cacheKey(provider: provider, model: model, text: trimmed);
    final cached = _cache[cacheKey];
    if (cached != null) {
      await _play(cached.audio);
      return TtsPlaybackResult(fellBack: false);
    }

    final response = await api.speak(
      text: trimmed,
      provider: provider,
      model: model,
      apiKey: settings.apiKey,
    );

    final fellBack = response.meta.provider.toLowerCase() != provider.toLowerCase();
    if (!fellBack) {
      _cache[cacheKey] = _CachedClip(
        audio: response.audio,
        provider: response.meta.provider,
        model: response.meta.model,
      );
    }

    await _play(response.audio);
    return TtsPlaybackResult(fellBack: fellBack);
  }

  Future<void> _play(Uint8List audio) async {
    if (_disposed) {
      return;
    }
    await _player.stop();
    await _player.play(BytesSource(audio));
  }

  String _cacheKey({required String provider, String? model, required String text}) {
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
  const _CachedClip({required this.audio, required this.provider, required this.model});

  final Uint8List audio;
  final String provider;
  final String model;
}
