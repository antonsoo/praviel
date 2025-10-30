import '../models/lesson.dart';

/// Provides contextual coaching hints for lesson exercises.
class LessonHintResolver {
  const LessonHintResolver._();

  static String? hintForTask(Task task) {
    if (task is AlphabetTask) {
      return 'Focus on the glyph shape. Compare the strokes with nearby options before committing.';
    }
    if (task is MatchTask) {
      return 'Look for shared stems or endings between the native word and the gloss.';
    }
    if (task is ClozeTask) {
      return 'Read the whole sentence aloud. Context usually suggests the missing case or tense.';
    }
    if (task is TranslateTask) {
      return task.direction == 'en->native'
          ? 'Match each English word to a native equivalent and mind agreement'
          : 'Scan for subject endings first, then piece together modifiers.';
    }
    if (task is GrammarTask) {
      return 'Decide whether form and function align. Case endings often expose the error.';
    }
    if (task is ListeningTask) {
      return 'Replay and jot down syllables you catch before picking the option.';
    }
    if (task is SpeakingTask) {
      return 'Break the prompt into syllables and speak slowly; accuracy beats speed.';
    }
    if (task is WordBankTask) {
      return 'Anchor the verb first, then arrange nouns/adjectives around it in natural order.';
    }
    if (task is TrueFalseTask) {
      return 'Check the key grammatical feature (case, tense, particle) before answering.';
    }
    if (task is MultipleChoiceTask) {
      return 'Eliminate answers that clash with the tense or case in the prompt.';
    }
    if (task is DialogueTask) {
      return 'Skim both speakers for context clues—greetings and farewells often pair together.';
    }
    if (task is ConjugationTask) {
      return 'Identify person/number first, then apply the appropriate stem ending.';
    }
    if (task is DeclensionTask) {
      return 'Match the requested case to its role (subject, object, etc.) before inflecting.';
    }
    if (task is SynonymTask) {
      return 'Think about the semantic field—the odd option usually belongs to another context.';
    }
    if (task is ContextMatchTask) {
      return 'Read the full sentence: surrounding adjectives or particles normally hint at meaning.';
    }
    if (task is ReorderTask) {
      return 'Locate the finite verb, then build the sentence outward from it.';
    }
    if (task is DictationTask) {
      return 'Listen for syllable rhythm. Writing pauses as slashes can help segment the phrase.';
    }
    if (task is EtymologyTask) {
      return 'Spot shared roots or suffixes—cognates often hide in the beginning or end of the word.';
    }
    if (task is ReadingComprehensionTask) {
      return 'Skim for key names and particles. Answer options usually restate part of the passage.';
    }
    return null;
  }
}
