# Social Features & Leaderboard Implementation

## 🎯 Overview

Comprehensive social features system including global/friends/local leaderboards, friend management, competitive challenges, and power-up shop. Fully integrated with existing gamification system.

## ✅ What's Been Implemented

### Backend (Python/FastAPI)

#### 1. Database Models ([backend/app/db/social_models.py](../backend/app/db/social_models.py))

**Friendship System:**
- Bidirectional friend connections
- Status: pending, accepted, blocked
- Track who initiated the request
- Timestamps for creation and acceptance

**Friend Challenges:**
- Competitive challenges between friends
- Types: xp_race, lesson_count, streak
- Progress tracking for both participants
- Auto-expiration and winner determination

**Leaderboard Rankings:**
- Cached leaderboard entries for performance
- Support for global, friends, and regional boards
- Periodic recalculation (recommended: every 5 minutes)
- Efficient queries with proper indexing

**Power-Up System:**
- Inventory management (quantity + active count)
- Usage tracking with expiration
- Types: streak_freeze (24h), xp_boost (1h), hint_reveal (instant)

#### 2. REST API ([backend/app/api/routers/social.py](../backend/app/api/routers/social.py))

**Leaderboard Endpoints:**
```
GET /api/v1/social/leaderboard/{board_type}?limit=50
  - board_type: global | friends | local
  - Returns: rankings, current_user_rank, total_users
```

**Friend Management:**
```
GET  /api/v1/social/friends
POST /api/v1/social/friends/add
  - Body: { "friend_username": "username" }
POST /api/v1/social/friends/{friend_id}/accept
DELETE /api/v1/social/friends/{friend_id}
```

**Challenges:**
```
POST /api/v1/social/challenges/create
  - Body: {
      "friend_id": int,
      "challenge_type": "xp_race | lesson_count | streak",
      "target_value": int,
      "duration_hours": int (default 24)
    }
GET /api/v1/social/challenges
  - Returns: active and pending challenges
```

**Power-Ups:**
```
GET  /api/v1/social/power-ups
  - Returns: user's power-up inventory
POST /api/v1/social/power-ups/purchase
  - Body: { "power_up_type": "streak_freeze | xp_boost | hint_reveal", "quantity": int }
  - Costs: streak_freeze=100 XP, xp_boost=200 XP, hint_reveal=50 XP
POST /api/v1/social/power-ups/{power_up_type}/activate
  - Activates a power-up from inventory
```

#### 3. Database Migration ([backend/migrations/versions/f5c31c93de18_add_social_features_and_leaderboard.py](../backend/migrations/versions/f5c31c93de18_add_social_features_and_leaderboard.py))

**Tables Created:**
- `friendship` - Friend connections with status tracking
- `friend_challenge` - Competitive challenges between friends
- `leaderboard_entry` - Cached leaderboard rankings
- `power_up_inventory` - User power-up ownership
- `power_up_usage` - Power-up activation history

**Indexes for Performance:**
- Composite indexes on (user_id, status) for friendships
- Indexes on (board_type, rank) for leaderboards
- Indexes on (user_id, is_active) for power-up usage

### Frontend (Flutter/Dart)

#### 1. Social API Client ([client/flutter_reader/lib/services/social_api.dart](../client/flutter_reader/lib/services/social_api.dart))

**Full API Integration:**
- Type-safe request/response models
- Authentication token support
- Comprehensive error handling
- All social endpoints covered

**Response Models:**
- `LeaderboardResponse` - Rankings with user position
- `FriendResponse` - Friend info with online status
- `ChallengeResponse` - Challenge details and progress
- `PowerUpInventoryResponse` - Power-up quantities

#### 2. Provider Integration ([client/flutter_reader/lib/app_providers.dart](../client/flutter_reader/lib/app_providers.dart))

```dart
final leaderboardServiceProvider = FutureProvider<LeaderboardService>((ref) async {
  final progressService = await ref.watch(progressServiceProvider.future);
  final service = LeaderboardService(progressService: progressService);
  ref.onDispose(service.dispose);
  return service;
});
```

#### 3. UI Integration ([client/flutter_reader/lib/pages/vibrant_home_page.dart](../client/flutter_reader/lib/pages/vibrant_home_page.dart))

**Leaderboard Quick Action Card:**
- Golden gradient to stand out
- "Compete with friends" subtitle
- Direct navigation to LeaderboardPage
- Positioned after Achievements card

**Existing Pages Ready:**
- [LeaderboardPage](../client/flutter_reader/lib/pages/leaderboard_page.dart) - Full leaderboard UI with tabs
- [ProgressStatsPage](../client/flutter_reader/lib/pages/progress_stats_page.dart) - Already integrated

## 🚀 How to Use

### Run Database Migration

```powershell
# Windows
cd backend
python -m alembic upgrade head
```

### Start the Backend

```powershell
cd backend
uvicorn app.main:app --reload
```

