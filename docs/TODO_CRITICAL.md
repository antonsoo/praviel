# Critical TODO - What's Actually Missing

## Testing (HIGH PRIORITY) ⚠️

### Must Test End-to-End:
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

## Missing Backend Content (MEDIUM PRIORITY)

### Language Data Not Yet Seeded
- Database structure ready but empty for:
  - Homer's Iliad (canonical Greek texts)
  - LSJ Lexicon entries
  - Smyth Grammar references
- **Impact**: Lesson generation works but uses seed/placeholder data only
- **Recommendation**: Seed with real Perseus Digital Library data

### AI Provider Issues
- OpenAI GPT-5: Works but occasionally times out (intermittent)
- Google Gemini: Fixed (commit a9fde0d) - now fully working
- Anthropic Claude: Fully working, fastest response time (~6s)

## Next Actions

### HIGH PRIORITY (Before Production Launch):
1. End-to-end testing with real user accounts
2. Seed database with actual Greek/Latin/Hebrew content
3. Test Flutter mobile app → backend integration
4. Add automated pytest suite for CI/CD

### MEDIUM PRIORITY (Post-Launch):
- Add double-or-nothing UI (backend ready, needs frontend dialog)
- Wire friend challenge progress auto-updates on lesson completion
- Investigate OpenAI intermittent timeout issues
- Add Latin and Hebrew lesson generation

### LOW PRIORITY (Future Enhancements):
- Push notifications for challenge expiry
- Analytics dashboard
- Additional power-ups (XP boost, hints, skip)

---

## Current Status
- Backend: 95% (all APIs working)
- Frontend: 95% (Flutter UI complete)
- Integration: 90% (needs E2E testing)
- Content: 20% (DB structure ready, needs Perseus data)

## Next Agent Priorities
**HIGH** (critical path):
1. End-to-end testing with real user accounts
2. Seed database with Perseus Digital Library content
3. Test Flutter mobile app → backend integration

**MEDIUM** (post-launch):
- Add double-or-nothing UI dialog (backend ready)
- Investigate OpenAI intermittent timeouts
- Add Latin/Hebrew lesson generation
