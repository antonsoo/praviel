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

### 3. Pull-to-Refresh ✅ DONE
- ✅ Added RefreshIndicator to VibrantHomePage
- ✅ Pulls latest challenges from backend on swipe-down
- ✅ Uses AlwaysScrollableScrollPhysics for better UX
- ⚠️ Still need: weekly challenges pull-to-refresh (separate card)

### 4. Error Messages ✅ DONE
- ✅ Created ErrorMessages utility class with user-friendly messages
- ✅ Maps technical errors to helpful messages (network, auth, etc.)
- ✅ Integrated into DailyChallengeServiceV2
- ✅ Shows SnackBar with retry option on errors

### 5. Offline Sync Verification ✅ DONE
- ✅ Created ConnectivityService with connectivity_plus package
- ✅ Integrated in app_providers.dart
- ✅ Automatically calls syncPendingUpdates() when connection restored
- ✅ Queues failed updates in SharedPreferences for later sync

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

### 1. Streak Freeze Auto-Use Logic ✅ DONE
✅ **IMPLEMENTED** in [backend/app/tasks/scheduled_tasks.py](../backend/app/tasks/scheduled_tasks.py)
- Runs daily at midnight
- Checks if users completed challenges yesterday
- Auto-uses streak freeze if available, otherwise resets streak
- Integrated into FastAPI lifespan in main.py

### 2. Weekly Challenge Expiry Cleanup ✅ DONE
✅ **IMPLEMENTED** in [backend/app/tasks/scheduled_tasks.py](../backend/app/tasks/scheduled_tasks.py)
- Runs every Monday at midnight
- Marks expired weekly challenges
- New challenges generated on-demand when users request them

## Frontend Missing

### 1. Connectivity Listener ✅ DONE
✅ **IMPLEMENTED** in [client/flutter_reader/lib/services/connectivity_service.dart](../client/flutter_reader/lib/services/connectivity_service.dart)
- Auto-syncs when connection restored
- Integrated in app_providers.dart

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

✅ **Latest Session Completion** (AI Agent Session):
- ✅ Cleaned up 9,774 lines of garbage docs
- ✅ Implemented ConnectivityService for offline sync
- ✅ Added pull-to-refresh for challenges on home page
- ✅ Created ErrorMessages utility for user-friendly error handling
- ✅ Connected challenge leaderboard to backend API (removed mock data)
- ✅ Added ChallengeLeaderboardResponse models to challenges_api.dart
- ✅ Implemented scheduled tasks for streak freeze auto-use (daily at midnight)
- ✅ Implemented scheduled tasks for weekly challenge cleanup (Mondays at midnight)
- ✅ Integrated task runner into FastAPI lifespan
- ✅ Updated TODO_CRITICAL with final status

⚠️ **Blocked by**: Backend server needs restart to pick up schema & logic changes
