import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_reader/main.dart';

void main() {
  testWidgets('renders analyze action', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ReaderApp()));
    expect(find.text('Analyze'), findsOneWidget);
    expect(find.textContaining('Greek text'), findsOneWidget);
  });
}
