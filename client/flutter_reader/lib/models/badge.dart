import 'package:flutter/material.dart';

/// Badge/Medal type
enum BadgeType {
  milestone, // XP/Level milestones
  achievement, // Special accomplishments
  event, // Limited-time events
  mastery, // Subject mastery
  social, // Social interactions
  streak, // Streak milestones
}

/// Badge rarity
enum BadgeRarity {
  bronze(Color(0xFFCD7F32), 'Bronze'),
  silver(Color(0xFFC0C0C0), 'Silver'),
  gold(Color(0xFFFFD700), 'Gold'),
  platinum(Color(0xFFE5E4E2), 'Platinum'),
  diamond(Color(0xFFB9F2FF), 'Diamond'),
  legendary(Color(0xFFFF1493), 'Legendary');

  const BadgeRarity(this.color, this.label);
  final Color color;
  final String label;
}

/// Badge model
class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.type,
    required this.requirement,
    this.isSecret = false,
    this.xpReward = 0,
    this.coinReward = 0,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;
  final BadgeRarity rarity;
  final BadgeType type;
  final String requirement;
  final bool isSecret;
  final int xpReward;
  final int coinReward;

  /// Predefined badges
  static const firstLesson = Badge(
    id: 'first_lesson',
    name: 'Scholar\'s First Step',
    description: 'Complete your first lesson',
    icon: Icons.school_rounded,
    rarity: BadgeRarity.bronze,
    type: BadgeType.milestone,
    requirement: 'Complete 1 lesson',
    xpReward: 10,
    coinReward: 5,
  );

  static const level10 = Badge(
    id: 'level_10',
    name: 'Rising Scholar',
    description: 'Reach Level 10',
    icon: Icons.star_rounded,
    rarity: BadgeRarity.silver,
    type: BadgeType.milestone,
    requirement: 'Reach Level 10',
    xpReward: 100,
    coinReward: 50,
  );

  static const level25 = Badge(
    id: 'level_25',
    name: 'Expert Linguist',
    description: 'Reach Level 25',
    icon: Icons.workspace_premium_rounded,
    rarity: BadgeRarity.gold,
    type: BadgeType.milestone,
    requirement: 'Reach Level 25',
    xpReward: 250,
    coinReward: 125,
  );

  static const level50 = Badge(
    id: 'level_50',
    name: 'Master Scholar',
    description: 'Reach Level 50',
    icon: Icons.emoji_events_rounded,
    rarity: BadgeRarity.platinum,
    type: BadgeType.milestone,
    requirement: 'Reach Level 50',
    xpReward: 500,
    coinReward: 250,
  );

  static const level100 = Badge(
    id: 'level_100',
    name: 'Legendary Polyglot',
    description: 'Reach Level 100',
    icon: Icons.diamond_rounded,
    rarity: BadgeRarity.legendary,
    type: BadgeType.milestone,
    requirement: 'Reach Level 100',
    xpReward: 1000,
    coinReward: 500,
  );

  static const streak7 = Badge(
    id: 'streak_7',
    name: 'Week Warrior',
    description: 'Maintain a 7-day streak',
    icon: Icons.local_fire_department_rounded,
    rarity: BadgeRarity.bronze,
    type: BadgeType.streak,
    requirement: '7-day streak',
    xpReward: 50,
    coinReward: 25,
  );

  static const streak30 = Badge(
    id: 'streak_30',
    name: 'Monthly Master',
    description: 'Maintain a 30-day streak',
    icon: Icons.local_fire_department_rounded,
    rarity: BadgeRarity.silver,
    type: BadgeType.streak,
    requirement: '30-day streak',
    xpReward: 200,
    coinReward: 100,
  );

  static const streak100 = Badge(
    id: 'streak_100',
    name: 'Century of Learning',
    description: 'Maintain a 100-day streak',
    icon: Icons.local_fire_department_rounded,
    rarity: BadgeRarity.gold,
    type: BadgeType.streak,
    requirement: '100-day streak',
    xpReward: 500,
    coinReward: 250,
  );

  static const perfectWeek = Badge(
    id: 'perfect_week',
    name: 'Flawless Week',
    description: 'Complete 7 perfect lessons in a row',
    icon: Icons.check_circle_rounded,
    rarity: BadgeRarity.gold,
    type: BadgeType.achievement,
    requirement: '7 perfect lessons consecutively',
    xpReward: 150,
    coinReward: 75,
  );

  static const speedDemon = Badge(
    id: 'speed_demon',
    name: 'Lightning Scholar',
    description: 'Complete a lesson in under 1 minute',
    icon: Icons.bolt_rounded,
    rarity: BadgeRarity.silver,
    type: BadgeType.achievement,
    requirement: 'Complete lesson < 1 minute',
    xpReward: 100,
    coinReward: 50,
  );

  static const nightOwl = Badge(
    id: 'night_owl',
    name: 'Midnight Scholar',
    description: 'Complete lessons at midnight',
    icon: Icons.nightlight_rounded,
    rarity: BadgeRarity.bronze,
    type: BadgeType.achievement,
    requirement: 'Study at midnight 5 times',
    isSecret: true,
    xpReward: 50,
    coinReward: 25,
  );

  static const earlyBird = Badge(
    id: 'early_bird',
    name: 'Dawn Learner',
    description: 'Complete lessons at sunrise',
    icon: Icons.wb_sunny_rounded,
    rarity: BadgeRarity.bronze,
    type: BadgeType.achievement,
    requirement: 'Study at 6 AM 5 times',
    isSecret: true,
    xpReward: 50,
    coinReward: 25,
  );

  static const comboKing = Badge(
    id: 'combo_king',
    name: 'Combo Champion',
    description: 'Achieve a 50x combo',
    icon: Icons.flash_on_rounded,
    rarity: BadgeRarity.platinum,
    type: BadgeType.achievement,
    requirement: '50x combo streak',
    xpReward: 300,
    coinReward: 150,
  );

  static const vocabularyMaster = Badge(
    id: 'vocabulary_master',
    name: 'Lexicon Master',
    description: 'Learn 1000 words',
    icon: Icons.menu_book_rounded,
    rarity: BadgeRarity.platinum,
    type: BadgeType.mastery,
    requirement: '1000 words learned',
    xpReward: 500,
    coinReward: 250,
  );

  static const translationExpert = Badge(
    id: 'translation_expert',
    name: 'Translation Virtuoso',
    description: 'Perfect accuracy on 50 translations',
    icon: Icons.translate_rounded,
    rarity: BadgeRarity.gold,
    type: BadgeType.mastery,
    requirement: '50 perfect translations',
    xpReward: 250,
    coinReward: 125,
  );

  static const socialButterfly = Badge(
    id: 'social_butterfly',
    name: 'Social Scholar',
    description: 'Add 10 friends',
    icon: Icons.group_rounded,
    rarity: BadgeRarity.silver,
    type: BadgeType.social,
    requirement: '10 friends',
    xpReward: 100,
    coinReward: 50,
  );

  static const competitor = Badge(
    id: 'competitor',
    name: 'Top 10 Finisher',
    description: 'Finish in top 10 of leaderboard',
    icon: Icons.leaderboard_rounded,
    rarity: BadgeRarity.gold,
    type: BadgeType.social,
    requirement: 'Top 10 leaderboard',
    xpReward: 200,
    coinReward: 100,
  );

  static const champion = Badge(
    id: 'champion',
    name: 'Champion',
    description: 'Reach #1 on leaderboard',
    icon: Icons.emoji_events_rounded,
    rarity: BadgeRarity.diamond,
    type: BadgeType.social,
    requirement: '#1 on leaderboard',
    xpReward: 1000,
    coinReward: 500,
  );

  static const summerEvent2025 = Badge(
    id: 'summer_event_2025',
    name: 'Summer Scholar 2025',
    description: 'Participated in Summer Event',
    icon: Icons.wb_sunny_rounded,
    rarity: BadgeRarity.gold,
    type: BadgeType.event,
    requirement: 'Complete summer event',
    xpReward: 300,
    coinReward: 150,
  );

  static const secretTreasure = Badge(
    id: 'secret_treasure',
    name: '???',
    description: 'A mysterious achievement...',
    icon: Icons.lock_rounded,
    rarity: BadgeRarity.legendary,
    type: BadgeType.achievement,
    requirement: 'Find the hidden treasure',
    isSecret: true,
    xpReward: 1000,
    coinReward: 500,
  );

  /// Get all badges
  static List<Badge> get all => [
    firstLesson,
    level10,
    level25,
    level50,
    level100,
    streak7,
    streak30,
    streak100,
    perfectWeek,
    speedDemon,
    nightOwl,
    earlyBird,
    comboKing,
    vocabularyMaster,
    translationExpert,
    socialButterfly,
    competitor,
    champion,
    summerEvent2025,
    secretTreasure,
  ];

  /// Get badges by type
  static List<Badge> byType(BadgeType type) {
    return all.where((b) => b.type == type).toList();
  }

  /// Get badges by rarity
  static List<Badge> byRarity(BadgeRarity rarity) {
    return all.where((b) => b.rarity == rarity).toList();
  }
}

/// User's earned badge
class EarnedBadge {
  const EarnedBadge({
    required this.badge,
    required this.earnedAt,
    this.progress = 1.0,
  });

  final Badge badge;
  final DateTime earnedAt;
  final double progress; // For badges in progress

  bool get isCompleted => progress >= 1.0;

  Map<String, dynamic> toJson() {
    return {
      'badgeId': badge.id,
      'earnedAt': earnedAt.toIso8601String(),
      'progress': progress,
    };
  }

  static EarnedBadge fromJson(Map<String, dynamic> json) {
    final badge = Badge.all.firstWhere((b) => b.id == json['badgeId']);
    return EarnedBadge(
      badge: badge,
      earnedAt: DateTime.parse(json['earnedAt']),
      progress: json['progress'] ?? 1.0,
    );
  }
}
