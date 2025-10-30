import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:praviel/widgets/skeleton_loader.dart';
import 'package:praviel/widgets/custom_refresh_indicator.dart';
import 'package:praviel/theme/vibrant_theme.dart';

void main() {
  group('Skeleton Loader Widget Tests', () {
    testWidgets('SkeletonLoader displays with correct size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(width: 100, height: 50),
          ),
        ),
      );

      final skeleton = tester.widget<SkeletonLoader>(find.byType(SkeletonLoader));
      expect(skeleton.width, 100);
      expect(skeleton.height, 50);
    });

    testWidgets('SkeletonCard displays correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SkeletonCard(),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsWidgets);
    });

    testWidgets('SkeletonList displays multiple items', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 800,
              child: SkeletonList(itemCount: 5),
            ),
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsNWidgets(5));
    });

    testWidgets('SkeletonAvatar displays with correct size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonAvatar(size: 64),
          ),
        ),
      );

      final avatar = tester.widget<SkeletonLoader>(find.byType(SkeletonLoader));
      expect(avatar.width, 64);
      expect(avatar.height, 64);
    });

    testWidgets('SkeletonGrid displays in grid layout', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonGrid(
              crossAxisCount: 2,
              itemCount: 6,
            ),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('CustomRefreshIndicator Widget Tests', () {
    testWidgets('CustomRefreshIndicator displays child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {},
              child: const Center(child: Text('Test Content')),
            ),
          ),
        ),
      );

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('CustomRefreshIndicator triggers onRefresh', (tester) async {
      var refreshCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {
                refreshCalled = true;
              },
              child: ListView(
                children: const [
                  SizedBox(height: 1000, child: Text('Scrollable Content')),
                ],
              ),
            ),
          ),
        ),
      );

      // Perform pull-to-refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(refreshCalled, true);
    });
  });

  group('Vibrant Theme Tests', () {
    test('VibrantTheme has correct spacing values', () {
      expect(VibrantSpacing.xxs, 4.0);
      expect(VibrantSpacing.xs, 8.0);
      expect(VibrantSpacing.sm, 12.0);
      expect(VibrantSpacing.md, 16.0);
      expect(VibrantSpacing.lg, 24.0);
      expect(VibrantSpacing.xl, 32.0);
      expect(VibrantSpacing.xxl, 48.0);
      expect(VibrantSpacing.xxxl, 64.0);
    });

    test('VibrantRadius has correct values', () {
      expect(VibrantRadius.sm, 12.0);
      expect(VibrantRadius.md, 16.0);
      expect(VibrantRadius.lg, 20.0);
      expect(VibrantRadius.xl, 24.0);
      expect(VibrantRadius.xxl, 32.0);
      expect(VibrantRadius.full, 999.0);
    });

    test('VibrantTheme has hero gradient', () {
      final gradient = VibrantTheme.heroGradient;
      expect(gradient, isA<LinearGradient>());
    });
  });
}
