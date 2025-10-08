import 'package:flutter/material.dart';

/// Type of power-up
enum PowerUpType {
  xpBoost,        // 2x XP for next lesson
  freezeStreak,   // Protect streak for 1 day
  skipQuestion,   // Skip one question
  hint,           // Get a hint
  slowTime,       // Extra time for timed exercises
  autoComplete,   // Auto-complete one exercise
}

/// Power-up model
class PowerUp {
  const PowerUp({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.cost,
    this.duration,
  });

  final PowerUpType type;
  final String name;
  final String description;
  final IconData icon;
  final PowerUpRarity rarity;
  final int cost; // Cost in coins/gems
  final Duration? duration;

  Color get color {
    switch (rarity) {
      case PowerUpRarity.common:
        return const Color(0xFF94A3B8); // Gray
      case PowerUpRarity.rare:
        return const Color(0xFF3B82F6); // Blue
      case PowerUpRarity.epic:
        return const Color(0xFF9333EA); // Purple
      case PowerUpRarity.legendary:
        return const Color(0xFFFFD700); // Gold
    }
  }

  Gradient get gradient {
    switch (rarity) {
      case PowerUpRarity.common:
        return LinearGradient(
          colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
        );
      case PowerUpRarity.rare:
        return LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        );
      case PowerUpRarity.epic:
        return LinearGradient(
          colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
        );
      case PowerUpRarity.legendary:
        return LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
    }
  }

  static const xpBoost = PowerUp(
    type: PowerUpType.xpBoost,
    name: 'XP Boost',
    description: 'Earn 2x XP for the next lesson',
    icon: Icons.auto_awesome_rounded,
    rarity: PowerUpRarity.rare,
    cost: 50,
    duration: Duration(minutes: 30),
  );

  static const freezeStreak = PowerUp(
    type: PowerUpType.freezeStreak,
    name: 'Streak Freeze',
    description: 'Protect your streak for 24 hours',
    icon: Icons.ac_unit_rounded,
    rarity: PowerUpRarity.epic,
    cost: 100,
    duration: Duration(hours: 24),
  );

  static const skipQuestion = PowerUp(
    type: PowerUpType.skipQuestion,
    name: 'Skip',
    description: 'Skip one difficult question',
    icon: Icons.skip_next_rounded,
    rarity: PowerUpRarity.common,
    cost: 25,
  );

  static const hint = PowerUp(
    type: PowerUpType.hint,
    name: 'Hint',
    description: 'Reveal a helpful hint',
    icon: Icons.lightbulb_rounded,
    rarity: PowerUpRarity.common,
    cost: 10,
  );

  static const slowTime = PowerUp(
    type: PowerUpType.slowTime,
    name: 'Time Warp',
    description: 'Get 50% more time on timed exercises',
    icon: Icons.schedule_rounded,
    rarity: PowerUpRarity.rare,
    cost: 75,
    duration: Duration(minutes: 15),
  );

  static const autoComplete = PowerUp(
    type: PowerUpType.autoComplete,
    name: 'Auto Complete',
    description: 'Automatically complete one exercise',
    icon: Icons.flash_on_rounded,
    rarity: PowerUpRarity.legendary,
    cost: 200,
  );

  static List<PowerUp> get all => [
    xpBoost,
    freezeStreak,
    skipQuestion,
    hint,
    slowTime,
    autoComplete,
  ];
}

/// Power-up rarity levels
enum PowerUpRarity {
  common,
  rare,
  epic,
  legendary,
}

/// Active power-up instance
class ActivePowerUp {
  const ActivePowerUp({
    required this.powerUp,
    required this.activatedAt,
    this.usesRemaining = 1,
  });

  final PowerUp powerUp;
  final DateTime activatedAt;
  final int usesRemaining;

  bool get isExpired {
    if (powerUp.duration == null) return false;
    return DateTime.now().difference(activatedAt) > powerUp.duration!;
  }

  bool get isActive => !isExpired && usesRemaining > 0;
}