The social endpoints will be available at `/api/v1/social/*`

### Test the API

```bash
# Get global leaderboard
curl http://localhost:8000/api/v1/social/leaderboard/global?limit=50

# Add a friend
curl -X POST http://localhost:8000/api/v1/social/friends/add \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"friend_username": "scholar123"}'

# Purchase a streak freeze
curl -X POST http://localhost:8000/api/v1/social/power-ups/purchase \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"power_up_type": "streak_freeze", "quantity": 1}'
```

### Flutter Integration

The leaderboard is now accessible from the home page via the "Leaderboard" quick action card. The LeaderboardService will automatically use the real API when authentication is implemented.

## 📋 Next Steps

### Priority 1: Connect to Real API
1. Update `LeaderboardService` to use `SocialApi` instead of mock data
2. Wire up authentication tokens in `SocialApi`
3. Handle offline/error states gracefully

### Priority 2: Friend Management UI
1. Create `FriendsPage` with tabs for friends/pending/suggestions
2. Add friend search functionality
3. Implement friend request notifications

### Priority 3: Power-Up Shop
1. Create `PowerUpShopPage` with purchase UI
2. Show active power-ups in profile
3. Add visual indicators when boosts are active

### Priority 4: Challenge UI
1. Create challenge creation modal
2. Show active challenges in home page
3. Real-time progress updates
4. Challenge completion celebrations

## 🎨 UI/UX Features

**Leaderboard Page Highlights:**
- 3 tabs: Global, Friends, Local
- Animated rank changes
- Current user highlight
- XP gap to next rank shown
- Pull-to-refresh support
- Beautiful empty states

**Power-Up Costs:**
- **Streak Freeze** (100 XP): Protects streak for 24 hours
- **XP Boost** (200 XP): 2x XP multiplier for 1 hour
- **Hint Reveal** (50 XP): Instant hint in current lesson

**Challenge Types:**
- **XP Race**: First to reach target XP wins
- **Lesson Count**: Complete N lessons first
- **Streak**: Maintain streak for duration

## 🔧 Technical Details

**Performance Optimizations:**
- Leaderboard caching with periodic refresh
- Indexed database queries
- Efficient friendship lookups
- Power-up usage tracking for analytics

**Security:**
- All endpoints require authentication
- Friend requests must be mutual
- Can't challenge non-friends
- XP deductions are validated

**Scalability:**
- Cached leaderboards reduce DB load
- Regional leaderboards for localization
- Efficient pagination support
- Background refresh jobs ready

## 📊 Database Schema

```sql
-- Friendship (bidirectional)
friendship (id, user_id, friend_id, status, initiated_by_user_id, accepted_at, created_at, updated_at)
UNIQUE (user_id, friend_id)
INDEX (user_id, status)

-- Friend Challenges
friend_challenge (id, initiator_user_id, opponent_user_id, challenge_type, target_value,
                  initiator_progress, opponent_progress, status, winner_user_id,
                  starts_at, expires_at, completed_at, created_at, updated_at)
INDEX (initiator_user_id, opponent_user_id)
INDEX (status)

-- Leaderboard Cache
leaderboard_entry (id, user_id, board_type, region, rank, xp_total, level, calculated_at)
INDEX (board_type, rank)
INDEX (user_id, board_type)
INDEX (board_type, region, rank)

-- Power-Up Inventory
power_up_inventory (id, user_id, power_up_type, quantity, active_count, created_at, updated_at)
UNIQUE (user_id, power_up_type)

-- Power-Up Usage
power_up_usage (id, user_id, power_up_type, activated_at, expires_at, is_active, created_at, updated_at)
INDEX (user_id, is_active)
```

## 🎯 Success Metrics

**Engagement:**
- Friend connections per user
- Daily challenge participation rate
- Leaderboard view frequency
- Power-up purchase conversion

**Retention:**
- Friends with matched learning schedules
- Challenge completion rate
- Streak freeze usage (indicates commitment)
- Return rate after friend challenges

**Monetization Ready:**
- Power-up shop infrastructure complete
- XP economy balanced
- Premium power-ups can be added
- Social features drive engagement

## 🤝 Contributing

When adding new social features:

1. Add database models to `social_models.py`
2. Create API endpoints in `routers/social.py`
3. Generate Alembic migration
4. Update `SocialApi` in Flutter
5. Create/update UI pages
6. Add to `app_providers.dart`
7. Update this documentation

## 📖 Related Documentation

- [Gamification System](./gamification_ideas.md)
- [Database Models](../backend/app/db/user_models.py)
- [API Authentication](../backend/app/security/)
- [Flutter Services](../client/flutter_reader/lib/services/)

---

**Status:** ✅ Backend Complete | ⚠️ Frontend Integration Needed
**Last Updated:** 2025-10-08
**Migration:** `f5c31c93de18_add_social_features_and_leaderboard`
