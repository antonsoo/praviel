library;

/// Vocabulary models for intelligent vocabulary tracking and review

/// Proficiency levels based on vocabulary size
enum ProficiencyLevel {
  absoluteBeginner,
  beginner,
  elementary,
  intermediate,
  upperIntermediate,
  advanced,
  proficient,
  expert;

  String get displayName => switch (this) {
        absoluteBeginner => 'Absolute Beginner',
        beginner => 'Beginner',
        elementary => 'Elementary',
        intermediate => 'Intermediate',
        upperIntermediate => 'Upper Intermediate',
        advanced => 'Advanced',
        proficient => 'Proficient',
        expert => 'Expert',
      };

  String toJson() => switch (this) {
        absoluteBeginner => 'absolute_beginner',
        beginner => 'beginner',
        elementary => 'elementary',
        intermediate => 'intermediate',
        upperIntermediate => 'upper_intermediate',
        advanced => 'advanced',
        proficient => 'proficient',
        expert => 'expert',
      };

  static ProficiencyLevel fromJson(String value) => switch (value) {
        'absolute_beginner' => absoluteBeginner,
        'beginner' => beginner,
        'elementary' => elementary,
        'intermediate' => intermediate,
        'upper_intermediate' => upperIntermediate,
        'advanced' => advanced,
        'proficient' => proficient,
        'expert' => expert,
        _ => beginner,
      };
}

/// Vocabulary difficulty levels
enum VocabularyDifficulty {
  coreBasic,
  common,
  intermediate,
  advanced,
  specialized,
  rare;

  String get displayName => switch (this) {
        coreBasic => 'Core Basic',
        common => 'Common',
        intermediate => 'Intermediate',
        advanced => 'Advanced',
        specialized => 'Specialized',
        rare => 'Rare',
      };

  String toJson() => switch (this) {
        coreBasic => 'core_basic',
        common => 'common',
        intermediate => 'intermediate',
        advanced => 'advanced',
        specialized => 'specialized',
        rare => 'rare',
      };

  static VocabularyDifficulty fromJson(String value) => switch (value) {
        'core_basic' => coreBasic,
        'common' => common,
        'intermediate' => intermediate,
        'advanced' => advanced,
        'specialized' => specialized,
        'rare' => rare,
        _ => common,
      };
}

/// Mastery levels for vocabulary tracking
enum MasteryLevel {
  newWord,
  learning,
  familiar,
  known,
  mastered;

  String get displayName => switch (this) {
        newWord => 'New',
        learning => 'Learning',
        familiar => 'Familiar',
        known => 'Known',
        mastered => 'Mastered',
      };

  String toJson() => switch (this) {
        newWord => 'new',
        learning => 'learning',
        familiar => 'familiar',
        known => 'known',
        mastered => 'mastered',
      };

  static MasteryLevel fromJson(String value) => switch (value) {
        'new' => newWord,
        'learning' => learning,
        'familiar' => familiar,
        'known' => known,
        'mastered' => mastered,
        _ => newWord,
      };
}

class VocabularyWord {
  const VocabularyWord({
    required this.word,
    required this.translation,
    this.transliteration,
    this.partOfSpeech,
    required this.difficulty,
    this.exampleSentence,
    this.exampleTranslation,
    this.notes,
  });

  final String word;
  final String translation;
  final String? transliteration;
  final String? partOfSpeech;
  final VocabularyDifficulty difficulty;
  final String? exampleSentence;
  final String? exampleTranslation;
  final List<String>? notes;

