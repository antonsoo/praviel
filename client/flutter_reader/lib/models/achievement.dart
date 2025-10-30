import 'package:flutter/material.dart';

/// Achievement model for gamification
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requirement,
    this.isUnlocked = false,
    this.unlockedAt,
    this.progress = 0,
    this.maxProgress = 1,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String requirement;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final int progress;
  final int maxProgress;

  Achievement copyWith({
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? progress,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      icon: icon,
      requirement: requirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progress: progress ?? this.progress,
      maxProgress: maxProgress,
    );
  }

  double get progressPercentage =>
      maxProgress > 0 ? (progress / maxProgress).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'progress': progress,
    };
  }

  factory Achievement.fromJson(
    Map<String, dynamic> json,
    Achievement template,
  ) {
    return template.copyWith(
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      progress: json['progress'] as int? ?? 0,
    );
  }
}

/// Predefined achievements
class Achievements {
  static const firstWord = Achievement(
    id: 'first_word',
    title: 'First Steps',
    description: 'Complete your first exercise',
    icon: Icons.star_rounded,
    requirement: 'Complete 1 exercise',
    maxProgress: 1,
  );

  static const homersStudent = Achievement(
    id: 'homers_student',
    title: 'Homer\'s Student',
    description: 'Complete 5 lessons from the Iliad',
    icon: Icons.menu_book_rounded,
    requirement: 'Complete 5 Iliad lessons',
    maxProgress: 5,
  );

  static const marathonRunner = Achievement(
    id: 'marathon_runner',
    title: 'Marathon Runner',
    description: 'Maintain a 30-day streak',
    icon: Icons.directions_run_rounded,
    requirement: 'Reach 30-day streak',
    maxProgress: 30,
  );

  static const vocabularyTitan = Achievement(
    id: 'vocabulary_titan',
    title: 'Vocabulary Titan',
    description: 'Learn 100 unique words',
    icon: Icons.book_rounded,
    requirement: 'Learn 100 words',
    maxProgress: 100,
  );

  static const speedDemon = Achievement(
    id: 'speed_demon',
    title: 'Speed Demon',
    description: 'Complete a lesson in under 2 minutes',
    icon: Icons.flash_on_rounded,
    requirement: 'Complete lesson < 2 minutes',
    maxProgress: 1,
  );

  static const perfectScholar = Achievement(
    id: 'perfect_scholar',
    title: 'Perfect Scholar',
    description: '100% accuracy on 10 lessons',
    icon: Icons.school_rounded,
    requirement: '10 perfect lessons',
    maxProgress: 10,
  );

  static const earlyBird = Achievement(
    id: 'early_bird',
    title: 'Early Bird',
    description: 'Complete a lesson before 8 AM',
    icon: Icons.wb_sunny_rounded,
    requirement: 'Lesson before 8 AM',
    maxProgress: 1,
  );

  static const nightOwl = Achievement(
    id: 'night_owl',
    title: 'Night Owl',
    description: 'Complete a lesson after 10 PM',
    icon: Icons.nightlight_rounded,
    requirement: 'Lesson after 10 PM',
    maxProgress: 1,
  );

  static const weekendWarrior = Achievement(
    id: 'weekend_warrior',
    title: 'Weekend Warrior',
    description: 'Complete lessons on 10 weekends',
    icon: Icons.weekend_rounded,
    requirement: '10 weekend lessons',
    maxProgress: 10,
  );

  static const grammarGuru = Achievement(
    id: 'grammar_guru',
    title: 'Grammar Guru',
    description: 'Master 50 grammar rules',
    icon: Icons.architecture_rounded,
    requirement: 'Master 50 grammar rules',
    maxProgress: 50,
  );

  static const translationMaster = Achievement(
    id: 'translation_master',
    title: 'Translation Master',
    description: 'Complete 100 translation exercises',
    icon: Icons.translate_rounded,
    requirement: 'Complete 100 translations',
    maxProgress: 100,
  );

  static const socialButterfly = Achievement(
    id: 'social_butterfly',
    title: 'Social Butterfly',
    description: 'Share 5 achievements',
    icon: Icons.share_rounded,
    requirement: 'Share 5 achievements',
    maxProgress: 5,
  );

  static const levelTen = Achievement(
    id: 'level_ten',
    title: 'Rising Star',
    description: 'Reach Level 10',
    icon: Icons.auto_awesome_rounded,
    requirement: 'Reach Level 10',
    maxProgress: 10,
  );

  static const levelTwenty = Achievement(
    id: 'level_twenty',
    title: 'Advanced Scholar',
    description: 'Reach Level 20',
    icon: Icons.emoji_events_rounded,
    requirement: 'Reach Level 20',
    maxProgress: 20,
  );

  static const centurion = Achievement(
    id: 'centurion',
    title: 'Centurion',
    description: 'Complete 100 lessons',
    icon: Icons.military_tech_rounded,
    requirement: 'Complete 100 lessons',
    maxProgress: 100,
  );

  static final all = [
    firstWord,
    homersStudent,
    marathonRunner,
    vocabularyTitan,
    speedDemon,
    perfectScholar,
    earlyBird,
    nightOwl,
    weekendWarrior,
    grammarGuru,
    translationMaster,
    socialButterfly,
    levelTen,
    levelTwenty,
    centurion,
  ];

  static Achievement? findById(String id) {
    try {
      return all.firstWhere((achievement) => achievement.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Achievement tier/rarity
enum AchievementTier { bronze, silver, gold, platinum }

extension AchievementTierExtension on AchievementTier {
  Color get color {
    switch (this) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return const Color(0xFFFFD700);
      case AchievementTier.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  String get name {
    switch (this) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
    }
  }
}
