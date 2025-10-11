class LessonResponse {
  LessonResponse({required this.meta, required this.tasks});

  final Meta meta;
  final List<Task> tasks;

  factory LessonResponse.fromJson(Map<String, dynamic> json) {
    final tasksJson = (json['tasks'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => item as Map<String, dynamic>)
        .toList(growable: false);
    return LessonResponse(
      meta: Meta.fromJson(json['meta'] as Map<String, dynamic>),
      tasks: tasksJson.map(Task.fromJson).toList(growable: false),
    );
  }
}

class Meta {
  Meta({
    required this.language,
    required this.profile,
    required this.provider,
    this.model,
    this.note,
  });

  final String language;
  final String profile;
  final String provider;
  final String? model;
  final String? note;

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      language: json['language'] as String? ?? 'grc',
      profile: json['profile'] as String? ?? 'beginner',
      provider: json['provider'] as String? ?? 'echo',
      model: json['model'] as String?,
      note: json['note'] as String?,
    );
  }
}

abstract class Task {
  Task(this.type);

  final String type;

  factory Task.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?)?.toLowerCase();
    switch (type) {
      case 'alphabet':
        return AlphabetTask.fromJson(json);
      case 'match':
        return MatchTask.fromJson(json);
      case 'cloze':
        return ClozeTask.fromJson(json);
      case 'translate':
        return TranslateTask.fromJson(json);
      case 'grammar':
        return GrammarTask.fromJson(json);
      case 'listening':
        return ListeningTask.fromJson(json);
      case 'speaking':
        return SpeakingTask.fromJson(json);
      case 'wordbank':
        return WordBankTask.fromJson(json);
      case 'truefalse':
        return TrueFalseTask.fromJson(json);
      case 'multiplechoice':
        return MultipleChoiceTask.fromJson(json);
      case 'dialogue':
        return DialogueTask.fromJson(json);
      case 'conjugation':
        return ConjugationTask.fromJson(json);
      case 'declension':
        return DeclensionTask.fromJson(json);
      case 'synonym':
        return SynonymTask.fromJson(json);
      case 'contextmatch':
        return ContextMatchTask.fromJson(json);
      case 'reorder':
        return ReorderTask.fromJson(json);
      case 'dictation':
        return DictationTask.fromJson(json);
      case 'etymology':
        return EtymologyTask.fromJson(json);
      default:
        throw ArgumentError('Unknown task type: ${json['type']}');
    }
  }
}

class AlphabetTask extends Task {
  AlphabetTask({
    required this.prompt,
    required this.options,
    required this.answer,
  }) : super('alphabet');

  final String prompt;
  final List<String> options;
  final String answer;

  factory AlphabetTask.fromJson(Map<String, dynamic> json) {
    return AlphabetTask(
      prompt: json['prompt'] as String? ?? '',
      options: List<String>.from(
        json['options'] as List<dynamic>? ?? const <dynamic>[],
      ),
      answer: json['answer'] as String? ?? '',
    );
  }
}

class MatchPair {
  MatchPair({required this.grc, required this.en});

  final String grc;
  final String en;

  factory MatchPair.fromJson(Map<String, dynamic> json) {
    return MatchPair(
      grc: json['grc'] as String? ?? '',
      en: json['en'] as String? ?? '',
    );
  }
}

class MatchTask extends Task {
  MatchTask({required this.pairs}) : super('match');

  final List<MatchPair> pairs;

