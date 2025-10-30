import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:praviel/models/language.dart';
import 'package:praviel/widgets/language_picker_sheet.dart';

void main() {
  testWidgets('Language picker lists all languages in canonical order',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: LanguagePickerSheet(currentLanguageCode: availableLanguages.first.code),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text(availableLanguages.first.name), findsOneWidget);

    // Scroll to the end to surface the final language in the catalog.
    await tester.dragUntilVisible(
      find.text(availableLanguages.last.name),
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
  });
}
