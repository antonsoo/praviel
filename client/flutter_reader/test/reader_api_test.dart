import 'dart:convert';

import 'package:flutter_reader/api/reader_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('AnalyzeResult.fromJson decodes optional sections', () {
    final payload = {
      'tokens': [
        {
          'text': 'Μῆνιν',
          'start': 0,
          'end': 5,
          'lemma': 'μῆνις',
          'morph': 'n-s---fa-',
        },
      ],
      'retrieval': [
        {
          'segment_id': 42,
          'work_ref': 'Il.1.1',
          'text_nfc': 'Μῆνιν ἄειδε, θεά,',
          'score': 0.91,
          'reasons': ['lemma match'],
        },
      ],
      'lexicon': [
        {
          'lemma': 'μῆνις',
          'gloss': 'anger, wrath',
          'citation': 'LSJ s.v. μῆνις',
        },
      ],
      'grammar': [
        {
          'anchor': '§123',
          'title': 'Genitive of Cause',
          'score': 0.72,
        },
      ],
    };

    final result = AnalyzeResult.fromJson(payload);
    expect(result.tokens, hasLength(1));
    expect(result.lexicon.single.gloss, 'anger, wrath');
    expect(result.grammar.single.anchor, '§123');
  });

  test('ReaderApi attaches Authorization header when BYOK is enabled', () async {
    final capturedHeaders = <String, String>{};
    final api = ReaderApi(
      baseUrl: 'http://localhost:8000/',
      client: MockClient((request) async {
        capturedHeaders.addAll(request.headers);
        return http.Response(
          jsonEncode({
            'tokens': [],
            'retrieval': [],
            'lexicon': [],
            'grammar': [],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    await api.analyze('μῆνιν', apiKey: 'sk-test', lsj: true);
    expect(capturedHeaders['Authorization'], 'Bearer sk-test');
    await api.close();
  });
}
