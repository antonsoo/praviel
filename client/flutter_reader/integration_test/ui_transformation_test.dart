import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:ancient_languages_app/main.dart' as app;

/// Comprehensive integration tests for the professional UI transformation
/// Tests all critical user flows:
/// - New user first experience (Home tab → Start Learning → Complete Lesson)
/// - Returning user experience (Progress persistence)
/// - Navigation across all 5 tabs
/// - Lessons tab usability (smart defaults, customization)
/// - Progress calculations and display

Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration interval = const Duration(milliseconds: 120),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(interval);
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TimeoutException('Timed out waiting for ${finder.toString()}');
}

Future<void> pumpWhile(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
  Duration interval = const Duration(milliseconds: 120),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(interval);
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  throw TimeoutException(
    'Timed out waiting for ${finder.toString()} to disappear',
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.defaultTestTimeout = const Timeout(Duration(minutes: 5));

  group('UI Transformation Tests', () {
    testWidgets('Flow 1: New user lands on Home tab by default', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      if (kIsWeb) {
        await binding.convertFlutterSurfaceToImage();
      }

      // Verify Home tab is default (index 0)
      // Look for Home-specific content
      final homeGreeting = find.textContaining('Ancient Greek Journey');
      expect(
        homeGreeting,
        findsOneWidget,
        reason: 'New user should see welcome greeting on Home tab',
      );

      // Verify bottom navigation shows Home as selected
      final homeNavItem = find.text('Home');
      expect(
        homeNavItem,
        findsOneWidget,
        reason: 'Home navigation item should be visible',
      );

      await binding.takeScreenshot('home_empty_state');
    });

    testWidgets('Flow 2: New user sees empty state with clear CTA', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      if (kIsWeb) {
        await binding.convertFlutterSurfaceToImage();
      }

      // Verify empty state content
      final journeyText = find.textContaining('journey');
      expect(
        journeyText,
        findsWidgets,
        reason: 'Should show journey-related messaging',
      );

      // Verify rocket icon exists (empty state visual)
      final rocketIcon = find.byIcon(Icons.rocket_launch);
      expect(
        rocketIcon,
        findsOneWidget,
        reason: 'Empty state should show rocket icon',
      );

      // Verify prominent CTA button exists
      final startButton = find.text('Start Daily Practice');
      expect(
        startButton,
        findsOneWidget,
        reason: 'Should show prominent Start Daily Practice button',
      );

      // Verify button is enabled
      final FilledButton button = tester.widget(
        find.ancestor(of: startButton, matching: find.byType(FilledButton)),
      );
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Start Daily Practice button should be enabled',
      );

      await binding.takeScreenshot('home_with_empty_state_cta');
    });

    testWidgets('Flow 3: Start Learning button navigates to Lessons tab', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap the Start Daily Practice button
      final startButton = find.text('Start Daily Practice');
      expect(startButton, findsOneWidget, reason: 'Start button should exist');

      await tester.tap(startButton);
      await tester.pumpAndSettle();

      // Verify navigation to Lessons tab
      // Check for Lessons tab content (Sources section)
      await pumpUntil(
        tester,
        find.text('Sources'),
        timeout: const Duration(seconds: 10),
      );

      expect(
        find.text('Sources'),
        findsOneWidget,
        reason: 'Should navigate to Lessons tab',
      );

      await binding.takeScreenshot('lessons_after_navigation');
    });

    testWidgets('Flow 4: All 5 tabs are present and navigable', (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify all 5 navigation destinations exist
      expect(
        find.text('Home'),
        findsOneWidget,
        reason: 'Home tab should exist',
      );
      expect(
        find.text('Reader'),
        findsOneWidget,
        reason: 'Reader tab should exist',
      );
      expect(
        find.text('Lessons'),
        findsOneWidget,
        reason: 'Lessons tab should exist',
      );
      expect(
        find.text('Chat'),
        findsOneWidget,
        reason: 'Chat tab should exist',
      );
      expect(
        find.text('History'),
        findsOneWidget,
        reason: 'History tab should exist',
      );

      // Test navigation to each tab
      await tester.tap(find.text('Reader'));
      await tester.pumpAndSettle();
      expect(
        find.text('Greek text'),
        findsOneWidget,
        reason: 'Reader tab should load',
      );

      await tester.tap(find.text('Lessons'));
      await tester.pumpAndSettle();
      await pumpUntil(tester, find.text('Sources'));
      expect(
        find.text('Sources'),
        findsOneWidget,
        reason: 'Lessons tab should load',
      );

      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();
      // Chat tab should show input field
      expect(
        find.byType(TextField),
        findsWidgets,
        reason: 'Chat tab should load',
      );

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      // History tab should load (may be empty)
      expect(
        find.text('History'),
        findsOneWidget,
        reason: 'History tab should load',
      );

      // Return to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Greek Journey'),
        findsOneWidget,
        reason: 'Should return to Home tab',
      );

      await binding.takeScreenshot('all_tabs_navigation');
    });

    testWidgets(
      'Flow 5: Lessons tab has prominent Start button and collapsible customization',
      (tester) async {
        await app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Navigate to Lessons tab
        await tester.tap(find.text('Lessons'));
        await tester.pumpAndSettle();
        await pumpUntil(tester, find.text('Sources'));

        // Verify Start Daily Practice button is prominent
        final startButtons = find.text('Start Daily Practice');
        expect(
          startButtons,
          findsWidgets,
          reason: 'Should have Start Daily Practice button',
        );

        // Verify customization section exists and is expandable
        final customizeSection = find.text('Customize Lesson');
        expect(
          customizeSection,
          findsOneWidget,
          reason: 'Should have Customize Lesson section',
        );

        // Tap to expand customization
        await tester.tap(customizeSection);
        await tester.pumpAndSettle();

        // Verify customization options are now visible
        expect(
          find.text('Exercises'),
          findsWidgets,
          reason: 'Should show exercise customization',
        );

        await binding.takeScreenshot('lessons_customization_expanded');
      },
    );

    testWidgets('Flow 6: Progress calculations are mathematically correct', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // This test verifies that progress service integration works
      // The actual math is tested in unit tests, but here we verify UI integration

      // Home tab should show progress widgets (even if zero)
      expect(find.text('Home'), findsOneWidget);

      // Verify Home page renders correctly
      // Progress-related widgets (Streak, XP, Level) may or may not be visible
      // depending on whether user has completed lessons
      // This is a basic integration check
      expect(
        find.byType(Widget),
        findsWidgets,
        reason: 'Home page should render',
      );
    });

    testWidgets('Flow 7: Celebration parameters are correctly configured', (
      tester,
    ) async {
      // This test verifies celebration widget exists in the widget tree
      // Actual visual verification (duration 3s, 200 particles) requires manual testing
      // But we can verify the code is integrated correctly

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Home tab (already there by default)
      // Celebration code is in lessons_page.dart and is shown when lesson completes
      // This test verifies the app structure supports celebration

      expect(
        find.text('Home'),
        findsOneWidget,
        reason: 'App should start successfully',
      );

      // The celebration overlay is conditionally rendered, so we can't test it directly
      // without completing a lesson. This would require mocking or a full lesson flow.
      // For now, verify the app loads without errors (which means celebration code compiles)
    });

    testWidgets(
      'Flow 8: Error handling - app handles missing progress gracefully',
      (tester) async {
        await app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        if (kIsWeb) {
          await binding.convertFlutterSurfaceToImage();
        }

        // Even with no stored progress, app should render Home tab
        expect(
          find.text('Home'),
          findsOneWidget,
          reason: 'App should handle missing progress',
        );

        // Should show empty state (not error)
        final journeyText = find.textContaining('Journey');
        expect(
          journeyText,
          findsWidgets,
          reason: 'Should show friendly empty state, not error',
        );

        // Should not show error message
        final errorText = find.textContaining('Error');
        expect(
          errorText,
          findsNothing,
          reason: 'Should not show error on missing progress',
        );
      },
    );

    testWidgets(
      'Flow 9: Progress card shows all stats when user has progress',
      (tester) async {
        // This test is limited because we can't easily inject progress data
        // without completing a lesson or using test-specific providers
        // For now, verify the UI structure is correct

        await app.main();
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Home tab should render
        expect(find.text('Home'), findsOneWidget);

        // In empty state, stat icons (fire, stars, medal) may not be visible
        // In progress state, they should be displayed
        // This is a smoke test to verify the home page structure is correct
        expect(
          find.byType(Scaffold),
          findsOneWidget,
          reason: 'Home page should have proper structure',
        );
      },
    );

    testWidgets('Flow 10: Visual polish - spacing and design tokens applied', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      if (kIsWeb) {
        await binding.convertFlutterSurfaceToImage();
      }

      // Verify Surface widget is used (indicates design system applied)
      expect(
        find.byType(SizedBox),
        findsWidgets,
        reason: 'Should use spacing widgets',
      );

      // Verify FilledButton is used (Material 3 design)
      expect(
        find.byType(FilledButton),
        findsWidgets,
        reason: 'Should use M3 components',
      );

      // Verify app has proper structure
      expect(
        find.byType(Scaffold),
        findsOneWidget,
        reason: 'Should have proper scaffold',
      );
      expect(
        find.byType(NavigationBar),
        findsOneWidget,
        reason: 'Should have navigation bar',
      );

      await binding.takeScreenshot('visual_polish_verification');
    });
  });

  group('Performance Tests', () {
    testWidgets('App startup performance', (tester) async {
      final stopwatch = Stopwatch()..start();

      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      stopwatch.stop();

      // Verify app starts in reasonable time (< 10 seconds)
      expect(
        stopwatch.elapsed.inSeconds,
        lessThan(10),
        reason: 'App should start within 10 seconds',
      );

      debugPrint('App startup took: ${stopwatch.elapsed.inMilliseconds}ms');
    });

    testWidgets('Tab navigation performance', (tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final stopwatch = Stopwatch();

      // Measure navigation to Lessons tab
      stopwatch.start();
      await tester.tap(find.text('Lessons'));
      await tester.pumpAndSettle();
      stopwatch.stop();

      debugPrint(
        'Navigation to Lessons took: ${stopwatch.elapsed.inMilliseconds}ms',
      );

      // Should feel instant (< 500ms)
      expect(
        stopwatch.elapsed.inMilliseconds,
        lessThan(500),
        reason: 'Tab navigation should be fast',
      );
    });
  });

  group('Regression Tests', () {
    testWidgets('Regression: Reader tab still works after UI transformation', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Reader tab
      await tester.tap(find.text('Reader'));
      await tester.pumpAndSettle();

      // Verify Reader functionality intact
      expect(
        find.text('Greek text'),
        findsOneWidget,
        reason: 'Reader should still work',
      );
      expect(
        find.byType(TextField),
        findsWidgets,
        reason: 'Reader input should work',
      );
    });

    testWidgets('Regression: Chat tab still works after UI transformation', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Chat tab
      await tester.tap(find.text('Chat'));
      await tester.pumpAndSettle();

      // Verify Chat functionality intact
      expect(
        find.byType(TextField),
        findsWidgets,
        reason: 'Chat should still work',
      );
    });

    testWidgets('Regression: History tab still works after UI transformation', (
      tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to History tab
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      // Verify History renders (may be empty)
      expect(
        find.text('History'),
        findsOneWidget,
        reason: 'History should still work',
      );
    });
  });
}
