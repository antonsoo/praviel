import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_reader/api/reader_api.dart';
import 'package:flutter_reader/main.dart';

class _InMemoryStorage implements SecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }
}

void main() {
  testWidgets('renders analyze action', (tester) async {
    final storage = _InMemoryStorage();
    final api = ReaderApi(
      baseUrl: 'http://localhost:8000/',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'tokens': const [],
            'retrieval': const [],
            'lexicon': const [],
            'grammar': const [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(api.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(apiBaseUrl: 'http://localhost:8000/'),
          ),
          secureStorageProvider.overrideWithValue(storage),
          byokControllerProvider.overrideWith(
            (ref) => ByokController(
              storage: storage,
              initial: const ByokState(apiKey: null, enabled: false),
            ),
          ),
          readerApiProvider.overrideWithValue(api),
        ],
        child: const ReaderApp(),
      ),
    );

    expect(find.text('Analyze'), findsOneWidget);
    expect(find.textContaining('Greek text'), findsOneWidget);
  });
}
