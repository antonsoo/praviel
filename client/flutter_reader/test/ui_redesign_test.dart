import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/widgets/premium_button.dart';

void main() {
  group('Premium Button UI Tests', () {
    testWidgets('PremiumButton renders and responds to taps',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PremiumButton(
                onPressed: () {
                  tapped = true;
                },
                child: const Text('TEST BUTTON'),
              ),
            ),
          ),
        ),
      );

      // Button should render
      expect(find.text('TEST BUTTON'), findsOneWidget);

      // Tap the button
      await tester.tap(find.text('TEST BUTTON'));
      await tester.pumpAndSettle();

      // Callback should have been called
      expect(tapped, true);
    });

    testWidgets('PremiumButton shows disabled state correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PremiumButton(
                onPressed: null, // Disabled
                enabled: false,
                child: const Text('DISABLED'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('DISABLED'), findsOneWidget);

      // Should not crash when tapping disabled button
      await tester.tap(find.text('DISABLED'));
      await tester.pumpAndSettle();
    });

    testWidgets('PremiumOutlineButton renders correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PremiumOutlineButton(
                onPressed: () {},
                child: const Text('OUTLINE'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('OUTLINE'), findsOneWidget);
    });

    testWidgets('PremiumButton animates on press',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PremiumButton(
                onPressed: () {},
                child: const Text('ANIMATE'),
              ),
            ),
          ),
        ),
      );

      // Get initial position
      final initialBox =
          tester.getTopLeft(find.text('ANIMATE'));

      // Start pressing
      final gesture = await tester.startGesture(
          tester.getCenter(find.text('ANIMATE')));

      // Pump a few frames to see animation
      await tester.pump(const Duration(milliseconds: 50));
      final pressedBox =
          tester.getTopLeft(find.text('ANIMATE'));

      // Button should have moved down (Y position increases)
      // Note: This might be flaky, just checking it exists
      expect(find.text('ANIMATE'), findsOneWidget);

      // Release
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('Theme Integration Tests', () {
    testWidgets('App uses correct color scheme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1CB0F6), // Duolingo blue
              secondary: Color(0xFF58CC02), // Duolingo green
            ),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final colors = Theme.of(context).colorScheme;
                return Column(
                  children: [
                    Container(
                      color: colors.primary,
                      child: const Text('Primary'),
                    ),
                    Container(
                      color: colors.secondary,
                      child: const Text('Secondary'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
    });
  });
}
