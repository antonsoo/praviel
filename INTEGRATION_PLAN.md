# Backend Challenges Integration Plan

## Goal
Connect the existing backend challenge APIs to the Flutter frontend with proper error handling, loading states, and offline support.

## Current Architecture

### Backend (✅ Complete)
```
/api/v1/challenges/
├── daily [GET] - Get daily challenges (auto-generates)
├── update-progress [POST] - Update challenge progress
├── streak [GET] - Get challenge streak
├── weekly [GET] - Get weekly challenges
├── weekly/update-progress [POST] - Update weekly progress
├── purchase-streak-freeze [POST] - Buy streak freeze
└── double-or-nothing/
    ├── start [POST] - Start challenge
    └── status [GET] - Get status
```

### Frontend (⚠️ Partial)
```
Services:
├── ✅ challenges_api.dart - API client (created, not used)
├── ✅ backend_challenge_service.dart - Service layer (created, not used)
├── ⚠️ daily_challenge_service.dart - OLD local-only service (currently in use)

Widgets:
├── ✅ daily_challenges_widget.dart - Shows local challenges
├── ✅ weekly_challenges_widget.dart - Created but not integrated
├── ❌ streak_freeze_shop.dart - Doesn't exist
└── ❌ double_or_nothing_modal.dart - Doesn't exist
```

## Integration Steps

### Phase 1: Replace Local Daily Challenges with Backend (PRIORITY 1)

**Goal**: Make existing daily challenges UI call backend API instead of generating locally

**Steps**:
1. ✅ Create `ChallengesApi` class
2. ✅ Create `BackendChallengeService` class
3. ✅ Add providers to `app_providers.dart`
4. ⬜ Update `DailyChallengeService` to delegate to backend
   - Keep existing interface for compatibility
   - Replace `_generateDailyChallenges()` with API call
   - Replace `updateProgress()` with API call
   - Add caching for offline support
5. ⬜ Test with real user account
6. ⬜ Fix any bugs found

**Files to Modify**:
- `services/daily_challenge_service.dart` - Refactor to use `BackendChallengeService`
- `models/daily_challenge.dart` - May need to add `fromApiResponse()` converter

**Estimated Time**: 2-3 hours

**Test Checklist**:
- [ ] Daily challenges load from backend on app start
- [ ] Progress updates when lesson completed
- [ ] Challenges marked complete when target reached
- [ ] Rewards granted to user (coins + XP)
- [ ] Streak updates when all challenges completed
- [ ] Works offline (shows cached challenges)
- [ ] Syncs when back online

---

### Phase 2: Add Weekly Challenges to Home Page (PRIORITY 2)

**Goal**: Display weekly challenges card on home screen

**Steps**:
1. ✅ Create `WeeklyChallengesCard` widget
2. ⬜ Add to `vibrant_home_page.dart` below daily challenges
3. ⬜ Create provider for weekly challenges state
4. ⬜ Add pull-to-refresh for challenges
5. ⬜ Add celebration animation when weekly challenge completes
6. ⬜ Test progress updates

**Files to Modify**:
- `pages/vibrant_home_page.dart` - Add `WeeklyChallengesCard`
- `app_providers.dart` - Add weekly challenges provider if needed

**Estimated Time**: 1-2 hours

**Test Checklist**:
- [ ] Weekly challenges card appears on home page
- [ ] Shows correct time remaining (days)
- [ ] Shows correct reward multipliers (5-10x)
- [ ] Progress updates when daily challenges completed
- [ ] Completion triggers celebration
- [ ] New challenges generate on Monday

---

### Phase 3: Build Streak Freeze Shop (PRIORITY 3)

**Goal**: Let users purchase and use streak freezes

**Steps**:
1. ⬜ Create `StreakFreezeShopBottomSheet` widget
2. ⬜ Add "Shop" button to home page or profile
3. ⬜ Implement purchase flow
4. ⬜ Show owned streak freezes count
5. ⬜ Auto-use on streak break
6. ⬜ Add confirmation dialogs
7. ⬜ Test purchase and usage

**Files to Create**:
- `widgets/gamification/streak_freeze_shop.dart`

**Files to Modify**:
- `pages/vibrant_home_page.dart` or `profile_page.dart` - Add shop entry point

**Estimated Time**: 2-3 hours

**Test Checklist**:
- [ ] Shop opens from home/profile
- [ ] Shows current coin balance
- [ ] Purchase button enabled only if enough coins
- [ ] Purchase succeeds and updates balance
- [ ] Owned freezes count shows in UI
- [ ] Streak freeze auto-consumes on miss
- [ ] Confirmation before purchase

---

### Phase 4: Build Double or Nothing Modal (PRIORITY 4)

**Goal**: Let users wager coins for commitment challenges

**Steps**:
1. ⬜ Create `DoubleOrNothingModal` widget
2. ⬜ Add entry point (button on home page?)
3. ⬜ Implement wager selection (100, 500, 1000 coins)
4. ⬜ Implement days selection (7, 14, 30 days)
5. ⬜ Show current challenge status if active
6. ⬜ Add progress tracking widget
7. ⬜ Add win/loss celebration
8. ⬜ Test complete flow

**Files to Create**:
- `widgets/gamification/double_or_nothing_modal.dart`
- `widgets/gamification/double_or_nothing_progress_widget.dart`

