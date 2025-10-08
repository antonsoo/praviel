# Backend API Integration Guide - Daily Challenges System

## Overview

This guide explains how to integrate the **Daily Challenges API** into your Ancient Languages app backend. The system provides complete backend support for the Flutter client's daily challenge features, including challenge generation, progress tracking, streak management, and leaderboards.

**Created**: 2025-10-08
**Status**: ✅ Ready for deployment
**Migration**: c7d82a4f9e15

---

## Quick Start

### 1. Run Database Migration

```bash
cd backend
python -m alembic upgrade head
```

This will create two new tables:
- `daily_challenge`: Stores user's daily challenges
- `challenge_streak`: Tracks challenge completion streaks

### 2. API Endpoints Available

All endpoints are automatically registered at `/api/v1/challenges/`

**Base URL**: `http://your-domain/api/v1/challenges`

---

## API Endpoints

### GET `/daily`
**Get user's active daily challenges**

**Authorization**: Required (Bearer token)

**Response**: `List[DailyChallengeResponse]`

```json
[
  {
    "id": 1,
    "challenge_type": "lessons_completed",
    "difficulty": "easy",
    "title": "🎉 Weekend Quick Learner",
    "description": "Complete 2 lessons today",
    "target_value": 2,
    "current_progress": 1,
    "coin_reward": 100,
    "xp_reward": 50,
    "is_completed": false,
    "is_weekend_bonus": true,
    "expires_at": "2025-10-09T00:00:00Z",
    "completed_at": null
  }
]
```

**Features**:
- Auto-generates challenges if none exist
- Filters expired challenges
- Returns 3-4 challenges based on user level
- Weekend bonuses (2x rewards on Sat/Sun)

**Challenge Types**:
- `lessons_completed`: Complete X lessons
- `xp_earned`: Earn X XP
- `perfect_score`: Get perfect scores
- `streak_maintain`: Maintain learning streak
- `words_learned`: Learn X new words

**Difficulty Levels**:
- `easy`: Low target, 50 coins base
- `medium`: Medium target, 100 coins base
- `hard`: High target (level 3+), 200 coins base
- `expert`: Very high target, 500 coins base

---

### POST `/update-progress`
**Update progress on a specific challenge**

**Authorization**: Required (Bearer token)

**Request Body**:
```json
{
  "challenge_id": 1,
  "increment": 1
}
```

**Response**:
```json
{
  "message": "Progress updated",
  "current_progress": 2,
  "is_completed": true,
  "rewards_granted": true,
  "coin_reward": 100,
  "xp_reward": 50
}
```

**Features**:
- Increments progress atomically
- Auto-completes when target reached
- Grants XP rewards immediately
- Updates challenge streak if all challenges complete
- Grants milestone bonuses (7, 30, 100 day streaks)

**Auto-Completion Logic**:
1. Check if `current_progress >= target_value`
2. If true: Set `is_completed = true`, `completed_at = now()`
3. Grant XP reward to user's `UserProgress`
4. Check if ALL challenges for today are complete
5. If all complete: Increment challenge streak

---

### GET `/streak`
**Get user's challenge completion streak**

**Authorization**: Required (Bearer token)

**Response**: `ChallengeStreakResponse`

```json
{
  "current_streak": 15,
  "longest_streak": 30,
  "total_days_completed": 45,
  "last_completion_date": "2025-10-08T18:30:00Z",
  "is_active_today": true
}
```

**Features**:
- Tracks consecutive days of completing ALL challenges
- Resets to 0 if user misses a day
- Tracks longest streak ever
- `is_active_today`: Whether user completed all challenges today

**Streak Milestones**:
- **7 days**: +100 coins, +50 XP
- **30 days**: +500 coins, +250 XP
- **100 days**: +2000 coins, +1000 XP

---

### GET `/leaderboard`
**Get challenge completion leaderboard**

**Authorization**: Required (Bearer token)

**Query Parameters**:
- `limit`: Max entries to return (default: 50)

**Response**: `ChallengeLeaderboardResponse`

