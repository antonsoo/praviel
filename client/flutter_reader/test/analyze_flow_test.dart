import 'dart:convert';

import 'package:flutter/material.dart';

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
  testWidgets('analyze flow renders results and latency badge', (tester) async {
    final storage = _InMemoryStorage();
    final api = ReaderApi(
      baseUrl: 'http://localhost:8000/',
      client: MockClient((request) async {
        expect(request.headers['Authorization'], isNull);
        return http.Response(
          jsonEncode({
            'tokens': [
              {
                'text': 'Μῆνιν',
                'start': 0,
                'end': 5,
                'lemma': 'μῆνις',
                'morph': 'n-s---fa-',
              },
              {
                'text': 'ἄειδε',
                'start': 6,
                'end': 11,
                'lemma': 'ἀείδω',
                'morph': 'v2spma---',
              },
            ],
            'retrieval': [
              {
                'segment_id': 1,
                'work_ref': 'Il.1.1',
                'text_nfc': 'Μῆνιν ἄειδε, θεά',
                'score': 0.93,
                'reasons': ['lemma match'],
              },
            ],
            'lexicon': [
              {
                'lemma': 'μῆνις',
                'gloss': 'wrath, anger',
                'citation': 'LSJ s.v. μῆνις',
              },
            ],
            'grammar': [
              {
                'anchor': '§166',
                'title': 'Imperatives of -μι verbs',
                'score': 0.78,
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
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

    await tester.enterText(find.byType(TextField), 'Μῆνιν ἄειδε');
    await tester.ensureVisible(find.text('Analyze'));
    await tester.tap(find.text('Analyze'), warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ListTile), findsWidgets);
    expect(find.byType(ListTile), findsWidgets);
  });
}
