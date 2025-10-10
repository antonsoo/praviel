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
