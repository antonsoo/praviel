import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/reader_api.dart';
import 'api/progress_api.dart';
import 'models/app_config.dart';
import 'models/feature_flags.dart';
import 'services/auth_service.dart';
import 'services/chat_api.dart';
import 'services/lesson_api.dart';
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
import 'api/leaderboard_api.dart';
import 'api/achievements_api.dart';
import 'api/shop_api.dart';

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

final lessonApiProvider = Provider<LessonApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = LessonApi(baseUrl: config.apiBaseUrl);
  final auth = ref.watch(authServiceProvider);
  if (auth.isAuthenticated) {
    auth.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  } else {
    api.setAuthToken(null);
  }
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });
  // LessonApi doesn't need explicit disposal
  return api;
});

final ttsApiProvider = Provider<TtsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = TtsApi(baseUrl: config.apiBaseUrl);
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
  final api = ChatApi(baseUrl: config.apiBaseUrl);
  ref.onDispose(api.close);
  return api;
});

/// Provider for progress API (backend sync)
final progressApiProvider = Provider<ProgressApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = ProgressApi(baseUrl: config.apiBaseUrl);

  // Wire up auth token
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  ref.onDispose(api.dispose);
  return api;
});

/// Provider for progress tracking and gamification
/// Uses backend API when authenticated, falls back to local storage when offline
final progressServiceProvider = FutureProvider<BackendProgressService>((ref) async {
  final progressApi = ref.watch(progressApiProvider);
  final authService = ref.watch(authServiceProvider);

  final service = BackendProgressService(
    progressApi: progressApi,
    localStore: ProgressStore(),
    isAuthenticated: authService.isAuthenticated,
  );

  await service.load();

  // Listen for auth state changes and update service
  ref.listen(authServiceProvider, (previous, next) {
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
final dailyChallengeServiceProvider = FutureProvider<DailyChallengeServiceV2>((ref) async {
  final backendService = await ref.watch(backendChallengeServiceProvider.future);
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
  final authService = ref.watch(authServiceProvider);
  final api = SocialApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  // Set initial token if already authenticated
  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  // SocialApi doesn't need explicit disposal
  return api;
});

/// Provider for challenges API (daily, weekly, streak freeze, etc.)
final challengesApiProvider = Provider<ChallengesApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = ChallengesApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  // Set initial token if already authenticated
  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  // ChallengesApi doesn't need explicit disposal
  return api;
});

/// Provider for backend challenge service (replaces local-only service)
final backendChallengeServiceProvider = FutureProvider<BackendChallengeService>((ref) async {
  final api = ref.watch(challengesApiProvider);
  final service = BackendChallengeService(api);
  await service.load();
  return service;
});

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
  final authService = ref.watch(authServiceProvider);
  final api = SrsApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  // Set initial token if already authenticated
  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  ref.onDispose(api.dispose);
  return api;
});

/// Provider for Quests (long-term goals) API
final questsApiProvider = Provider<QuestsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = QuestsApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  // Set initial token if already authenticated
  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  ref.onDispose(api.dispose);
  return api;
});


/// Provider for password reset API
final passwordResetApiProvider = Provider<PasswordResetApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final api = PasswordResetApi(baseUrl: config.apiBaseUrl);
  ref.onDispose(api.close);
  return api;
});

/// Provider for offline mutation queue service
final offlineQueueServiceProvider = FutureProvider<OfflineQueueService>((ref) async {
  final service = OfflineQueueService();
  await service.initialize();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider for search API (lexicon, grammar, texts)
final searchApiProvider = Provider<SearchApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = SearchApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes (optional for search)
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  ref.onDispose(api.dispose);
  return api;
});

/// Provider for AI coach API (RAG-based tutoring)
final coachApiProvider = Provider<CoachApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = CoachApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes (optional for coach)
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  ref.onDispose(api.close);
  return api;
});

/// Provider for API keys management (BYOK)
final apiKeysApiProvider = Provider<ApiKeysApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = ApiKeysApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  ref.onDispose(api.close);
  return api;
});

/// Provider for user preferences API
final userPreferencesApiProvider = Provider<UserPreferencesApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = UserPreferencesApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  ref.onDispose(api.close);
  return api;
});

/// Provider for leaderboard API (competitive rankings)
final leaderboardApiProvider = Provider<LeaderboardApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = LeaderboardApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  return api;
});

/// Provider for achievements API (unlocked achievements)
final achievementsApiProvider = Provider<AchievementsApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = AchievementsApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  return api;
});

/// Provider for shop API (power-ups and purchases)
final shopApiProvider = Provider<ShopApi>((ref) {
  final config = ref.watch(appConfigProvider);
  final authService = ref.watch(authServiceProvider);
  final api = ShopApi(baseUrl: config.apiBaseUrl);

  // Update token when auth state changes
  ref.listen(authServiceProvider, (previous, next) {
    if (next.isAuthenticated) {
      next.getAuthHeaders().then((headers) {
        final token = headers['Authorization']?.replaceFirst('Bearer ', '');
        api.setAuthToken(token);
      });
    } else {
      api.setAuthToken(null);
    }
  });

  if (authService.isAuthenticated) {
    authService.getAuthHeaders().then((headers) {
      final token = headers['Authorization']?.replaceFirst('Bearer ', '');
      api.setAuthToken(token);
    });
  }

  return api;
});
