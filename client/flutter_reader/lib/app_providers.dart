import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/reader_api.dart';
import 'models/app_config.dart';
import 'models/feature_flags.dart';
import 'services/lesson_api.dart';
import 'services/tts_api.dart';
import 'services/tts_controller.dart';

final appConfigProvider = Provider<AppConfig>((_) {
  throw UnimplementedError('appConfigProvider must be overridden');
});

final readerApiProvider = Provider<ReaderApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = ReaderApi(baseUrl: config.apiBaseUrl);
  ref.onDispose(api.close);
  return api;
});

final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  final api = ref.watch(readerApiProvider);
  try {
    return await api.featureFlags();
  } catch (_) {
    return FeatureFlags.none;
  }
});

final lessonApiProvider = Provider<LessonApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = LessonApi(baseUrl: config.apiBaseUrl);
  ref.onDispose(api.close);
  return api;
});

final ttsApiProvider = Provider<TtsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = TtsApi(baseUrl: config.apiBaseUrl);
  ref.onDispose(api.close);
  return api;
});

final ttsControllerProvider = Provider<TtsController>((ref) {
  final api = ref.watch(ttsApiProvider);
  final controller = TtsController(ref: ref, api: api);
  ref.onDispose(controller.dispose);
  return controller;
});