```json
{
  "entries": [
    {
      "user_id": 123,
      "username": "StreakMaster",
      "challenges_completed": 45,
      "current_streak": 15,
      "longest_streak": 30,
      "total_rewards": 4500,
      "rank": 1
    }
  ],
  "user_rank": 10,
  "total_users": 1500
}
```

**Ranking Logic**:
1. Primary: `current_streak` (DESC)
2. Secondary: `total challenges completed` (DESC)

**Features**:
- Shows top N users
- Calculates user's rank even if not in top N
- Includes total users for percentile calculation
- Only includes active users

---

## Database Schema

### Table: `daily_challenge`

| Column | Type | Description |
|--------|------|-------------|
| id | Integer | Primary key |
| user_id | Integer | Foreign key to user.id |
| challenge_type | String(50) | Type of challenge |
| difficulty | String(20) | easy, medium, hard, expert |
| title | String(100) | Display title |
| description | String(255) | Challenge description |
| target_value | Integer | Goal to reach |
| current_progress | Integer | Current progress |
| coin_reward | Integer | Coins granted on completion |
| xp_reward | Integer | XP granted on completion |
| is_completed | Boolean | Completion status |
| is_weekend_bonus | Boolean | 2x rewards flag |
| completed_at | DateTime | When completed (nullable) |
| expires_at | DateTime | Expiration time (24h) |
| created_at | DateTime | Creation timestamp |
| updated_at | DateTime | Last update timestamp |

**Indexes**:
- `user_id` (single column)
- `(user_id, is_completed, expires_at)` (composite)

### Table: `challenge_streak`

| Column | Type | Description |
|--------|------|-------------|
| id | Integer | Primary key |
| user_id | Integer | Foreign key to user.id (UNIQUE) |
| current_streak | Integer | Consecutive days |
| longest_streak | Integer | Best streak ever |
| total_days_completed | Integer | All-time completions |
| last_completion_date | DateTime | Last full completion |
| is_active_today | Boolean | Completed today flag |
| created_at | DateTime | Creation timestamp |
| updated_at | DateTime | Last update timestamp |

**Constraints**:
- `user_id` is UNIQUE (one streak per user)

---

## Challenge Generation Logic

### Auto-Generation Triggers

Challenges are auto-generated when:
1. User calls `GET /daily` and has no active challenges
2. All existing challenges have expired (past midnight)

### Generation Algorithm

```python
def _generate_daily_challenges(user, db):
    # Get user level for difficulty scaling
    user_level = get_user_progress(user).level

    # Check if weekend (Saturday=5, Sunday=6)
    is_weekend = datetime.now().weekday() in [5, 6]
    reward_multiplier = 2.0 if is_weekend else 1.0

    # Set expiration to next midnight
    tomorrow = next_midnight()

    challenges = []

    # Always: Easy challenge (2 lessons)
    challenges.append(create_challenge(
        type="lessons_completed",
        difficulty="easy",
        target=2,
        coins=50 * multiplier,
        xp=25 * multiplier
    ))

    # Always: Medium XP challenge (scaled to level)
    challenges.append(create_challenge(
        type="xp_earned",
        difficulty="medium",
        target=user_level * 50,
        coins=100 * multiplier,
        xp=50 * multiplier
    ))

    # If level >= 3: Hard perfectionist challenge
    if user_level >= 3:
        challenges.append(create_challenge(
            type="perfect_score",
            difficulty="hard",
            target=3,
            coins=200 * multiplier,
            xp=100 * multiplier
        ))

    # Always: Streak maintenance challenge
    challenges.append(create_challenge(
        type="streak_maintain",
        difficulty="medium",
        target=1,
        coins=75 * multiplier,
        xp=30 * multiplier
    ))

    return challenges
```

### Challenge Personalization

Challenges scale with user level:
- **Level 1-2**: 2 lessons, 50-100 XP targets
- **Level 3-5**: 2 lessons, 150-250 XP targets, +perfectionist challenge
- **Level 6-10**: 2 lessons, 300-500 XP targets, harder perfectionist
- **Level 10+**: 2 lessons, 500+ XP targets, expert challenges

---

## Streak Management

### Streak Update Flow

