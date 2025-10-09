# Critical TODO - What's Actually Missing

## Testing (HIGH PRIORITY) ⚠️

**NONE OF THIS HAS BEEN TESTED WITH A REAL USER**

### Must Test:
1. Complete lesson → verify challenge progress updates
2. Complete challenge → verify coins increase in UI
3. Purchase streak freeze → verify coins decrease, freeze count increases
4. Start double-or-nothing → verify coins deducted, challenge created
5. Complete double-or-nothing → verify coins doubled
6. Miss day with streak freeze → verify streak protected
7. Weekly challenge completion → verify 5-10x rewards granted
8. Offline mode → complete lesson, reconnect, verify syncs

## Missing Features

### 1. Celebration Animations
- No visual feedback when challenge completes (just updates silently)
- No confetti/animation when weekly challenge done
- No win/loss animation for double-or-nothing

### 2. Auto-Use Streak Freeze
- Backend has endpoint: `/api/v1/challenges/use-streak-freeze`
- BUT: Who calls it? When?
- Need daily cron job or trigger to check for missed days

### 3. Pull-to-Refresh
- Weekly challenges card has no pull-to-refresh
- User can't manually refresh challenges

### 4. Error Messages
- Generic errors: "Failed to load challenges"
- Need specific user-friendly messages

### 5. Offline Sync Verification
- `DailyChallengeServiceV2.syncPendingUpdates()` exists
- But is it called when app comes back online?
- Need connectivity listener

## Known Bugs (From Critical Review)

### FIXED:
- ✅ Coins not loading from backend on startup
- ✅ Backend API missing coins fields
- ✅ Challenge updates not returning new coin balance

### UNTESTED (May Still Be Broken):
- ⚠️ Race conditions with concurrent challenge updates
- ⚠️ Double-or-nothing daily progress tracking
- ⚠️ Weekly challenge auto-expiry and regeneration
- ⚠️ Pending updates queue actually syncing

## Backend Missing

### 1. Streak Freeze Auto-Use Logic
Need cron job or trigger:
```python
# Run daily at midnight
async def check_broken_streaks():
    for user in active_users:
        if not completed_challenges_yesterday(user):
            if user.streak_freezes > 0:
                use_streak_freeze(user)
            else:
                reset_streak(user)
```

### 2. Weekly Challenge Expiry Cleanup
```python
# Run weekly on Monday at midnight
async def cleanup_expired_weekly_challenges():
    mark_expired_challenges()
    generate_new_weekly_challenges()
```

## Frontend Missing

### 1. Connectivity Listener
```dart
Connectivity().onConnectivityChanged.listen((result) {
  if (result != ConnectivityResult.none) {
    dailyChallengeService.syncPendingUpdates();
  }
});
```

### 2. Challenge Completion Celebration
```dart
if (completed) {
  showDialog(
    context: context,
    builder: (_) => CelebrationDialog(
      coins: challenge.coinReward,
      xp: challenge.xpReward,
    ),
  );
}
```

## What Can Wait (Low Priority)

- Push notifications for challenge expiry
- Social features (challenge friends)
- Analytics dashboard
- A/B testing infrastructure
- Additional power-ups (XP boost, hints, skip)

## Next Actions

1. **RIGHT NOW**: Manual test with real user account
2. Add celebration animations
3. Implement streak freeze auto-use
4. Add offline sync trigger
5. Test edge cases (race conditions, errors)

---

**Status**: Code is ~85% done, Testing is ~5% done
**Critical Path**: TESTING before adding more features
