import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ancient_languages_app/services/retention_loop_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Retention Loop Integration Tests', () {
    late RetentionLoopService service;

    setUp(() async {
      service = RetentionLoopService();
      await service.load();
    });

    test('Service loads successfully', () {
      expect(service.isLoaded, true);
      expect(service.dailyLoop, isNotNull);
      expect(service.weeklyLoop, isNotNull);
      expect(service.masteryLoop, isNotNull);
    });

    test('First check-in returns "Started Your Journey" reward', () async {
      final rewards = await service.checkIn(xpEarned: 200, lessonsCompleted: 1);

      expect(rewards, isNotEmpty);
      expect(rewards.first.type, RewardType.streakStart);
      expect(rewards.first.title, 'Started Your Journey!');
      expect(rewards.first.xpBonus, 10);
      debugPrint(
        'First reward: ${rewards.first.title} (+${rewards.first.xpBonus} XP)',
      );
    });

    test('Second check-in on same day returns no reward', () async {
      // First check-in
      await service.checkIn(xpEarned: 200, lessonsCompleted: 1);

      // Second check-in same day
      final rewards = await service.checkIn(xpEarned: 200, lessonsCompleted: 1);

      expect(rewards, isEmpty);
      debugPrint('Second check-in same day: no rewards (correct)');
    });

    test('3-day streak returns milestone reward', () async {
      // Reset service
      await service.reset();

      // Day 1
      service.dailyLoop!.lastCheckIn = DateTime(2025, 1, 1);
      service.dailyLoop!.currentStreak = 0;

      // Day 2
      service.dailyLoop!.checkIn(DateTime(2025, 1, 2));

      // Day 3 - should trigger milestone
      final reward = service.dailyLoop!.checkIn(DateTime(2025, 1, 3));

      expect(reward, isNotNull);
      expect(reward!.type, RewardType.streakMilestone);
      expect(reward.title, '3 Day Streak!');
      expect(reward.xpBonus, 15); // 3 * 5
      debugPrint(
        '3-day streak reward: ${reward.title} (+${reward.xpBonus} XP)',
      );
    });

    test('7-day streak returns bigger milestone reward', () async {
      // Reset and set to day 6
      await service.reset();
      service.dailyLoop!.currentStreak = 6;
      service.dailyLoop!.lastCheckIn = DateTime(2025, 1, 6);

      // Day 7 - should trigger milestone
      final reward = service.dailyLoop!.checkIn(DateTime(2025, 1, 7));

      expect(reward, isNotNull);
      expect(reward!.type, RewardType.streakMilestone);
      expect(reward.title, '7 Day Streak!');
      expect(reward.xpBonus, 35); // 7 * 5
      debugPrint(
        '7-day streak reward: ${reward.title} (+${reward.xpBonus} XP)',
      );
    });

    test('Broken streak returns reset message', () async {
      // Set to day 5
      await service.reset();
      service.dailyLoop!.currentStreak = 5;
      service.dailyLoop!.lastCheckIn = DateTime(2025, 1, 5);

      // Skip a day, check in on day 7 (not 6)
      final reward = service.dailyLoop!.checkIn(DateTime(2025, 1, 7));

      expect(reward, isNotNull);
      expect(reward!.type, RewardType.streakBroken);
      expect(reward.title, 'Streak Reset');
      expect(reward.xpBonus, 0);
      expect(service.dailyLoop!.currentStreak, 1); // Reset to 1
      debugPrint('Broken streak: ${reward.title}');
    });

    test('Weekly goal completion returns reward', () async {
      await service.reset();

      // Add progress toward weekly goal (assuming 1000 XP goal)
      service.weeklyLoop!.addProgress(1000, 10);

      final reward = service.weeklyLoop!.checkProgress();

      expect(reward, isNotNull);
      expect(reward!.type, RewardType.weeklyGoal);
      debugPrint('Weekly goal reward: ${reward.title} (+${reward.xpBonus} XP)');
    });

    test('Mastery level up returns reward', () async {
      await service.reset();

      // Add enough XP to level up (varies by level)
      final reward = service.masteryLoop!.addMastery(500);

      expect(reward, isNotNull);
      expect(reward!.type, RewardType.masteryLevel);
      debugPrint('Mastery reward: ${reward.title} (+${reward.xpBonus} XP)');
    });

    test('Multiple rewards can be returned in one check-in', () async {
      // This tests the scenario where user triggers multiple milestones at once
      await service.reset();

      // Set up to trigger both daily streak and weekly goal
      service.dailyLoop!.currentStreak = 2;
      service.dailyLoop!.lastCheckIn = DateTime(2025, 1, 2);
      service.weeklyLoop!.addProgress(950, 9); // Close to 1000

      // Check in with enough XP to complete weekly goal
      final rewards = await service.checkIn(xpEarned: 100, lessonsCompleted: 1);

      expect(rewards.length, greaterThanOrEqualTo(2));
      debugPrint('Multiple rewards: ${rewards.length} rewards earned');
      for (final reward in rewards) {
        debugPrint('  - ${reward.title}: +${reward.xpBonus} XP');
      }
    });
  });
}
