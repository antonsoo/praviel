import 'dart:ui';

import 'package:flutter_reader/api/reader_api.dart';
import 'package:flutter_reader/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helper.dart';

class _FakeAnalysisController extends AnalysisController {
  _FakeAnalysisController(this._result);

  final AnalyzeResult _result;

  @override
  Future<AnalyzeResult?> build() async => _result;
}

void main() {
  setUpAll(() {
    configureGoogleFontsForTest();
  });

  testWidgets(
    'reader home golden',
    (tester) async {
      final result = AnalyzeResult(
        tokens: const [
          AnalyzeToken(
            text: 'Μῆνιν',
            start: 0,
            end: 5,
            lemma: 'μῆνις',
            morph: 'n-s---fa-',
          ),
          AnalyzeToken(
            text: 'ἄειδε',
            start: 6,
            end: 11,
            lemma: 'ἀείδω',
            morph: 'v2spma---',
          ),
        ],
        retrieval: const [],
        lexicon: const [
          LexiconEntry(
            lemma: 'μῆνις',
            gloss: 'wrath, anger (of the gods)',
            citation: 'LSJ s.v. μῆνις',
          ),
          LexiconEntry(
            lemma: 'ἀείδω',
            gloss: 'to sing, chant',
            citation: 'LSJ s.v. ἀείδω',
          ),
        ],
        grammar: const [
          GrammarEntry(anchor: '§123', title: 'Genitive of Cause', score: 0.92),
          GrammarEntry(
            anchor: '§166',
            title: 'Imperatives of -μι verbs',
            score: 0.81,
          ),
        ],
      );

      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analysisControllerProvider.overrideWith(
              () => _FakeAnalysisController(result),
            ),
          ],
          child: const ReaderApp(),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(ReaderHomePage),
        matchesGoldenFile('reader_home.png'),
      );
    },
    skip: true,
  ); // Google Fonts needs font variants not in assets (NotoSerif-SemiBold, Inter-Bold, Inter-SemiBold)
}