  factory MatchTask.fromJson(Map<String, dynamic> json) {
    final pairsJson = (json['pairs'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => MatchPair.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return MatchTask(pairs: pairsJson);
  }
}

class Blank {
  Blank({required this.surface, required this.idx});

  final String surface;
  final int idx;

  factory Blank.fromJson(Map<String, dynamic> json) {
    return Blank(
      surface: json['surface'] as String? ?? '',
      idx: (json['idx'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClozeTask extends Task {
  ClozeTask({
    required this.sourceKind,
    this.ref,
    required this.text,
    required this.blanks,
    this.options,
  }) : super('cloze');

  final String sourceKind;
  final String? ref;
  final String text;
  final List<Blank> blanks;
  final List<String>? options;

  factory ClozeTask.fromJson(Map<String, dynamic> json) {
    final blanksJson = (json['blanks'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => Blank.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final optionsJson = json['options'] == null
        ? null
        : List<String>.from(json['options'] as List<dynamic>);
    return ClozeTask(
      sourceKind: json['source_kind'] as String? ?? 'daily',
      ref: json['ref'] as String?,
      text: json['text'] as String? ?? '',
      blanks: blanksJson,
      options: optionsJson,
    );
  }
}

class TranslateTask extends Task {
  TranslateTask({
    required this.direction,
    required this.text,
    required this.rubric,
    this.sampleSolution,
  }) : super('translate');

  final String direction;
  final String text;
  final String rubric;
  final String? sampleSolution;

  factory TranslateTask.fromJson(Map<String, dynamic> json) {
    return TranslateTask(
      direction: json['direction'] as String? ?? 'grc→en',
      text: json['text'] as String? ?? '',
      rubric: json['rubric'] as String? ?? '',
      sampleSolution: json['sample'] as String?,
    );
  }
}

class GrammarTask extends Task {
  GrammarTask({
    required this.sentence,
    required this.isCorrect,
    this.errorExplanation,
  }) : super('grammar');

  final String sentence;
  final bool isCorrect;
  final String? errorExplanation;

  factory GrammarTask.fromJson(Map<String, dynamic> json) {
    return GrammarTask(
      sentence: json['sentence'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
      errorExplanation: json['error_explanation'] as String?,
    );
  }
}

class ListeningTask extends Task {
  ListeningTask({
    this.audioUrl,
    required this.audioText,
    required this.options,
    required this.answer,
  }) : super('listening');

  final String? audioUrl;
  final String audioText;
  final List<String> options;
  final String answer;

  factory ListeningTask.fromJson(Map<String, dynamic> json) {
    return ListeningTask(
      audioUrl: json['audio_url'] as String?,
      audioText: json['audio_text'] as String? ?? '',
      options: List<String>.from(
        json['options'] as List<dynamic>? ?? const <dynamic>[],
      ),
      answer: json['answer'] as String? ?? '',
    );
  }
}

class SpeakingTask extends Task {
  SpeakingTask({
    required this.prompt,
    required this.targetText,
    this.phoneticGuide,
  }) : super('speaking');

  final String prompt;
  final String targetText;
  final String? phoneticGuide;

  factory SpeakingTask.fromJson(Map<String, dynamic> json) {
    return SpeakingTask(
      prompt: json['prompt'] as String? ?? '',
      targetText: json['target_text'] as String? ?? '',
      phoneticGuide: json['phonetic_guide'] as String?,
    );
  }
}

class WordBankTask extends Task {
  WordBankTask({
    required this.words,
    required this.correctOrder,
    required this.translation,
  }) : super('wordbank');

  final List<String> words;
  final List<int> correctOrder;
  final String translation;

  factory WordBankTask.fromJson(Map<String, dynamic> json) {
    return WordBankTask(
      words: List<String>.from(
        json['words'] as List<dynamic>? ?? const <dynamic>[],
      ),
      correctOrder: List<int>.from(
        json['correct_order'] as List<dynamic>? ?? const <dynamic>[],
      ),
      translation: json['translation'] as String? ?? '',
    );
  }
}

class TrueFalseTask extends Task {
  TrueFalseTask({
    required this.statement,
    required this.isTrue,
    required this.explanation,
  }) : super('truefalse');

  final String statement;
  final bool isTrue;
  final String explanation;

  factory TrueFalseTask.fromJson(Map<String, dynamic> json) {
    return TrueFalseTask(
      statement: json['statement'] as String? ?? '',
      isTrue: json['is_true'] as bool? ?? false,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class MultipleChoiceTask extends Task {
  MultipleChoiceTask({
    required this.question,
    this.context,
    required this.options,
    required this.answerIndex,
  }) : super('multiplechoice');

  final String question;
  final String? context;
  final List<String> options;
  final int answerIndex;

  factory MultipleChoiceTask.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceTask(
      question: json['question'] as String? ?? '',
      context: json['context'] as String?,
      options: List<String>.from(
        json['options'] as List<dynamic>? ?? const <dynamic>[],
      ),
      answerIndex: (json['answer_index'] as num?)?.toInt() ?? 0,
    );
  }
}

class DialogueLine {
  DialogueLine({required this.speaker, required this.text});

  final String speaker;
  final String text;

  factory DialogueLine.fromJson(Map<String, dynamic> json) {
    return DialogueLine(
      speaker: json['speaker'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

class DialogueTask extends Task {
  DialogueTask({
    required this.lines,
    required this.missingIndex,
    required this.options,
    required this.answer,
  }) : super('dialogue');

  final List<DialogueLine> lines;
  final int missingIndex;
  final List<String> options;
  final String answer;

  factory DialogueTask.fromJson(Map<String, dynamic> json) {
    return DialogueTask(
      lines: (json['lines'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => DialogueLine.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      missingIndex: (json['missing_index'] as num?)?.toInt() ?? 0,
      options: List<String>.from(
        json['options'] as List<dynamic>? ?? const <dynamic>[],
      ),
      answer: json['answer'] as String? ?? '',
    );
  }
}

class ConjugationTask extends Task {
  ConjugationTask({
    required this.verbInfinitive,
    required this.verbMeaning,
    required this.person,
    required this.tense,
    required this.answer,
  }) : super('conjugation');

  final String verbInfinitive;
  final String verbMeaning;
  final String person;
  final String tense;
  final String answer;

  factory ConjugationTask.fromJson(Map<String, dynamic> json) {
    return ConjugationTask(
      verbInfinitive: json['verb_infinitive'] as String? ?? '',
      verbMeaning: json['verb_meaning'] as String? ?? '',
      person: json['person'] as String? ?? '',
      tense: json['tense'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class DeclensionTask extends Task {
  DeclensionTask({
    required this.word,
    required this.wordMeaning,
    required this.caseType,
    required this.number,
    required this.answer,
  }) : super('declension');

  final String word;
  final String wordMeaning;
  final String caseType;
  final String number;
  final String answer;

  factory DeclensionTask.fromJson(Map<String, dynamic> json) {
    return DeclensionTask(
      word: json['word'] as String? ?? '',
      wordMeaning: json['word_meaning'] as String? ?? '',
      caseType: json['case'] as String? ?? '',
      number: json['number'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
    );
  }
}

class SynonymTask extends Task {
  SynonymTask({
    required this.word,
    required this.taskType,
    required this.options,
    required this.answer,
  }) : super('synonym');

  final String word;
  final String taskType; // 'synonym' or 'antonym'
  final List<String> options;
  final String answer;

  factory SynonymTask.fromJson(Map<String, dynamic> json) {
    return SynonymTask(
      word: json['word'] as String? ?? '',
      taskType: json['task_type'] as String? ?? 'synonym',
      options: List<String>.from(
        json['options'] as List<dynamic>? ?? const <dynamic>[],
      ),
      answer: json['answer'] as String? ?? '',
    );
  }
}

class ContextMatchTask extends Task {
  ContextMatchTask({
    required this.sentence,
    this.contextHint,
    required this.options,
    required this.answer,
  }) : super('contextmatch');

  final String sentence;
  final String? contextHint;
  final List<String> options;
  final String answer;

  factory ContextMatchTask.fromJson(Map<String, dynamic> json) {
    return ContextMatchTask(
      sentence: json['sentence'] as String? ?? '',
      contextHint: json['context_hint'] as String?,
      options: List<String>.from(
        json['options'] as List<dynamic>? ?? const <dynamic>[],
      ),
      answer: json['answer'] as String? ?? '',
    );
  }
}

class ReorderTask extends Task {
  ReorderTask({
    required this.fragments,
    required this.correctOrder,
    required this.translation,
  }) : super('reorder');

  final List<String> fragments;
  final List<int> correctOrder;
  final String translation;

  factory ReorderTask.fromJson(Map<String, dynamic> json) {
    return ReorderTask(
      fragments: List<String>.from(
        json['fragments'] as List<dynamic>? ?? const <dynamic>[],
      ),
      correctOrder: List<int>.from(
        json['correct_order'] as List<dynamic>? ?? const <dynamic>[],
      ),
      translation: json['translation'] as String? ?? '',
    );
  }
}

class DictationTask extends Task {
  DictationTask({
    this.audioUrl,
    required this.targetText,
    this.hint,
  }) : super('dictation');

  final String? audioUrl;
  final String targetText;
  final String? hint;

  factory DictationTask.fromJson(Map<String, dynamic> json) {
    return DictationTask(
      audioUrl: json['audio_url'] as String?,
      targetText: json['target_text'] as String? ?? '',
      hint: json['hint'] as String?,
    );
  }
}

class EtymologyTask extends Task {
  EtymologyTask({
    required this.question,
    required this.word,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  }) : super('etymology');

  final String question;
  final String word;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  factory EtymologyTask.fromJson(Map<String, dynamic> json) {
    return EtymologyTask(
      question: json['question'] as String? ?? '',
      word: json['word'] as String? ?? '',
      options: List<String>.from(
        json['options'] as List<dynamic>? ?? const <dynamic>[],
      ),
      answerIndex: (json['answer_index'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String? ?? '',
    );
  }
}
