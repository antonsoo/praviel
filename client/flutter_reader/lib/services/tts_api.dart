import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;


class TtsMeta {
  const TtsMeta({required this.provider, required this.model, required this.sampleRate});

  final String provider;
  final String model;
  final int sampleRate;

  factory TtsMeta.fromJson(Map<String, dynamic> json) {
    return TtsMeta(
      provider: (json['provider'] as String? ?? 'echo').toLowerCase(),
      model: json['model'] as String? ?? 'echo:v0',
      sampleRate: (json['sample_rate'] as num?)?.toInt() ?? 22050,
    );
  }
}

class TtsResponse {
  const TtsResponse({required this.audio, required this.meta});

  final Uint8List audio;
  final TtsMeta meta;

  factory TtsResponse.fromJson(Map<String, dynamic> json) {
    final audioJson = json['audio'] as Map<String, dynamic>? ?? const {};
    final base64 = audioJson['b64'] as String? ?? '';
    return TtsResponse(
      audio: base64Decode(base64),
      meta: TtsMeta.fromJson(json['meta'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class TtsApi {
  TtsApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<TtsResponse> speak({
    required String text,
    required String provider,
    String? model,
    required String apiKey,
  }) async {
    final uri = Uri.parse(_normalize(baseUrl)).resolve('tts/speak');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (provider != 'echo') {
      final trimmed = apiKey.trim();
      if (trimmed.isNotEmpty) {
        headers['Authorization'] = 'Bearer $trimmed';
      }
    }

    final body = jsonEncode({
      'text': text,
      'provider': provider,
      if (model != null && model.trim().isNotEmpty) 'model': model.trim(),
    });

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 400) {
      final reason = response.reasonPhrase ?? '';
      throw Exception(
        'TTS request failed: ${response.statusCode} $reason'.trim(),
      );
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return TtsResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON from /tts/speak: ${error.message}');
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /tts/speak: $error');
    }
  }

  String _normalize(String url) => url.endsWith('/') ? url : '$url/';

  Future<void> close() async => _client.close();
}
