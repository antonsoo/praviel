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

### 1. Celebration Animations ✅ DONE (commit 2621055)
- ✅ Created CelebrationDialog widget with confetti
- ✅ Integrated into GamificationCoordinator.showRewards()
- ✅ Shows coins/XP with elastic animations
- ⚠️ Still need: weekly challenge & double-or-nothing specific celebrations

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
- ✅ Coins not loading from backend on startup (commit 51d9618)
- ✅ Backend API missing coins fields (commit 51d9618)
- ✅ Challenge updates not returning new coin balance (commit 51d9618)
- ✅ XP challenge has target_value=0 for level 0 users (commit a3fb88b)
- ✅ Missing ChallengeCelebration widget referenced in coordinator (commit 2621055)

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

### 2. Challenge Completion Celebration ✅ DONE (commit 2621055)
```dart
// NOW IMPLEMENTED in GamificationCoordinator.showRewards()
for (final challenge in rewards.completedChallenges) {
  showCelebration(
    context,
    coins: challenge.coinReward,
    xp: challenge.xpReward,
    title: '🎉 Challenge Complete!',
    message: challenge.title,
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

1. **RIGHT NOW**: RESTART BACKEND SERVER to apply fixes (51d9618, a3fb88b)
2. Manual test with real user account
3. Implement streak freeze auto-use (backend cron)
4. Add offline sync trigger (connectivity listener)
5. Test edge cases (race conditions, errors)

---

**Status**: Code is ~90% done, Testing is ~10% done (manual API testing completed)
**Critical Path**: Backend restart → Full integration testing → Production deployment

## Recent Progress (This Session)

✅ **Manual API Testing** (commit 3d70637):
- Tested 5 endpoints with curl + DB verification
- Found 4 critical bugs, fixed 2
- Created comprehensive test report

✅ **Bug Fixes**:
- XP challenge generation for level 0 users (commit a3fb88b)
- Coins sync backend→frontend (commit 51d9618)

✅ **Features Added**:
- Celebration animations with confetti (commit 2621055)
- Fixed missing ChallengeCelebration widget

⚠️ **Blocked by**: Backend server needs restart to pick up schema & logic changes