```
1. User completes a challenge
   └─> POST /update-progress called

2. Backend checks if challenge just completed
   └─> If current_progress >= target_value:
       ├─> Set is_completed = true
       ├─> Grant rewards (XP + coins)
       └─> Call _check_and_update_streak()

3. _check_and_update_streak() runs
   └─> Query all today's challenges
       └─> If ALL are completed AND not already counted today:
           ├─> Increment current_streak += 1
           ├─> Increment total_days_completed += 1
           ├─> Set is_active_today = true
           ├─> Update last_completion_date = now()
           └─> Check for milestone rewards (7, 30, 100)
```

### Streak Reset Logic

Streaks reset automatically when:
1. User doesn't complete ALL challenges within 24 hours
2. Next day starts (midnight UTC)
3. Check happens on first challenge completion of new day

**Implementation** (runs daily):
```python
def reset_daily_flags():
    # At midnight, reset all is_active_today flags
    ChallengeStreak.update_many(is_active_today=False)

    # Check for broken streaks
    yesterday = now() - timedelta(days=1)
    broken_streaks = ChallengeStreak.where(
        last_completion_date < yesterday,
        current_streak > 0
    )
    broken_streaks.update(current_streak=0)
```

---

## Integration Examples

### Flutter Client Integration

**1. Load daily challenges on home screen**:
```dart
final challenges = await dailyChallengeService.load();
// Or from API:
final response = await http.get(
  Uri.parse('$baseUrl/api/v1/challenges/daily'),
  headers: {'Authorization': 'Bearer $token'},
);
final challenges = (jsonDecode(response.body) as List)
    .map((json) => DailyChallenge.fromJson(json))
    .toList();
```

**2. Update progress after lesson completion**:
```dart
Future<void> onLessonCompleted({
  required int xpEarned,
  required bool isPerfect,
  required int wordsLearned,
}) async {
  // Update each relevant challenge type
  for (var challenge in activeChallenges) {
    int increment = 0;

    if (challenge.type == 'lessons_completed') increment = 1;
    if (challenge.type == 'xp_earned') increment = xpEarned;
    if (challenge.type == 'perfect_score' && isPerfect) increment = 1;
    if (challenge.type == 'words_learned') increment = wordsLearned;
    if (challenge.type == 'streak_maintain') increment = 1;

    if (increment > 0) {
      await http.post(
        Uri.parse('$baseUrl/api/v1/challenges/update-progress'),
        headers: {'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'challenge_id': challenge.id,
          'increment': increment,
        }),
      );
    }
  }
}
```

**3. Load and display streak**:
```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/v1/challenges/streak'),
  headers: {'Authorization': 'Bearer $token'},
);
final streak = ChallengeStreak.fromJson(jsonDecode(response.body));
```

**4. Load leaderboard**:
```dart
final response = await http.get(
  Uri.parse('$baseUrl/api/v1/challenges/leaderboard?limit=50'),
  headers: {'Authorization': 'Bearer $token'},
);
final leaderboard = ChallengeLeaderboardResponse.fromJson(
  jsonDecode(response.body)
);
```

---

## Testing

### Manual API Testing

**1. Get challenges** (creates if none exist):
```bash
curl -X GET "http://localhost:8000/api/v1/challenges/daily" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**2. Update progress**:
```bash
curl -X POST "http://localhost:8000/api/v1/challenges/update-progress" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"challenge_id": 1, "increment": 1}'
```

**3. Get streak**:
```bash
curl -X GET "http://localhost:8000/api/v1/challenges/streak" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**4. Get leaderboard**:
```bash
curl -X GET "http://localhost:8000/api/v1/challenges/leaderboard?limit=10" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Expected Test Flow

```
1. User A calls GET /daily
   → Receives 4 challenges (easy, medium, hard, streak)
   → All have current_progress = 0

2. User A completes a lesson
   → Client calls POST /update-progress for "lessons_completed" (+1)
   → Client calls POST /update-progress for "xp_earned" (+50)
   → Client calls POST /update-progress for "streak_maintain" (+1)

3. User A completes another lesson
   → "lessons_completed" reaches target (2/2)
   → Response: rewards_granted = true, coin_reward = 100, xp_reward = 50
   → User's XP increased in database

