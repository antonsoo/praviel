import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ancient_languages_app/services/adaptive_difficulty_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adaptive Difficulty Integration Tests', () {
    late AdaptiveDifficultyService service;

    setUp(() async {
      service = AdaptiveDifficultyService();
      await service.load();
    });

    test('Service loads successfully', () {
      expect(service.isLoaded, true);
      expect(service.currentDifficulty, 0.3); // Default beginner level
    });

    test('Records performance and adapts difficulty upward', () async {
      // Simulate user getting 10 exercises correct quickly
      for (int i = 0; i < 10; i++) {
        await service.recordPerformance(
          correct: true,
          timeSpent: 8.5, // Fast
          category: SkillCategory.vocabulary,
          exerciseType: 'ClozeTask',
        );
      }

      // Difficulty should increase
      expect(service.currentDifficulty, greaterThan(0.3));
      debugPrint('Difficulty after 10 correct: ${service.currentDifficulty}');
    });

    test('Records performance and adapts difficulty downward', () async {
      // Set initial difficulty higher
      await service.recordPerformance(
        correct: true,
        timeSpent: 8.0,
        category: SkillCategory.vocabulary,
        exerciseType: 'ClozeTask',
      );

      // Now simulate user struggling (getting wrong answers slowly)
      for (int i = 0; i < 10; i++) {
        await service.recordPerformance(
          correct: false,
          timeSpent: 25.0, // Slow
          category: SkillCategory.vocabulary,
          exerciseType: 'ClozeTask',
        );
      }

      // Difficulty should decrease from initial
      expect(service.currentDifficulty, lessThan(0.35));
      debugPrint('Difficulty after 10 wrong: ${service.currentDifficulty}');
    });

    test('Provides insights after sufficient data', () async {
      // Record 10 exercises
      for (int i = 0; i < 10; i++) {
        await service.recordPerformance(
          correct: i % 2 == 0, // 50% accuracy
          timeSpent: 15.0,
          category: SkillCategory.vocabulary,
          exerciseType: 'ClozeTask',
        );
      }

      final insights = service.getInsights();
      expect(insights.totalExercises, 10);
      expect(insights.overallAccuracy, 0.5);
      expect(insights.strongestSkill, isNotNull);
    });

    test('Different skill categories tracked independently', () async {
      // Good at vocabulary
      for (int i = 0; i < 5; i++) {
        await service.recordPerformance(
          correct: true,
          timeSpent: 10.0,
          category: SkillCategory.vocabulary,
          exerciseType: 'ClozeTask',
        );
      }

      // Bad at grammar
      for (int i = 0; i < 5; i++) {
        await service.recordPerformance(
          correct: false,
          timeSpent: 20.0,
          category: SkillCategory.grammar,
          exerciseType: 'GrammarTask',
        );
      }

      final vocabLevel = service.getSkillLevel(SkillCategory.vocabulary);
      final grammarLevel = service.getSkillLevel(SkillCategory.grammar);

      expect(vocabLevel, greaterThan(grammarLevel));
      debugPrint('Vocabulary level: $vocabLevel, Grammar level: $grammarLevel');
    });
  });
}