  factory VocabularyWord.fromJson(Map<String, dynamic> json) {
    return VocabularyWord(
      word: json['word'] as String,
      translation: json['translation'] as String,
      transliteration: json['transliteration'] as String?,
      partOfSpeech: json['part_of_speech'] as String?,
      difficulty: VocabularyDifficulty.fromJson(json['difficulty'] as String),
      exampleSentence: json['example_sentence'] as String?,
      exampleTranslation: json['example_translation'] as String?,
      notes: (json['notes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'translation': translation,
      if (transliteration != null) 'transliteration': transliteration,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      'difficulty': difficulty.toJson(),
      if (exampleSentence != null) 'example_sentence': exampleSentence,
      if (exampleTranslation != null) 'example_translation': exampleTranslation,
      if (notes != null) 'notes': notes,
    };
  }
}

class VocabularyGenerationRequest {
  const VocabularyGenerationRequest({
    required this.languageCode,
    required this.proficiencyLevel,
    this.difficulty,
    this.count,
    this.category,
    this.provider,
    this.model,
  });

  final String languageCode;
  final ProficiencyLevel proficiencyLevel;
  final VocabularyDifficulty? difficulty;
  final int? count;
  final String? category;
  final String? provider;
  final String? model;

  Map<String, dynamic> toJson() {
    return {
      'language_code': languageCode,
      'proficiency_level': proficiencyLevel.toJson(),
      if (difficulty != null) 'difficulty': difficulty!.toJson(),
      if (count != null) 'count': count,
      if (category != null) 'category': category,
      if (provider != null) 'provider': provider,
      if (model != null) 'model': model,
    };
  }
}

class VocabularyGenerationResponse {
  const VocabularyGenerationResponse({
    required this.words,
    required this.languageCode,
    required this.proficiencyLevel,
    required this.count,
  });

  final List<VocabularyWord> words;
  final String languageCode;
  final ProficiencyLevel proficiencyLevel;
  final int count;

  factory VocabularyGenerationResponse.fromJson(Map<String, dynamic> json) {
    return VocabularyGenerationResponse(
      words: (json['words'] as List<dynamic>)
          .map((e) => VocabularyWord.fromJson(e as Map<String, dynamic>))
          .toList(),
      languageCode: json['language_code'] as String,
      proficiencyLevel:
          ProficiencyLevel.fromJson(json['proficiency_level'] as String),
      count: json['count'] as int,
    );
  }
}

class VocabularyInteractionRequest {
  const VocabularyInteractionRequest({
    required this.userId,
    required this.languageCode,
    required this.word,
    required this.correct,
    this.responseTimeMs,
  });

  final int userId;
  final String languageCode;
  final String word;
  final bool correct;
  final int? responseTimeMs;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language_code': languageCode,
      'word': word,
      'correct': correct,
      if (responseTimeMs != null) 'response_time_ms': responseTimeMs,
    };
  }
}

class VocabularyInteractionResponse {
  const VocabularyInteractionResponse({
    required this.word,
    required this.masteryLevel,
    required this.nextReview,
    required this.totalEncounters,
    required this.accuracy,
  });

  final String word;
  final String masteryLevel;
  final DateTime nextReview;
  final int totalEncounters;
  final double accuracy;

  factory VocabularyInteractionResponse.fromJson(Map<String, dynamic> json) {
    return VocabularyInteractionResponse(
      word: json['word'] as String,
      masteryLevel: json['mastery_level'] as String,
      nextReview: DateTime.parse(json['next_review'] as String),
      totalEncounters: json['total_encounters'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }
}

class VocabularyReviewRequest {
  const VocabularyReviewRequest({
    required this.userId,
    required this.languageCode,
    this.count = 20,
  });

  final int userId;
  final String languageCode;
  final int count;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'language_code': languageCode,
      'count': count,
    };
  }
}

class VocabularyReviewItem {
  const VocabularyReviewItem({
    required this.word,
    required this.wordNormalized,
    required this.masteryLevel,
    required this.timesSeen,
    required this.accuracy,
    this.lastSeen,
  });

  final String word;
  final String wordNormalized;
  final String masteryLevel;
  final int timesSeen;
  final double accuracy;
  final DateTime? lastSeen;

  factory VocabularyReviewItem.fromJson(Map<String, dynamic> json) {
    return VocabularyReviewItem(
      word: json['word'] as String,
      wordNormalized: json['word_normalized'] as String,
      masteryLevel: json['mastery_level'] as String,
      timesSeen: json['times_seen'] as int,
      accuracy: (json['accuracy'] as num).toDouble(),
      lastSeen: json['last_seen'] != null
          ? DateTime.parse(json['last_seen'] as String)
          : null,
    );
  }
}

class VocabularyReviewResponse {
  const VocabularyReviewResponse({
    required this.items,
    required this.totalDue,
    required this.userId,
    required this.languageCode,
  });

  final List<VocabularyReviewItem> items;
  final int totalDue;
  final int userId;
  final String languageCode;

  factory VocabularyReviewResponse.fromJson(Map<String, dynamic> json) {
    return VocabularyReviewResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => VocabularyReviewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDue: json['total_due'] as int,
      userId: json['user_id'] as int,
      languageCode: json['language_code'] as String,
    );
  }
}
