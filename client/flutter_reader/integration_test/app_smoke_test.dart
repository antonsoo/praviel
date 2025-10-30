import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:praviel/main.dart' as app;
import 'package:praviel/main.dart' show ReaderHomePage;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and shows the home shell', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.byType(ReaderHomePage), findsOneWidget);
    expect(find.text('Lessons'), findsWidgets);
  });
}
