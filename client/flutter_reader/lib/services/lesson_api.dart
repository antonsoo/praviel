import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/lesson.dart';
import 'byok_controller.dart';

class LessonApiException implements Exception {
  const LessonApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class GeneratorParams {
  const GeneratorParams({
    this.language = 'grc',
    this.profile = 'beginner',
    this.sources = const ['daily', 'canon'],
    this.exerciseTypes = const ['alphabet', 'match', 'cloze', 'translate'],
    this.kCanon = 2,
    this.includeAudio = false,
    this.provider,
    this.model,
    this.register = 'literary',
  });

  final String language;
  final String profile;
  final List<String> sources;
  final List<String> exerciseTypes;
  final int kCanon;
  final bool includeAudio;
  final String? provider;
  final String? model;
  final String register;

  Map<String, dynamic> toJson({
    String? overrideProvider,
    String? overrideModel,
  }) => {
    'language': language,
    'profile': profile,
    'sources': sources,
    'exercise_types': exerciseTypes,
    'k_canon': kCanon,
    'include_audio': includeAudio,
    'provider': overrideProvider ?? provider ?? 'echo',
    if ((overrideModel ?? model) != null) 'model': overrideModel ?? model,
    'register': register,
  };
}

class LessonApi {
  LessonApi({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<LessonResponse> generate(
    GeneratorParams params,
    ByokSettings settings,
  ) async {
    final provider = (params.provider ?? settings.lessonProvider).trim().isEmpty
        ? 'echo'
        : (params.provider ?? settings.lessonProvider).trim();
    final model = provider == 'echo'
        ? null
        : (params.model ?? settings.lessonModel);
    final uri = Uri.parse(_normalize(baseUrl)).resolve('lesson/generate');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (provider != 'echo') {
      final key = settings.apiKey.trim();
      if (key.isNotEmpty) {
        headers['Authorization'] = 'Bearer $key';
      }
    }

    final body = jsonEncode(
      params.toJson(overrideProvider: provider, overrideModel: model),
    );

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode >= 400) {
      final reason = response.reasonPhrase ?? '';
      var message = 'Lesson generation failed: ${response.statusCode} $reason'
          .trim();
      try {
        final payload = jsonDecode(response.body);
        if (payload is Map<String, dynamic>) {
          final error = payload['error'];
          if (error is Map<String, dynamic>) {
            final raw = error['message'];
            if (raw is String && raw.trim().isNotEmpty) {
              message = raw.trim();
            }
          } else {
            final detail = payload['detail'];
            if (detail is String && detail.trim().isNotEmpty) {
              message = detail.trim();
            }
          }
        }
      } catch (_) {
        // Ignore parse errors and fall back to default message.
      }
      throw LessonApiException(message, statusCode: response.statusCode);
    }

    try {
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return LessonResponse.fromJson(payload);
    } on FormatException catch (error) {
      throw Exception('Invalid JSON from /lesson/generate: ${error.message}');
    } on TypeError catch (error) {
      throw Exception('Unexpected schema from /lesson/generate: $error');
    }
  }

  String _normalize(String url) => url.endsWith('/') ? url : '$url/';

  Future<void> close() async => _client.close();
}
