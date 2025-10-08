# Gamification System - Quick Start Guide

## 🎮 How It Works

The gamification system adds fun, addictive game mechanics to language learning:

- **XP & Levels**: Earn points, level up
- **Combos**: Consecutive correct answers = multipliers
- **Daily Goals**: Set and track daily XP targets
- **Streaks**: Keep learning every day
- **Badges**: Unlock achievements
- **Power-Ups**: Boost your learning
- **Leaderboards**: Compete with friends

## 🚀 Quick Integration Checklist

### Already Integrated ✅

1. **Lessons Flow** ([vibrant_lessons_page.dart](../client/flutter_reader/lib/pages/vibrant_lessons_page.dart:138))
   - GamificationCoordinator initialized in initState
   - Exercise flow uses coordinator.processExercise()
   - Lesson completion uses coordinator.processLessonCompletion()
   - Combo counter shows in header when >= 3
   - Power-up quick bar displays available power-ups

2. **Home Page** ([vibrant_home_page.dart](../client/flutter_reader/lib/pages/vibrant_home_page.dart:258))
   - Daily goal card shows progress
   - Tap to customize goal amount
   - Displays goal streak

3. **All Services** ([app_providers.dart](../client/flutter_reader/lib/app_providers.dart:75))
   - All gamification services provided via Riverpod
   - Automatic initialization
   - Proper lifecycle management

## 📊 Key Features

### 1. XP & Combos

**Base XP:** 25 per correct answer

**Combo Multipliers:**
- 3-4 correct: 1.2x
- 5-9 correct: 1.5x
- 10-19 correct: 2.0x
- 20+ correct: 2.5x

**Bonus XP:**
- 3 combo: +5 XP
- 5 combo: +10 XP
- 10 combo: +25 XP
- 20 combo: +50 XP

**Power-Up Boost:**
- XP Boost active: 2x final XP

### 2. Daily Goals

**Default:** 50 XP/day
**Customizable:** Tap goal card to change
**Auto-Reset:** Midnight local time
**Streak Tracking:** Days maintaining goal

### 3. Power-Ups (6 Types)

| Power-Up | Effect | Cost |
|----------|--------|------|
| XP Boost | 2x XP for next lesson | 50 coins |
| Freeze Streak | Protect streak for 1 day | 100 coins |
| Skip Question | Skip one question | 25 coins |
| Hint | Get a hint | 20 coins |
| Slow Time | Extra time for timed exercises | 30 coins |
| Auto-Complete | Auto-complete one exercise | 75 coins |

**Earn Coins:** Complete lessons, earn badges

### 4. Badges (20+)

**Rarities:**
- Bronze (common)
- Silver (uncommon)
- Gold (rare)
- Platinum (epic)
- Diamond (legendary)
- Legendary (mythic)

**Examples:**
- Level milestones (10, 25, 50, 100)
- Streak milestones (7, 30, 100, 365 days)
- Lesson counts (10, 50, 100, 500)
- Perfect lessons (10, 25, 50)
- Early bird / Night owl (time-based)

## 💻 Code Examples

### Using the Coordinator

```dart
// In your page's initState
GamificationCoordinator? _coordinator;

Future<void> _initializeGamification() async {
  final progress = await ref.read(progressServiceProvider.future);
  final dailyGoal = await ref.read(dailyGoalServiceProvider.future);
  final combo = ref.read(comboServiceProvider);
  final powerUps = await ref.read(powerUpServiceProvider.future);
  final badges = await ref.read(badgeServiceProvider.future);
  final achievements = ref.read(achievementServiceProvider);

  if (mounted) {
    setState(() {
      _coordinator = GamificationCoordinator(
        progressService: progress,
        dailyGoalService: dailyGoal,
        comboService: combo,
        powerUpService: powerUps,
        badgeService: badges,
        achievementService: achievements,
      );
    });
  }
}

// Process exercise result
final result = await _coordinator!.processExercise(
  context: context,
  isCorrect: true,
  baseXP: 25,
  wordsLearned: 1,
);

print('XP earned: ${result.xpEarned}');
print('Combo: ${result.comboCount}x');
print('Multiplier: ${result.multiplier}');
```

### Showing Combo Counter

```dart
// In your build method
if (_coordinator != null && _coordinator!.comboService.currentCombo >= 3)
  ComboCounter(
    combo: _coordinator!.comboService.currentCombo,
    tier: _coordinator!.comboService.comboTier,
  ),
```

### Daily Goal Progress

```dart
// Watch daily goal service
final dailyGoalServiceAsync = ref.watch(dailyGoalServiceProvider);

return dailyGoalServiceAsync.when(
  data: (dailyGoalService) {
    return DailyGoalCard(
      currentXP: dailyGoalService.currentProgress,
      goalXP: dailyGoalService.dailyGoalXP,
      streak: dailyGoalService.goalStreak,
      onTap: () {
        // Show settings modal
        showModalBottomSheet(
          context: context,
          builder: (_) => DailyGoalSettingModal(
            currentGoal: dailyGoalService.dailyGoalXP,
            onGoalChanged: (xp) => dailyGoalService.setDailyGoal(xp),
          ),
        );
      },
    );
  },
  loading: () => const CircularProgressIndicator(),
  error: (_, __) => const Text('Error loading daily goal'),
);
```

