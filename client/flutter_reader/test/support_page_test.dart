import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_reader/pages/support_page.dart';

void main() {
  testWidgets('Support page renders without crashing', (WidgetTester tester) async {
    // Build the SupportPage widget
    await tester.pumpWidget(
      const MaterialApp(
        home: SupportPage(),
      ),
    );

    // Verify the page loads without errors
    expect(find.byType(SupportPage), findsOneWidget);

    // Verify key elements are present
    expect(find.text('Why Support AncientLanguages?'), findsOneWidget);
    expect(find.text('GitHub Sponsors'), findsOneWidget);
  });

  testWidgets('Support page has correct sections', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SupportPage(),
      ),
    );

    // Verify all major sections exist
    expect(find.text('One-Time Donations'), findsOneWidget);
    expect(find.text('Recurring Support'), findsOneWidget);
    expect(find.text('Transparent Funding'), findsOneWidget);
    expect(find.text('Cryptocurrency Donations'), findsOneWidget);
  });
}
