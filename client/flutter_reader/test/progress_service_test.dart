import 'package:flutter_test/flutter_test.dart';
import 'package:ancient_languages_app/services/progress_service.dart';
import 'package:ancient_languages_app/services/progress_store.dart';

void main() {
  group('ProgressService - Level Calculations', () {
    test('calculateLevel returns 0 for 0 XP', () {
      expect(ProgressService.calculateLevel(0), 0);
    });

    test('calculateLevel returns 0 for XP < 100', () {
      expect(ProgressService.calculateLevel(99), 0);
    });

    test('calculateLevel returns 1 for exactly 100 XP', () {
      expect(ProgressService.calculateLevel(100), 1);
    });

    test('calculateLevel returns 1 for XP between 100-399', () {
      expect(ProgressService.calculateLevel(250), 1);
      expect(ProgressService.calculateLevel(399), 1);
    });

    test('calculateLevel returns 2 for exactly 400 XP', () {
      expect(ProgressService.calculateLevel(400), 2);
    });

    test('calculateLevel returns 2 for XP between 400-899', () {
      expect(ProgressService.calculateLevel(650), 2);
      expect(ProgressService.calculateLevel(899), 2);
    });

    test('calculateLevel returns 3 for exactly 900 XP', () {
      expect(ProgressService.calculateLevel(900), 3);
    });

    test('calculateLevel handles large XP values', () {
      expect(ProgressService.calculateLevel(10000), 10);
      expect(ProgressService.calculateLevel(40000), 20);
    });
  });

  group('ProgressService - XP For Level', () {
    test('getXPForLevel returns correct values', () {
      expect(ProgressService.getXPForLevel(0), 0);
      expect(ProgressService.getXPForLevel(1), 100);
      expect(ProgressService.getXPForLevel(2), 400);
      expect(ProgressService.getXPForLevel(3), 900);
      expect(ProgressService.getXPForLevel(4), 1600);
      expect(ProgressService.getXPForLevel(5), 2500);
    });
  });

  group('ProgressService - Progress To Next Level', () {
    test('progressToNextLevel returns 0.0 at level boundary', () {
      expect(ProgressService.getProgressToNextLevel(0), 0.0);
      expect(ProgressService.getProgressToNextLevel(100), 0.0);
      expect(ProgressService.getProgressToNextLevel(400), 0.0);
    });

    test('progressToNextLevel returns 0.5 at midpoint', () {
      // Level 0->1: 0 to 100, midpoint = 50
      expect(ProgressService.getProgressToNextLevel(50), 0.5);

      // Level 1->2: 100 to 400, midpoint = 250
      expect(ProgressService.getProgressToNextLevel(250), 0.5);

      // Level 2->3: 400 to 900, midpoint = 650
      expect(ProgressService.getProgressToNextLevel(650), 0.5);
    });

    test('progressToNextLevel returns ~1.0 near next level', () {
      expect(ProgressService.getProgressToNextLevel(99), closeTo(0.99, 0.01));
      expect(
        ProgressService.getProgressToNextLevel(399),
        closeTo(0.997, 0.001),
      );
    });

    test('progressToNextLevel is clamped between 0 and 1', () {
      final progress = ProgressService.getProgressToNextLevel(50);
      expect(progress, greaterThanOrEqualTo(0.0));
      expect(progress, lessThanOrEqualTo(1.0));
    });
  });

  group('ProgressService - Streak Logic (Unit Tests)', () {
    late ProgressService service;
    late _MockProgressStore store;

    setUp(() {
      store = _MockProgressStore();
      service = ProgressService(store);
    });

    test('first lesson sets streak to 1', () async {
      await service.load();

      await service.updateProgress(
        xpGained: 50,
        timestamp: DateTime(2025, 1, 15, 10, 0),
      );

      expect(service.streakDays, 1);
      expect(service.xpTotal, 50);
    });

    test('second lesson same day keeps streak at 1', () async {
      // Set up initial state
      store.initialData = {
        'xpTotal': 50,
        'streakDays': 1,
        'lastLessonAt': '2025-01-15T10:00:00',
        'lastStreakUpdate': '2025-01-15T00:00:00',
      };
      await service.load();

      // Complete another lesson same day (8 hours later)
      await service.updateProgress(
        xpGained: 30,
        timestamp: DateTime(2025, 1, 15, 18, 0),
      );

      expect(service.streakDays, 1); // Should NOT increment
      expect(service.xpTotal, 80);
    });

    test('lesson next day increments streak', () async {
      // Set up initial state
      store.initialData = {
        'xpTotal': 50,
        'streakDays': 1,
        'lastLessonAt': '2025-01-15T10:00:00',
        'lastStreakUpdate': '2025-01-15T00:00:00',
      };
      await service.load();

      // Complete lesson next day
      await service.updateProgress(
        xpGained: 30,
        timestamp: DateTime(2025, 1, 16, 10, 0),
      );

      expect(service.streakDays, 2); // Should increment
      expect(service.xpTotal, 80);
    });

    test('gap of 2+ days resets streak to 1', () async {
      // Set up initial state with 5-day streak
      store.initialData = {
        'xpTotal': 250,
        'streakDays': 5,
        'lastLessonAt': '2025-01-15T10:00:00',
        'lastStreakUpdate': '2025-01-15T00:00:00',
      };
      await service.load();

      // Complete lesson 3 days later (skipped 2 days)
      await service.updateProgress(
        xpGained: 30,
        timestamp: DateTime(2025, 1, 18, 10, 0),
      );

      expect(service.streakDays, 1); // Should reset
      expect(service.xpTotal, 280);
    });

    test('edge case: lesson at 11:59pm then 12:01am', () async {
      // This should count as next day and increment streak
      store.initialData = {
        'xpTotal': 50,
        'streakDays': 1,
        'lastLessonAt': '2025-01-15T23:59:00',
        'lastStreakUpdate': '2025-01-15T00:00:00',
      };
      await service.load();

      // Complete lesson 2 minutes later (next day)
      await service.updateProgress(
        xpGained: 30,
        timestamp: DateTime(2025, 1, 16, 0, 1),
      );

      expect(
        service.streakDays,
        2,
      ); // Should increment (different calendar day)
      expect(service.xpTotal, 80);
    });
  });

  group('ProgressService - Concurrent Updates (Race Condition Test)', () {
    late ProgressService service;
    late _MockProgressStore store;

    setUp(() {
      store = _MockProgressStore();
      service = ProgressService(store);
    });

    test('sequential updates accumulate correctly', () async {
      await service.load();

      // First update
      await service.updateProgress(
        xpGained: 50,
        timestamp: DateTime(2025, 1, 15),
      );
      expect(service.xpTotal, 50);

      // Second update
      await service.updateProgress(
        xpGained: 30,
        timestamp: DateTime(2025, 1, 15),
      );
      expect(service.xpTotal, 80);

      // Third update
      await service.updateProgress(
        xpGained: 20,
        timestamp: DateTime(2025, 1, 15),
      );
      expect(service.xpTotal, 100);
    });

    test('concurrent updates execute sequentially without data loss', () async {
      await service.load();

      // Fire off multiple updates without awaiting (simulates race condition)
      final futures = <Future<void>>[];
      final timestamp = DateTime.now();
      futures.add(service.updateProgress(xpGained: 10, timestamp: timestamp));
      futures.add(service.updateProgress(xpGained: 20, timestamp: timestamp));
      futures.add(service.updateProgress(xpGained: 30, timestamp: timestamp));
      futures.add(service.updateProgress(xpGained: 40, timestamp: timestamp));

      // Wait for all to complete
      await Future.wait(futures);

      // All XP should be accounted for (no data loss)
      expect(service.xpTotal, 100); // 10 + 20 + 30 + 40
    });
  });

  group('ProgressService - Level Up Detection', () {
    late ProgressService service;
    late _MockProgressStore store;

    setUp(() {
      store = _MockProgressStore();
      service = ProgressService(store);
    });

    test('detects level up when crossing threshold', () async {
      // Start at 90 XP (level 0)
      store.initialData = {
        'xpTotal': 90,
        'streakDays': 1,
        'lastLessonAt': '2025-01-15T10:00:00',
        'lastStreakUpdate': '2025-01-15T00:00:00',
      };
      await service.load();
      expect(service.currentLevel, 0);

      // Add 20 XP, should reach level 1
      await service.updateProgress(
        xpGained: 20,
        timestamp: DateTime(2025, 1, 15),
      );

      expect(service.xpTotal, 110);
      expect(service.currentLevel, 1);
      // Note: Level up log happens in updateProgress (line 115)
    });

    test('no level up when staying in same level', () async {
      store.initialData = {
        'xpTotal': 100,
        'streakDays': 1,
        'lastLessonAt': '2025-01-15T10:00:00',
        'lastStreakUpdate': '2025-01-15T00:00:00',
      };
      await service.load();
      expect(service.currentLevel, 1);

      // Add 50 XP (still in level 1)
      await service.updateProgress(
        xpGained: 50,
        timestamp: DateTime(2025, 1, 15),
      );

      expect(service.xpTotal, 150);
      expect(service.currentLevel, 1); // Still level 1
    });
  });
}

/// Mock ProgressStore for testing
class _MockProgressStore extends ProgressStore {
  Map<String, dynamic> initialData = {
    'xpTotal': 0,
    'streakDays': 0,
    'lastLessonAt': null,
    'lastStreakUpdate': null,
  };

  Map<String, dynamic> _data = {};

  @override
  Future<Map<String, dynamic>> load() async {
    _data = Map<String, dynamic>.from(initialData);
    return _data;
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    _data = Map<String, dynamic>.from(data);
    // Simulate async storage (add small delay to test race conditions)
    await Future.delayed(const Duration(milliseconds: 10));
  }
}