### Power-Up Quick Bar

```dart
if (_coordinator != null && _coordinator!.powerUpService.inventory.isNotEmpty)
  PowerUpQuickBar(
    inventory: _coordinator!.powerUpService.inventory,
    activePowerUps: _coordinator!.powerUpService.activePowerUps,
    onActivate: (powerUp) async {
      await _coordinator!.powerUpService.activate(powerUp);
      if (mounted) setState(() {});
    },
  ),
```

## 🎨 UI Components

### Widgets Available

**Combo:**
- `ComboCounter` - Floating combo display
- `ComboMilestonePopup` - Milestone celebration
- `ComboProgressBar` - Progress to next milestone
- `ComboStatsCard` - Statistics summary
- `ComboMultiplierBadge` - Rotating multiplier

**Daily Goal:**
- `DailyGoalCard` - Main goal display
- `DailyGoalSettingModal` - Customize goal
- `DailyGoalChart` - Progress chart

**Power-Ups:**
- `PowerUpCard` - Shop/inventory item
- `PowerUpQuickBar` - In-lesson bar
- `PowerUpEffectIndicator` - Active effect

**Badges:**
- `BadgeWidget` - Single badge display
- `BadgeUnlockModal` - Unlock animation
- `BadgeCollectionGrid` - Collection view
- `BadgeDetailsModal` - Badge details

**Other:**
- `ActivityHeatmap` - Contribution calendar
- `LeaderboardWidget` - Rankings
- `LearningInsights` - Analytics

## 📦 Services API

### ProgressService

```dart
// Current stats
int get xpTotal
int get currentLevel
int get streakDays
int get totalLessons
int get perfectLessons
int get wordsLearned

// Progress to next level
double get progressToNextLevel
int get xpToNextLevel
int get xpForCurrentLevel
int get xpForNextLevel

// Update progress
Future<void> updateProgress({
  required int xpGained,
  required DateTime timestamp,
  bool isPerfect = false,
  int wordsLearnedCount = 0,
})
```

### ComboService

```dart
// Current combo
int get currentCombo
int get maxCombo
ComboTier get comboTier

// Multipliers
double get comboMultiplier
int get bonusXP

// Update combo
void recordCorrect()
void recordWrong()
void reset()

// Check milestones
bool isComboMilestone(int combo)
String getComboMessage(int combo)
```

### PowerUpService

```dart
// Inventory
Map<PowerUpType, int> get inventory
int get coins

// Active power-ups
List<ActivePowerUp> get activePowerUps
bool isActive(PowerUpType type)

// Management
Future<bool> purchase(PowerUp powerUp)
Future<bool> activate(PowerUp powerUp)
Future<void> addCoins(int amount)
```

### BadgeService

```dart
// Collection
List<EarnedBadge> get allBadges
bool hasBadge(String badgeId)

// Check & award
Future<List<EarnedBadge>> checkBadges({
  int? level,
  int? streakDays,
  int? totalLessons,
  int? maxCombo,
  DateTime? lessonTime,
})

Future<EarnedBadge?> awardBadge(Badge badge)
```

### DailyGoalService

```dart
// Goal info
int get dailyGoalXP
int get currentProgress
int get goalStreak
bool get isGoalMet
double get progressPercentage

// Update
Future<void> addProgress(int xp)
Future<void> setDailyGoal(int xp)
```

## 🧪 Testing

### Manual Test Flow

1. **Start App** → Verify no errors
2. **Start Lesson** → Coordinator initializes
3. **Answer 3 correct** → Combo counter appears
4. **Answer 2 more correct** → Combo at 5x, see multiplier
5. **Get 1 wrong** → Combo resets
6. **Complete Lesson** → See rewards modal
7. **Check Home** → Daily goal updated
8. **Tap Goal** → Customize goal amount

### Debug Console Output

```dart
// Add to coordinator
debugPrint('[Gamification] XP: ${result.xpEarned}, Combo: ${result.comboCount}x, Multiplier: ${result.multiplier}');
```

## 🐛 Troubleshooting

### Combo not showing?
- Check `currentCombo >= 3`
- Verify coordinator is initialized
- Look for null coordinator

### XP not updating?
- Check coordinator.processExercise() called
- Verify await on async calls
- Check SharedPreferences permissions

### Daily goal not resetting?
- Verify date check in DailyGoalService
- Check _checkDayRollover() logic
- Ensure app opened after midnight

### Power-ups not activating?
- Check inventory count > 0
- Verify activate() returns true
- Check power-up effects applied

## 📚 Further Reading

- [Full Integration Guide](INTEGRATION_GUIDE.md)
- [Honest Assessment](HONEST_ASSESSMENT.md)
- [200% Complete Report](200_PERCENT_COMPLETE.md)
- [API Protection System](AI_AGENT_PROTECTION.md)

---

**Status:** ✅ Ready to Use
**Version:** 1.0.0
**Last Updated:** 2025-10-07
