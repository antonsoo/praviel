import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/reader_api.dart';
import 'api/progress_api.dart';
import 'models/app_config.dart';
import 'models/feature_flags.dart';
import 'services/auth_service.dart';
import 'services/chat_api.dart';
import 'services/lesson_api.dart';
import 'services/reader_api.dart' as text_reader;
import 'services/backend_progress_service.dart';
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
import 'services/leaderboard_service.dart';
import 'services/daily_challenge_service_v2.dart';
import 'services/social_api.dart';
import 'services/challenges_api.dart';
import 'services/backend_challenge_service.dart';
import 'services/connectivity_service.dart';
import 'services/srs_api.dart';
import 'services/quests_api.dart';
import 'services/password_reset_api.dart';
import 'services/offline_queue_service.dart';
import 'services/search_api.dart';
import 'services/coach_api.dart';
import 'services/api_keys_api.dart';
import 'services/user_preferences_api.dart';
import 'services/vocabulary_api.dart';
import 'services/support_api.dart';
import 'services/http/csrf_client.dart';
import 'api/leaderboard_api.dart';
import 'api/achievements_api.dart';
import 'api/shop_api.dart';
import 'services/user_profile_api.dart';

final appConfigProvider = Provider<AppConfig>((_) {
  throw UnimplementedError('appConfigProvider must be overridden');
});

final apiHttpClientProvider = Provider<CsrfClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final client = CsrfClient();
  final baseUri = Uri.parse(config.apiBaseUrl);
  unawaited(client.ensureToken(baseUri.resolve('/health')));
  ref.onDispose(client.close);
  return client;
});

class _AuthServiceNotifier extends Notifier<AuthService> {
  @override
  AuthService build() {
    final config = ref.watch(appConfigProvider);
    final httpClient = ref.watch(apiHttpClientProvider);
    final service = AuthService(
      baseUrl: config.apiBaseUrl,
      httpClient: httpClient,
    );

    void listener() {
      state = service;
    }

    service.addListener(listener);
    ref.onDispose(() {
      service.removeListener(listener);
      service.dispose();
    });

    unawaited(service.initialize());
    return service;
  }
}

/// Provider for authentication service
final authServiceProvider =
    NotifierProvider<_AuthServiceNotifier, AuthService>(
      _AuthServiceNotifier.new,
    );

final readerApiProvider = Provider<ReaderApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = ReaderApi(baseUrl: config.apiBaseUrl, client: httpClient);
  // ReaderApi doesn't need explicit disposal
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

Future<void> _syncAuthToken(
  AuthService auth,
  void Function(String? token) setter,
) async {
  if (!auth.isAuthenticated) {
    setter(null);
    return;
  }
  try {
    final headers = await auth.getAuthHeaders();
    final raw = headers['Authorization'];
    final normalized = raw?.replaceFirst('Bearer ', '').trim();
    setter(normalized != null && normalized.isNotEmpty ? normalized : null);
  } catch (_) {
    setter(null);
  }
}

void _bindAuthToken(Ref ref, void Function(String? token) setter) {
  // Initial sync
  final auth = ref.read(authServiceProvider);
  unawaited(_syncAuthToken(auth, setter));

  // Listen for changes
  ref.listen<AuthService>(
    authServiceProvider,
    (_, auth) => unawaited(_syncAuthToken(auth, setter)),
  );
}

final lessonApiProvider = Provider<LessonApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = LessonApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  // LessonApi doesn't need explicit disposal
  return api;
});

final ttsApiProvider = Provider<TtsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = TtsApi(baseUrl: config.apiBaseUrl, client: httpClient);
  // TtsApi doesn't need explicit disposal
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
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = ChatApi(baseUrl: config.apiBaseUrl, client: httpClient);
  ref.onDispose(api.close);
  return api;
});

final supportApiProvider = Provider<SupportApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = SupportApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.close);
  return api;
});

/// Provider for text reader API (browsing classical texts)
final textReaderApiProvider = Provider<text_reader.ReaderApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = text_reader.ReaderApi(
    baseUrl: config.apiBaseUrl,
    client: httpClient,
  );

  _bindAuthToken(ref, api.setAuthToken);

  ref.onDispose(api.close);
  return api;
});

/// Provider for progress API (backend sync)
final progressApiProvider = Provider<ProgressApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = ProgressApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.dispose);
  return api;
});

