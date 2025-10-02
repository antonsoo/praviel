import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  group('Backend Integration Tests', () {
    test('Text-range endpoint returns Greek vocabulary from specific lines',
        () async {
      final response = await http.post(
        Uri.parse('$baseUrl/lesson/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': 'grc',
          'text_range': {'ref_start': 'Il.1.20', 'ref_end': 'Il.1.30'},
          'exercise_types': ['match', 'cloze'],
          'provider': 'echo',
        }),
      );

      expect(response.statusCode, 200,
          reason: 'API should return 200 OK for text-range request');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      expect(data['tasks'], isNotEmpty,
          reason: 'Response should contain at least one task');

      // Verify contains Greek text (Unicode range 0x0370-0x03FF)
      final taskJson = jsonEncode(data['tasks']);
      final containsGreek = taskJson.codeUnits
          .any((code) => code >= 0x0370 && code <= 0x03FF);
      expect(containsGreek, isTrue,
          reason: 'Tasks should contain Greek characters');

      // Verify specific vocabulary from lines 1.20-1.30
      final expectedPhrases = [
        'ἀλλʼ οὐκ Ἀτρεΐδῃ', // from line 1.24
        'ἔνθʼ ἄλλοι μὲν', // from line 1.22
        'ἁζόμενοι', // from line 1.21
      ];

      var foundCount = 0;
      for (final phrase in expectedPhrases) {
        if (taskJson.contains(phrase)) {
          foundCount++;
        }
      }
      expect(foundCount, greaterThan(0),
          reason:
              'Should contain at least one phrase from Iliad 1.20-1.30');
    });

    test('Register modes produce different vocabulary', () async {
      final literaryResponse = await http.post(
        Uri.parse('$baseUrl/lesson/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': 'grc',
          'register': 'literary',
          'exercise_types': ['match'],
          'provider': 'echo',
          'sources': ['daily'],
        }),
      );

      final colloquialResponse = await http.post(
        Uri.parse('$baseUrl/lesson/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'language': 'grc',
          'register': 'colloquial',
          'exercise_types': ['match'],
          'provider': 'echo',
          'sources': ['daily'],
        }),
      );

      expect(literaryResponse.statusCode, 200,
          reason: 'Literary register should return 200 OK');
      expect(colloquialResponse.statusCode, 200,
          reason: 'Colloquial register should return 200 OK');

      final literaryData =
          jsonDecode(literaryResponse.body) as Map<String, dynamic>;
      final colloquialData =
          jsonDecode(colloquialResponse.body) as Map<String, dynamic>;

      expect(literaryData['tasks'], isNotEmpty,
          reason: 'Literary tasks should not be empty');
      expect(colloquialData['tasks'], isNotEmpty,
          reason: 'Colloquial tasks should not be empty');

      // Extract vocabulary from responses
      final literaryJson = jsonEncode(literaryData['tasks']);
      final colloquialJson = jsonEncode(colloquialData['tasks']);

      // Vocabularies should be different
      expect(literaryJson != colloquialJson, isTrue,
          reason:
              'Literary and colloquial registers should produce different vocabulary');

      // Check for expected literary phrases
      final literaryIndicators = ['εὖ ἔχω', 'δέκα', 'χαῖρε'];
      final hasLiteraryVocab = literaryIndicators
          .any((phrase) => literaryJson.contains(phrase));
      expect(hasLiteraryVocab, isTrue,
          reason: 'Literary response should contain formal vocabulary');

      // Check for expected colloquial phrases
      final colloquialIndicators = [
        'πωλεῖς',
        'θέλω',
        'οἶνον',
        'φίλε'
      ];
      final hasColloquialVocab = colloquialIndicators
          .any((phrase) => colloquialJson.contains(phrase));
      expect(hasColloquialVocab, isTrue,
          reason: 'Colloquial response should contain everyday vocabulary');
    });

    test('Health endpoint confirms lessons feature enabled', () async {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      expect(response.statusCode, 200,
          reason: 'Health endpoint should return 200 OK');

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      expect(data['status'], 'ok', reason: 'Server status should be ok');
      expect(data['features'], isNotNull,
          reason: 'Features object should exist');

      final features = data['features'] as Map<String, dynamic>;
      expect(features['lessons'], isTrue,
          reason: 'Lessons feature should be enabled');
    });
  });
}