**Files to Modify**:
- `pages/vibrant_home_page.dart` - Add entry point

**Estimated Time**: 3-4 hours

**Test Checklist**:
- [ ] Modal opens with wager/days selection
- [ ] Can't start if insufficient coins
- [ ] Can't start if already have active challenge
- [ ] Active challenge shows progress
- [ ] Progress updates daily
- [ ] Win scenario grants 2x coins
- [ ] Loss scenario shows encouraging message
- [ ] Can only have 1 active at a time

---

## Technical Considerations

### Error Handling
```dart
// Example pattern for all API calls
try {
  final challenges = await _api.getDailyChallenges();
  // success
} on http.ClientException {
  // Network error - show cached data
  debugPrint('Network error, using cached challenges');
  return _cachedChallenges;
} catch (e) {
  // Other error - show error state
  debugPrint('Failed to load challenges: $e');
  rethrow;
}
```

### Loading States
```dart
// Use AsyncValue for loading states
ref.watch(backendChallengeServiceProvider).when(
  data: (service) => /* Show challenges */,
  loading: () => /* Show skeleton loader */,
  error: (error, stack) => /* Show error state with retry */,
);
```

### Offline Support
```dart
// Cache challenges in SharedPreferences
class BackendChallengeService {
  static const _cacheKey = 'cached_challenges';

  Future<void> _cacheData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode({
      'daily': _dailyChallenges.map((c) => c.toJson()).toList(),
      'weekly': _weeklyChallenges.map((c) => c.toJson()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    }));
  }

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      // Parse and use cached data
    }
  }
}
```

### Progress Synchronization
```dart
// When lesson completes, update all relevant challenges
Future<void> onLessonCompleted(...) async {
  try {
    // Try to update backend
    await service.onLessonCompleted(...);
  } catch (e) {
    // If offline, queue for later sync
    await _queuePendingUpdate(...);
  }
}

// Sync pending updates when back online
Future<void> syncPendingUpdates() async {
  final pending = await _loadPendingUpdates();
  for (final update in pending) {
    try {
      await _api.updateChallengeProgress(...);
      await _removePendingUpdate(update.id);
    } catch (e) {
      // Keep in queue
      break;
    }
  }
}
```

## Testing Strategy

### Unit Tests
- [ ] ChallengesApi methods with mocked HTTP client
- [ ] BackendChallengeService methods
- [ ] Progress calculation logic
- [ ] Reward granting logic

### Integration Tests
- [ ] End-to-end challenge completion flow
- [ ] Offline/online transitions
- [ ] Pending updates sync
- [ ] Reward granting to user progress

### Manual Tests
- [ ] Create real user account
- [ ] Complete daily challenges
- [ ] Complete weekly challenges
- [ ] Purchase streak freeze
- [ ] Start double or nothing
- [ ] Complete double or nothing
- [ ] Break streak (test freeze consumption)
- [ ] Test with airplane mode (offline)
- [ ] Test reconnection (sync)

## Success Criteria

1. ✅ All daily challenges come from backend API
2. ✅ Weekly challenges visible and functional
3. ✅ Streak freeze purchasable and works
4. ✅ Double or nothing fully functional
5. ✅ Offline support works (cached challenges)
6. ✅ No data loss on network errors
7. ✅ Smooth animations and feedback
8. ✅ Proper error handling everywhere
9. ✅ No crashes or bugs
10. ✅ Code is maintainable and tested

## Timeline

**Phase 1**: 2-3 hours (can start NOW)
**Phase 2**: 1-2 hours (depends on Phase 1)
**Phase 3**: 2-3 hours (depends on Phase 1)
**Phase 4**: 3-4 hours (depends on Phase 1)

**Total**: 8-12 hours of focused work

**Critical Path**: Phase 1 must be done first. Others can be done in parallel afterward.

## Next Immediate Action

**START HERE**: Refactor `DailyChallengeService` to use backend API

```dart
// services/daily_challenge_service.dart

class DailyChallengeService extends ChangeNotifier {
  DailyChallengeService(
    this._progressService,
    this._powerUpService,
    this._backendService, // ADD THIS
  );

  final BackendChallengeService _backendService; // ADD THIS

  // Replace local generation with backend API call
  Future<void> load() async {
    try {
      await _backendService.load();
      _challenges = _convertFromBackend(_backendService.dailyChallenges);
      _loaded = true;
      notifyListeners();
    } catch (e) {
      // Try to load from cache
      await _loadFromCache();
    }
  }

  // Convert backend responses to local models
  List<DailyChallenge> _convertFromBackend(
    List<DailyChallengeApiResponse> apiChallenges
  ) {
    return apiChallenges.map((api) => DailyChallenge(
      id: api.id.toString(),
      type: _parseType(api.challengeType),
      difficulty: _parseDifficulty(api.difficulty),
      title: api.title,
      description: api.description,
      targetValue: api.targetValue,
      currentProgress: api.currentProgress,
      coinReward: api.coinReward,
      xpReward: api.xpReward,
      expiresAt: api.expiresAt,
      isCompleted: api.isCompleted,
      completedAt: api.completedAt,
      isWeekendBonus: api.isWeekendBonus,
    )).toList();
  }
}
```

---

**Created**: 2025-10-08
**Status**: PLANNING - Ready to execute
**Estimated Completion**: Phase 1 can be done in next session