/// Provider for progress tracking and gamification
/// Uses backend API when authenticated, falls back to local storage when offline
final progressServiceProvider = FutureProvider<BackendProgressService>((
  ref,
) async {
  final progressApi = ref.watch(progressApiProvider);
  final authService = ref.read(authServiceProvider);

  final service = BackendProgressService(
    progressApi: progressApi,
    localStore: ProgressStore(),
    isAuthenticated: authService.isAuthenticated,
  );

  await service.load();

  // Listen for auth state changes and update service
  ref.listen<AuthService>(authServiceProvider, (previous, next) {
    service.updateAuthStatus(next.isAuthenticated);
  });

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
  final progressService = await ref.watch(progressServiceProvider.future);
  final service = PowerUpService(progressService);
  await service.load();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for daily challenges (V2 - uses backend API)
final dailyChallengeServiceProvider = FutureProvider<DailyChallengeServiceV2>((
  ref,
) async {
  final backendService = await ref.watch(
    backendChallengeServiceProvider.future,
  );
  final service = DailyChallengeServiceV2(backendService);
  await service.load();
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
final adaptiveDifficultyServiceProvider =
    FutureProvider<AdaptiveDifficultyService>((ref) async {
      final service = AdaptiveDifficultyService();
      await service.load();
      ref.onDispose(service.dispose);
      return service;
    });

/// Provider for retention loops (engagement mechanics)
final retentionLoopServiceProvider = FutureProvider<RetentionLoopService>((
  ref,
) async {
  final service = RetentionLoopService();
  await service.load();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for social features API
final socialApiProvider = Provider<SocialApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = SocialApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.close);
  return api;
});

/// Provider for challenges API (daily, weekly, streak freeze, etc.)
final challengesApiProvider = Provider<ChallengesApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = ChallengesApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.dispose);
  return api;
});

/// Provider for backend challenge service (replaces local-only service)
final backendChallengeServiceProvider = FutureProvider<BackendChallengeService>(
  (ref) async {
    final api = ref.watch(challengesApiProvider);
    final authService = ref.read(authServiceProvider);
    final service = BackendChallengeService(
      api,
      isAuthenticated: authService.isAuthenticated,
    );
    await service.load();
    ref.listen<AuthService>(authServiceProvider, (previous, next) {
      if (previous?.isAuthenticated == next.isAuthenticated) {
        return;
      }
      service.updateAuthStatus(next.isAuthenticated);
    });
    ref.onDispose(service.dispose);
    return service;
  },
);

/// Provider for connectivity monitoring and offline sync
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final challengeService = ref.watch(dailyChallengeServiceProvider);

  final service = ConnectivityService(
    onConnectivityRestored: () {
      // Trigger sync when connection is restored
      challengeService.whenData((service) => service.syncPendingUpdates());
    },
  );

  ref.onDispose(service.dispose);
  return service;
});

/// Provider for leaderboard and social features
final leaderboardServiceProvider = FutureProvider<LeaderboardService>((
  ref,
) async {
  final progressService = await ref.watch(progressServiceProvider.future);
  final socialApi = ref.watch(socialApiProvider);
  final challengesApi = ref.watch(challengesApiProvider);
  final service = LeaderboardService(
    progressService: progressService,
    socialApi: socialApi,
    challengesApi: challengesApi,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for SRS (Spaced Repetition System) flashcards API
final srsApiProvider = Provider<SrsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = SrsApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.dispose);
  return api;
});

/// Provider for Quests (long-term goals) API
final questsApiProvider = Provider<QuestsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = QuestsApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.dispose);
  return api;
});

/// Provider for password reset API
final passwordResetApiProvider = Provider<PasswordResetApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = PasswordResetApi(baseUrl: config.apiBaseUrl, client: httpClient);
  ref.onDispose(api.close);
  return api;
});

/// Provider for offline mutation queue service
final offlineQueueServiceProvider = FutureProvider<OfflineQueueService>((
  ref,
) async {
  final service = OfflineQueueService();
  await service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for search API (lexicon, grammar, texts)
final searchApiProvider = Provider<SearchApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = SearchApi(baseUrl: config.apiBaseUrl, client: httpClient);

  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.dispose);
  return api;
});

/// Provider for AI coach API (RAG-based tutoring)
final coachApiProvider = Provider<CoachApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = CoachApi(baseUrl: config.apiBaseUrl, client: httpClient);

  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.close);
  return api;
});

/// Provider for API keys management (BYOK)
final apiKeysApiProvider = Provider<ApiKeysApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = ApiKeysApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.close);
  return api;
});

/// Provider for user preferences API
final userPreferencesApiProvider = Provider<UserPreferencesApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = UserPreferencesApi(
    baseUrl: config.apiBaseUrl,
    client: httpClient,
  );
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.close);
  return api;
});

final userProfileApiProvider = Provider<UserProfileApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = UserProfileApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.close);
  return api;
});

/// Provider for leaderboard API (competitive rankings)
final leaderboardApiProvider = Provider<LeaderboardApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = LeaderboardApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.close);
  return api;
});

/// Provider for achievements API (unlocked achievements)
final achievementsApiProvider = Provider<AchievementsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = AchievementsApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  return api;
});

/// Provider for shop API (power-ups and purchases)
final shopApiProvider = Provider<ShopApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = ShopApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  return api;
});

/// Provider for vocabulary API (intelligent vocabulary practice)
final vocabularyApiProvider = Provider<VocabularyApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final httpClient = ref.watch(apiHttpClientProvider);
  final api = VocabularyApi(baseUrl: config.apiBaseUrl, client: httpClient);
  _bindAuthToken(ref, api.setAuthToken);
  ref.onDispose(api.close);
  return api;
});
