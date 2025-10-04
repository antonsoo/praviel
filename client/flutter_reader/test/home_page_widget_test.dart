import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/pages/home_page.dart';
import 'package:flutter_reader/services/progress_service.dart';
import 'package:flutter_reader/services/progress_store.dart';
import 'package:flutter_reader/app_providers.dart';

/// Widget tests for HomePage - verifying UI renders correctly
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

void main() {
  group('HomePage Widget Tests', () {
    testWidgets('Empty state: shows journey message and rocket icon', (tester) async {
      final mockStore = MockProgressStore({});
      final progressService = ProgressService(mockStore);
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      // Wait for async provider to load
      await tester.pumpAndSettle();

      // Verify empty state elements
      expect(find.textContaining('Journey'), findsOneWidget, reason: 'Should show journey message for new users');
      expect(find.byIcon(Icons.rocket_launch), findsOneWidget, reason: 'Should show rocket icon in empty state');
      expect(find.text('Start Daily Practice'), findsOneWidget, reason: 'Should show CTA button');
    });

    testWidgets('Progress state: shows XP, streak, and level', (tester) async {
      final mockStore = MockProgressStore({
        'xpTotal': 150,
        'streakDays': 3,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final progressService = ProgressService(mockStore);
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify progress elements are shown
      expect(find.text('Welcome back!'), findsOneWidget, reason: 'Should show welcome back for returning users');
      expect(find.text('150'), findsOneWidget, reason: 'Should show XP value');
      expect(find.text('3'), findsOneWidget, reason: 'Should show streak value');

      // Verify level calculation (150 XP = level 1, since floor(sqrt(150/100)) = 1)
      expect(find.text('1'), findsWidgets, reason: 'Should show level 1');
    });

    testWidgets('Progress bar: calculates correctly for mid-level', (tester) async {
      // 150 XP:
      // Current level: 1 (needs 100 XP to reach)
      // Next level: 2 (needs 400 XP to reach)
      // Progress: (150 - 100) / (400 - 100) = 50 / 300 = 0.1666...
      final mockStore = MockProgressStore({
        'xpTotal': 150,
        'streakDays': 1,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final progressService = ProgressService(mockStore);
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the progress indicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );

      // Progress should be approximately 0.166 (50/300)
      expect(progressIndicator.value, closeTo(0.166, 0.01), reason: 'Progress bar should show ~16.6% to next level');
    });

    testWidgets('Start button: fires callback when pressed', (tester) async {
      final mockStore = MockProgressStore({});
      final progressService = ProgressService(mockStore);
      await progressService.load();

      bool callbackFired = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () => callbackFired = true,
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the start button
      await tester.tap(find.text('Start Daily Practice'));
      await tester.pumpAndSettle();

      expect(callbackFired, isTrue, reason: 'Start button should trigger navigation callback');
    });

    testWidgets('Stat icons: fire, stars, medal visible with progress', (tester) async {
      final mockStore = MockProgressStore({
        'xpTotal': 100,
        'streakDays': 1,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final progressService = ProgressService(mockStore);
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify stat icons are shown
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget, reason: 'Should show fire icon for streak');
      expect(find.byIcon(Icons.stars), findsOneWidget, reason: 'Should show stars icon for XP');
      expect(find.byIcon(Icons.military_tech), findsOneWidget, reason: 'Should show medal icon for level');
    });

    testWidgets('Empty state: no stat icons shown', (tester) async {
      final mockStore = MockProgressStore({});
      final progressService = ProgressService(mockStore);
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // In empty state, stat icons should NOT be shown
      expect(find.byIcon(Icons.local_fire_department), findsNothing, reason: 'Should not show streak icon in empty state');
      expect(find.byIcon(Icons.stars), findsNothing, reason: 'Should not show XP icon in empty state');
      expect(find.byIcon(Icons.military_tech), findsNothing, reason: 'Should not show level icon in empty state');
    });

    testWidgets('XP to next level: calculates correctly', (tester) async {
      // 150 XP, level 1, needs 400 for level 2, so 250 XP remaining
      final mockStore = MockProgressStore({
        'xpTotal': 150,
        'streakDays': 1,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final progressService = ProgressService(mockStore);
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "250 XP to Level 2"
      expect(find.textContaining('250 XP to Level 2'), findsOneWidget, reason: 'Should show XP remaining to next level');
    });

    testWidgets('CTA button: empty state shows "Start Daily Practice"', (tester) async {
      final mockStore = MockProgressStore({});
      final progressService = ProgressService(mockStore);
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Start Daily Practice'), findsOneWidget, reason: 'Empty state should show Start Daily Practice');
    });

    testWidgets('CTA button: progress state shows "Continue Learning"', (tester) async {
      final mockStore = MockProgressStore({
        'xpTotal': 100,
        'streakDays': 1,
        'lastLessonAt': DateTime.now().toIso8601String(),
      });
      final progressService = ProgressService(mockStore);
      await progressService.load();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            progressServiceProvider.overrideWith((ref) async => progressService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: HomePage(
                onStartLearning: () {},
                onViewHistory: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Continue Learning'), findsOneWidget, reason: 'Progress state should show Continue Learning');
    });
  });
}
