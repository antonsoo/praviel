import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praviel/pages/stunning_home_page.dart';
import 'package:praviel/services/backend_progress_service.dart';
import 'package:praviel/services/progress_store.dart';
import 'package:praviel/api/progress_api.dart';
import 'package:praviel/app_providers.dart';

/// Widget tests for StunningHomePage - verifying UI renders correctly
/// These tests run WITHOUT a browser and verify widget structure
class MockProgressStore implements ProgressStore {
  final Map<String, dynamic> _data;

  MockProgressStore(this._data);

  @override
  Future<Map<String, dynamic>> load() async => Map.from(_data);

  @override
  Future<void> save(Map<String, dynamic> data) async {
    _data.clear();
    _data.addAll(data);
  }

  @override
  Future<void> reset() async {
    _data.clear();
  }
}

class MockProgressApi extends ProgressApi {
  MockProgressApi() : super(baseUrl: 'http://mock');

  @override
  Future<UserProgressResponse> getUserProgress() async {
    return UserProgressResponse(
      xpTotal: 0,
      streakDays: 0,
      maxStreak: 0,
      coins: 0,
      streakFreezes: 0,
      totalLessons: 0,
      totalExercises: 0,
      totalTimeMinutes: 0,
      level: 0,
      xpForCurrentLevel: 0,
      xpForNextLevel: 100,
      xpToNextLevel: 100,
      progressToNextLevel: 0.0,
      lastLessonAt: null,
      lastStreakUpdate: null,
    );
  }

  @override
  Future<UserProgressResponse> updateProgress({
    required int xpGained,
    String? lessonId,
    int? timeSpentMinutes,
    bool? isPerfect,
    int? wordsLearnedCount,
  }) async {
    return getUserProgress();
  }
}

void main() {
  group('StunningHomePage Widget Tests', () {
    testWidgets('Empty state: shows journey message and rocket icon', (
      tester,
    ) async {
      final mockStore = MockProgressStore({});
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      // Wait for async provider to load (use pump instead of pumpAndSettle due to infinite animations)
      await tester.pump(); // Build initial frame
      await tester.pump(); // Build frame after future completes

      // Verify empty state elements
      expect(
        find.textContaining('Journey'),
        findsWidgets, // Multiple widgets contain "Journey"
        reason: 'Should show journey message for new users',
      );
      expect(
        find.byIcon(Icons.rocket_launch),
        findsOneWidget,
        reason: 'Should show rocket icon in empty state',
      );
      expect(
        find.text('Start Your Journey'),
        findsOneWidget,
        reason: 'Should show CTA button',
      );
    });

    testWidgets('Progress state: shows XP, streak, and level', (tester) async {
      final mockStore = MockProgressStore({
        'xpTotal': 150,
        'streakDays': 3,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify progress elements are shown
      expect(
        find.textContaining('Welcome Back'),
        findsOneWidget,
        reason: 'Should show welcome back for returning users',
      );
      expect(find.text('150'), findsOneWidget, reason: 'Should show XP value');
      expect(
        find.text('3'),
        findsOneWidget,
        reason: 'Should show streak value',
      );

      // Verify level calculation (150 XP = level 1, since floor(sqrt(150/100)) = 1)
      expect(find.text('1'), findsWidgets, reason: 'Should show level 1');
    });

    testWidgets('Progress bar: calculates correctly for mid-level', (
      tester,
    ) async {
      // 150 XP:
      // Current level: 1 (needs 100 XP to reach)
      // Next level: 2 (needs 400 XP to reach)
      // Progress: (150 - 100) / (400 - 100) = 50 / 300 = 0.1666...
      final mockStore = MockProgressStore({
        'xpTotal': 150,
        'streakDays': 1,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Find the progress indicator (FractionallySizedBox in StunningHomePage)
      final progressWidget = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );

      // Progress should be approximately 0.166 (50/300)
      expect(
        progressWidget.widthFactor,
        closeTo(0.166, 0.01),
        reason: 'Progress bar should show ~16.6% to next level',
      );
    });

    testWidgets('Start button: fires callback when pressed', (tester) async {
      final mockStore = MockProgressStore({});
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      bool callbackFired = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () => callbackFired = true,
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Find and tap the start button
      await tester.tap(find.text('Start Your Journey'));
      await tester.pump();

      expect(
        callbackFired,
        isTrue,
        reason: 'Start button should trigger navigation callback',
      );
    });

    testWidgets('Stat icons: fire, stars, medal visible with progress', (
      tester,
    ) async {
      final mockStore = MockProgressStore({
        'xpTotal': 100,
        'streakDays': 1,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify stat icons are shown
      expect(
        find.byIcon(Icons.local_fire_department),
        findsOneWidget,
        reason: 'Should show fire icon for streak',
      );
      expect(
        find.byIcon(Icons.stars),
        findsOneWidget,
        reason: 'Should show stars icon for XP',
      );
      expect(
        find.byIcon(Icons.military_tech),
        findsOneWidget,
        reason: 'Should show medal icon for level',
      );
    });

    testWidgets('Empty state: no stat icons shown', (tester) async {
      final mockStore = MockProgressStore({});
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // In empty state, stat icons should NOT be shown
      expect(
        find.byIcon(Icons.local_fire_department),
        findsNothing,
        reason: 'Should not show streak icon in empty state',
      );
      expect(
        find.byIcon(Icons.stars),
        findsNothing,
        reason: 'Should not show XP icon in empty state',
      );
      expect(
        find.byIcon(Icons.military_tech),
        findsNothing,
        reason: 'Should not show level icon in empty state',
      );
    });

    testWidgets('XP to next level: calculates correctly', (tester) async {
      // 150 XP, level 1, needs 400 for level 2, so 250 XP remaining
      final mockStore = MockProgressStore({
        'xpTotal': 150,
        'streakDays': 1,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should show "250 XP to next level"
      expect(
        find.textContaining('250 XP to next level'),
        findsOneWidget,
        reason: 'Should show XP remaining to next level',
      );
    });

    testWidgets('CTA button: empty state shows "Start Your Journey"', (
      tester,
    ) async {
      final mockStore = MockProgressStore({});
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.text('Start Your Journey'),
        findsOneWidget,
        reason: 'Empty state should show Start Your Journey',
      );
    });

    testWidgets('CTA button: progress state shows "Continue Learning"', (
      tester,
    ) async {
      final mockStore = MockProgressStore({
        'xpTotal': 100,
        'streakDays': 1,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final mockApi = MockProgressApi();
      final progressService = BackendProgressService(
        progressApi: mockApi,
        localStore: mockStore,
        isAuthenticated: false,
      );
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith(
              (ref) async => progressService,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StunningHomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.text('Continue Learning'),
        findsOneWidget,
        reason: 'Progress state should show Continue Learning',
      );
    });
  });
}
