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

    // Verify sections visible above the fold
    expect(find.text('One-Time Donations'), findsOneWidget);
    expect(find.text('Recurring Support'), findsOneWidget);

    // Note: 'Transparent Funding' section is conditionally shown only when
    // Open Collective is configured (not a placeholder). Since it's currently
    // a placeholder, this section won't appear.

    // Scroll down to make the crypto section visible (ListView uses lazy rendering)
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // Verify the cryptocurrency section
    expect(find.text('Cryptocurrency Donations'), findsOneWidget);
  });
}