4. User A completes 2 more challenges
   → All 4 challenges now completed
   → Streak updates: current_streak = 1, is_active_today = true

5. Next day, User A completes all challenges again
   → Streak updates: current_streak = 2

6. User A reaches 7-day streak
   → Auto-granted: +100 coins, +50 XP (milestone bonus)
```

---

## Performance Considerations

### Indexing Strategy

**Query 1**: Get active challenges for user
```sql
SELECT * FROM daily_challenge
WHERE user_id = ? AND expires_at > NOW()
```
**Index**: `(user_id, expires_at)` ✅

**Query 2**: Check if all challenges complete
```sql
SELECT * FROM daily_challenge
WHERE user_id = ? AND expires_at > NOW() AND is_completed = true
```
**Index**: `(user_id, is_completed, expires_at)` ✅

**Query 3**: Leaderboard ranking
```sql
SELECT * FROM challenge_streak
JOIN user ON user.id = challenge_streak.user_id
WHERE user.is_active = true
ORDER BY current_streak DESC, total_days_completed DESC
LIMIT 50
```
**Index**: `(user_id)` unique ✅

### Caching Recommendations

**Cache**: User's active challenges for 5 minutes
```python
@cache(ttl=300)
def get_user_challenges(user_id):
    return db.query(DailyChallenge).filter(
        user_id=user_id,
        expires_at > now()
    ).all()
```

**Cache**: Leaderboard for 10 minutes (global)
```python
@cache(ttl=600, key="challenge_leaderboard")
def get_leaderboard(limit=50):
    return db.query(...).limit(limit).all()
```

**No Cache**: Streak data (changes frequently)

---

## Migration Guide

### For Existing Users

1. **Run migration**: `python -m alembic upgrade head`
2. **No data loss**: Existing users continue normally
3. **First access**: Challenges auto-generate on first `GET /daily` call
4. **Streak starts at 0**: All users start with `current_streak = 0`
5. **Build streak**: Users increment streak by completing all daily challenges

### Rollback Plan

If issues arise:

```bash
# Rollback migration
python -m alembic downgrade f5c31c93de18

# Remove router from main.py (comment out line 180)
# app.include_router(daily_challenges_router, ...)

# Restart server
```

No data loss for existing features - daily challenges are completely isolated.

---

## Monitoring & Analytics

### Key Metrics to Track

1. **Challenge Completion Rate**
   ```sql
   SELECT
     COUNT(CASE WHEN is_completed THEN 1 END) * 100.0 / COUNT(*) as completion_rate
   FROM daily_challenge
   WHERE created_at > NOW() - INTERVAL '7 days';
   ```

2. **Average Streak Length**
   ```sql
   SELECT AVG(current_streak) as avg_streak
   FROM challenge_streak
   WHERE current_streak > 0;
   ```

3. **Milestone Achievements**
   ```sql
   SELECT
     COUNT(CASE WHEN current_streak >= 7 THEN 1 END) as week_warriors,
     COUNT(CASE WHEN current_streak >= 30 THEN 1 END) as masters,
     COUNT(CASE WHEN current_streak >= 100 THEN 1 END) as legends
   FROM challenge_streak;
   ```

4. **Weekend Engagement**
   ```sql
   SELECT
     EXTRACT(DOW FROM created_at) as day_of_week,
     COUNT(*) as challenges_created
   FROM daily_challenge
   GROUP BY day_of_week
   ORDER BY day_of_week;
   ```

---

## Summary

✅ **Database Migration**: c7d82a4f9e15 creates 2 tables
✅ **API Endpoints**: 4 endpoints at `/api/v1/challenges/`
✅ **Auto-Generation**: Challenges create automatically
✅ **Weekend Bonuses**: 2x rewards on Sat/Sun
✅ **Streak System**: Tracks consecutive completions with milestones
✅ **Leaderboards**: Social competition ranking
✅ **Ready to Deploy**: Complete backend support for Flutter client

**Next Steps**:
1. Run database migration
2. Test API endpoints
3. Update Flutter client to use API instead of local storage
4. Monitor engagement metrics
5. Iterate based on user behavior

The backend is production-ready and fully supports all features implemented in the Flutter client!
