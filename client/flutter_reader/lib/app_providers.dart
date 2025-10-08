import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/reader_api.dart';
import 'models/app_config.dart';
import 'models/feature_flags.dart';
import 'services/auth_service.dart';
import 'services/chat_api.dart';
import 'services/lesson_api.dart';
import 'services/progress_service.dart';
import 'services/progress_store.dart';
import 'services/tts_api.dart';
import 'services/tts_controller.dart';
import 'services/daily_goal_service.dart';
import 'services/combo_service.dart';
import 'services/power_up_service.dart';
import 'services/badge_service.dart';
import 'services/achievement_service.dart';
import 'services/adaptive_difficulty_service.dart';
import 'services/retention_loop_service.dart';

final appConfigProvider = Provider<AppConfig>((_) {
  throw UnimplementedError('appConfigProvider must be overridden');
});

/// Provider for authentication service
final authServiceProvider = Provider<AuthService>((ref) {
  final config = ref.watch(appConfigProvider);
  return AuthService(baseUrl: config.apiBaseUrl);
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

final chatApiProvider = Provider<ChatApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = ChatApi(baseUrl: config.apiBaseUrl);
  ref.onDispose(api.close);
  return api;
});

/// Provider for progress tracking and gamification
/// Uses AsyncNotifier pattern to handle async initialization properly
final progressServiceProvider = FutureProvider<ProgressService>((ref) async {
  final service = ProgressService(ProgressStore());
  await service.load();
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for daily goal tracking
final dailyGoalServiceProvider = FutureProvider<DailyGoalService>((ref) async {
  final service = DailyGoalService();
  await service.load();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for combo streak tracking
final comboServiceProvider = Provider<ComboService>((ref) {
  final service = ComboService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for power-ups and boosters
final powerUpServiceProvider = FutureProvider<PowerUpService>((ref) async {
  final service = PowerUpService();
  await service.load();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for badge collection
final badgeServiceProvider = FutureProvider<BadgeService>((ref) async {
  final service = BadgeService();
  await service.load();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for achievement tracking
final achievementServiceProvider = Provider<AchievementService>((ref) {
  final service = AchievementService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for adaptive difficulty (AI-driven personalization)
final adaptiveDifficultyServiceProvider = FutureProvider<AdaptiveDifficultyService>((ref) async {
  final service = AdaptiveDifficultyService();
  await service.load();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for retention loops (engagement mechanics)
final retentionLoopServiceProvider = FutureProvider<RetentionLoopService>((ref) async {
  final service = RetentionLoopService();
  await service.load();
  ref.onDispose(service.dispose);
  return service;
});
