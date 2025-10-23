import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../pages/enhanced_home_page.dart';
import '../pages/pro_chat_page.dart';
import '../pages/pro_history_page.dart';
import '../pages/enhanced_profile_page.dart';
import '../pages/social_leaderboard_page.dart';
import '../pages/enhanced_reader_page.dart';
import '../pages/settings_page.dart';
import '../pages/search_page.dart';
import '../pages/achievements_page.dart';
import '../pages/skill_tree_page.dart';
import '../main.dart';
import '../widgets/layout/app_shell.dart';

/// Professional router configuration using GoRouter 14.7.3
///
/// Features:
/// - Declarative routing
/// - Deep linking support
/// - Type-safe navigation
/// - Bottom navigation shell
/// - Route guards for future auth
class AppRouter {
  static const String home = '/';
  static const String lessons = '/lessons';
  static const String chat = '/chat';
  static const String reader = '/reader';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String social = '/social';
  static const String enhancedReader = '/reader/enhanced';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String achievements = '/achievements';
  static const String skillTree = '/skill-tree';

  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    routes: [
      // Main app shell with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          // Home tab
          GoRoute(
            path: home,
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const EnhancedHomePage(),
            ),
          ),

          // Lessons tab
          GoRoute(
            path: lessons,
            name: 'lessons',
            pageBuilder: (context, state) {
              // TODO: Get lessonApi from provider
              return NoTransitionPage(
                key: state.pageKey,
                child: const Placeholder(), // VibrantLessonsPage(api: lessonApi),
              );
            },
          ),

          // Chat tab
          GoRoute(
            path: chat,
            name: 'chat',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProChatPage(),
            ),
          ),

          // Reader tab
          GoRoute(
            path: reader,
            name: 'reader',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ReaderTab(),
            ),
          ),

          // History tab
          GoRoute(
            path: history,
            name: 'history',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProHistoryPage(),
            ),
          ),

          // Profile tab
          GoRoute(
            path: profile,
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const EnhancedProfilePage(),
            ),
          ),

          // Social/Leaderboard (accessible from home)
          GoRoute(
            path: social,
            name: 'social',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SocialLeaderboardPage(),
            ),
          ),
        ],
      ),

      // Enhanced reader (fullscreen, outside shell)
      GoRoute(
        path: '$enhancedReader/:languageCode/:passageId',
        name: 'enhanced-reader',
        pageBuilder: (context, state) {
          final languageCode = state.pathParameters['languageCode'] ?? 'grc-cls';
          final passageId = state.pathParameters['passageId'] ?? '';
          final queryParams = state.uri.queryParameters;
          final text = queryParams['text'] ?? '';
          final title = queryParams['title'] ?? 'Passage';
          final reference = queryParams['reference'] ?? '';
          final translation = queryParams['translation'];

          return MaterialPage(
            key: state.pageKey,
            fullscreenDialog: true,
            child: EnhancedReaderPage(
              languageCode: languageCode,
              passageId: passageId,
              title: title,
              reference: reference,
              text: text,
              translation: translation,
            ),
          );
        },
      ),

      // Settings (modal)
      GoRoute(
        path: settings,
        name: 'settings',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: const SettingsPage(),
          ),
        ),
      ),

      // Search (modal)
      GoRoute(
        path: search,
        name: 'search',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const SearchPage(),
        ),
      ),

      // Achievements (modal)
      GoRoute(
        path: achievements,
        name: 'achievements',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const AchievementsPage(),
        ),
      ),

      // Skill Tree (modal)
      GoRoute(
        path: skillTree,
        name: 'skill-tree',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          fullscreenDialog: true,
          child: const SkillTreePage(),
        ),
      ),

      // SRS Decks (modal) - TODO: Implement when SRS feature is ready
      // Quests (modal) - TODO: Implement when quests feature is ready
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Extension methods for type-safe navigation
extension AppRouterExtension on BuildContext {
  /// Navigate to home
  void goHome() => go(AppRouter.home);

  /// Navigate to lessons
  void goLessons() => go(AppRouter.lessons);

  /// Navigate to chat
  void goChat() => go(AppRouter.chat);

  /// Navigate to reader
  void goReader() => go(AppRouter.reader);

  /// Navigate to history
  void goHistory() => go(AppRouter.history);

  /// Navigate to profile
  void goProfile() => go(AppRouter.profile);

  /// Navigate to social/leaderboard
  void goSocial() => go(AppRouter.social);

  /// Navigate to enhanced reader with passage
  void goEnhancedReader({
    required String languageCode,
    required String passageId,
    required String title,
    required String reference,
    required String text,
    String? translation,
  }) {
    final queryParams = <String, String>{
      'title': title,
      'reference': reference,
      'text': text,
    };
    if (translation != null) {
      queryParams['translation'] = translation;
    }

    final uri = Uri(
      path: '${AppRouter.enhancedReader}/$languageCode/$passageId',
      queryParameters: queryParams,
    );
    go(uri.toString());
  }

  /// Navigate to settings
  void goSettings() => go(AppRouter.settings);

  /// Navigate to search
  void goSearch() => go(AppRouter.search);

  /// Navigate to achievements
  void goAchievements() => go(AppRouter.achievements);

  /// Navigate to skill tree
  void goSkillTree() => go(AppRouter.skillTree);
}
