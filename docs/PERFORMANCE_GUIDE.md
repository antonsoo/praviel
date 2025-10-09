# Performance Optimization Guide

**Ancient Languages Platform — Best Practices for Speed & Efficiency**

---

## Table of Contents

1. [Backend Performance](#backend-performance)
2. [Frontend Performance](#frontend-performance)
3. [Database Optimization](#database-optimization)
4. [Network Optimization](#network-optimization)
5. [Monitoring & Profiling](#monitoring--profiling)

---

## Backend Performance

### 1. API Response Caching

**Recommendation:** Cache lesson generation results to avoid repeated AI calls.

```python
# backend/app/lesson/router.py
from functools import lru_cache
from hashlib import sha256

@lru_cache(maxsize=1000)
def get_cached_lesson(text_ref: str, difficulty: str) -> dict:
    """Cache lesson generation by text reference + difficulty."""
    cache_key = sha256(f"{text_ref}:{difficulty}".encode()).hexdigest()
    # Check Redis/DB cache first
    # If miss, generate and store
    pass
```

### 2. Database Connection Pooling

**Current:** SQLAlchemy with connection pooling enabled.

**Optimization:** Tune pool size based on load.

```python
# backend/app/db/session.py
engine = create_engine(
    settings.DATABASE_URL,
    pool_size=20,          # Increase for high concurrency
    max_overflow=40,       # Allow burst traffic
    pool_pre_ping=True,    # Check connection health
    pool_recycle=3600,     # Recycle connections every hour
)
```

### 3. Async Database Queries

**Recommendation:** Use `asyncpg` for non-blocking queries in high-traffic endpoints.

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine

async_engine = create_async_engine(
    "postgresql+asyncpg://user:pass@localhost/db",
    echo=False,
    future=True,
)

async def get_user_progress_async(user_id: int):
    async with AsyncSession(async_engine) as session:
        result = await session.execute(
            select(UserProgress).where(UserProgress.user_id == user_id)
        )
        return result.scalars().first()
```

### 4. API Request Batching

**Recommendation:** Allow clients to batch multiple operations.

```python
@router.post("/batch")
async def batch_operations(ops: List[BatchOp], user: User = Depends(get_current_user)):
    """Execute multiple API operations in one request.

    Example:
        [
            {"op": "get_progress", "params": {}},
            {"op": "get_achievements", "params": {}},
            {"op": "get_skills", "params": {}}
        ]
    """
    results = await asyncio.gather(
        *[execute_op(op, user) for op in ops]
    )
    return {"results": results}
```

### 5. Reduce AI Provider Latency

**Current:** Sequential AI calls (OpenAI → Anthropic fallback).

**Optimization:** Parallel requests with circuit breaker pattern.

```python
import asyncio
from circuitbreaker import circuit

@circuit(failure_threshold=5, recovery_timeout=60)
async def call_openai(prompt: str) -> str:
    # ...

@circuit(failure_threshold=5, recovery_timeout=60)
async def call_anthropic(prompt: str) -> str:
    # ...

async def get_ai_response_fast(prompt: str) -> str:
    """Try multiple providers in parallel, return first success."""
    tasks = [call_openai(prompt), call_anthropic(prompt)]
    for future in asyncio.as_completed(tasks):
        try:
            return await future
        except Exception:
            continue
    raise Exception("All providers failed")
```

---

## Frontend Performance

### 1. Use `const` Constructors

**Impact:** Reduces widget rebuilds by ~30%.

```dart
// ❌ BAD: Creates new widget every rebuild
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Hello'),
    );
  }
}

// ✅ GOOD: Reuses widget instance
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Hello');
  }
}
```

### 2. ListView.builder for Long Lists

**Impact:** Lazy loading improves scroll performance.

```dart
// ❌ BAD: Loads all 1000 items immediately
ListView(
  children: List.generate(1000, (i) => ListTile(title: Text('Item $i'))),
)

// ✅ GOOD: Only builds visible items
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
)
```

### 3. Memoize Expensive Computations

**Impact:** Avoid recalculating values on every rebuild.

```dart
import 'package:flutter_hooks/flutter_hooks.dart';

class ExpensiveWidget extends HookWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ useMemoized caches result until dependencies change
    final expensiveValue = useMemoized(
      () => computeExpensiveValue(),
      [dependency1, dependency2],
    );

    return Text('$expensiveValue');
  }
}
```

### 4. Optimize Images

**Recommendation:** Use cached network images and resize on server.

```dart
import 'package:cached_network_image.dart';

CachedNetworkImage(
  imageUrl: 'https://example.com/image.jpg',
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 300,  // Resize to fit container
  maxHeightDiskCache: 300,
)
```

### 5. Avoid Rebuilding Entire Tree

**Use Riverpod Selectors:**

```dart
// ❌ BAD: Rebuilds entire widget when ANY part of user changes
final user = ref.watch(userProvider);

// ✅ GOOD: Only rebuilds when username changes
final username = ref.watch(userProvider.select((user) => user.username));
```

---

## Database Optimization

### 1. Add Missing Indexes

**Recommendation:** Index frequently queried columns.

```sql
-- Speed up user progress queries
CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);

-- Speed up learning events time-series queries
CREATE INDEX idx_learning_events_timestamp ON learning_events(timestamp DESC);

-- Speed up skill lookups
CREATE INDEX idx_user_skills_topic ON user_skills(user_id, topic);
```

### 2. Use Partial Indexes

**Recommendation:** Index only active/relevant rows.

```sql
-- Only index non-deleted users
CREATE INDEX idx_active_users ON users(id) WHERE deleted_at IS NULL;

-- Only index due SRS cards
CREATE INDEX idx_due_srs_cards ON user_srs_cards(user_id, next_review_at)
WHERE next_review_at <= NOW();
```

### 3. Query Optimization

**Use EXPLAIN ANALYZE:**

```sql
EXPLAIN ANALYZE
SELECT * FROM user_progress WHERE user_id = 123;

-- Look for:
-- - Sequential Scans (bad) vs Index Scans (good)
-- - High execution time (> 100ms)
-- - Missing indexes
```

### 4. Denormalize for Read-Heavy Queries

**Example:** Store aggregated stats in `user_progress` instead of computing on every request.

```python
# Instead of:
xp_total = db.query(func.sum(LearningEvent.xp_earned)).filter(
    LearningEvent.user_id == user_id
).scalar()

# Store in user_progress.xp_total and increment on each event:
user_progress.xp_total += xp_earned
db.commit()
```

### 5. Use Materialized Views

**Recommendation:** Precompute expensive aggregations.

```sql
CREATE MATERIALIZED VIEW user_stats_summary AS
SELECT
    user_id,
    COUNT(DISTINCT lesson_id) AS total_lessons,
    SUM(xp_earned) AS total_xp,
    AVG(accuracy) AS avg_accuracy
FROM learning_events
GROUP BY user_id;

-- Refresh periodically (cron job)
REFRESH MATERIALIZED VIEW user_stats_summary;
```

---

## Network Optimization

### 1. Enable Gzip Compression

**Recommendation:** Compress API responses.

```python
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(GZipMiddleware, minimum_size=1000)
```

### 2. Use HTTP/2

**Recommendation:** Multiplexed requests over single connection.

```python
# Deploy with Uvicorn + HTTP/2
uvicorn app.main:app --host 0.0.0.0 --port 8000 --http h2
```

### 3. CDN for Static Assets

**Recommendation:** Serve Flutter web build via CDN (Cloudflare, AWS CloudFront).

### 4. Reduce Payload Size

**Recommendation:** Only send required fields.

```python
# ❌ BAD: Returns entire user object (20+ fields)
@router.get("/users/me")
async def get_me(user: User = Depends(get_current_user)):
    return user

# ✅ GOOD: Return minimal profile
@router.get("/users/me/profile")
async def get_profile(user: User = Depends(get_current_user)):
    return {
        "id": user.id,
        "username": user.username,
        "xp": user.progress.xp_total,
        "level": user.progress.current_level,
    }
```

---

## Monitoring & Profiling

### 1. Backend Profiling

**Use cProfile:**

```python
import cProfile
import pstats

profiler = cProfile.Profile()
profiler.enable()

# Run expensive operation
generate_lesson(text_ref="Il.1.1-1.100")

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(20)  # Top 20 slowest functions
```

### 2. Database Query Monitoring

**Enable slow query logging:**

```sql
-- PostgreSQL
ALTER SYSTEM SET log_min_duration_statement = 1000;  -- Log queries > 1s
SELECT pg_reload_conf();

-- View slow queries
SELECT query, mean_exec_time, calls
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

### 3. Frontend Performance

**Use Flutter DevTools:**

```bash
flutter run --profile
# Open DevTools → Performance tab
# Record timeline during scroll/navigation
# Look for:
# - Frame render time > 16ms (jank)
# - Widget rebuilds (highlight repaints)
# - Memory leaks
```

### 4. API Response Time Monitoring

**Add middleware:**

```python
import time
from fastapi import Request

@app.middleware("http")
async def log_request_time(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time

    # Log slow requests
    if duration > 1.0:
        logger.warning(f"Slow request: {request.url.path} ({duration:.2f}s)")

    response.headers["X-Process-Time"] = str(duration)
    return response
```

---

## Performance Checklist

### Backend
- [ ] Enable Redis caching for lessons/searches
- [ ] Tune database connection pool (20-40 connections)
- [ ] Add indexes on user_id, timestamp, topic columns
- [ ] Enable gzip compression
- [ ] Use async database queries for read-heavy endpoints
- [ ] Implement circuit breaker for AI providers

### Frontend
- [ ] Use `const` constructors everywhere possible
- [ ] Replace `ListView` with `ListView.builder`
- [ ] Memoize expensive computations with `useMemoized`
- [ ] Optimize images (CachedNetworkImage + resize)
- [ ] Use Riverpod selectors to minimize rebuilds

### Database
- [ ] Add missing indexes (see section above)
- [ ] Create partial indexes for filtered queries
- [ ] Denormalize aggregated stats (xp_total, total_lessons)
- [ ] Use materialized views for dashboards
- [ ] Enable slow query logging

### Network
- [ ] Deploy CDN for Flutter web assets
- [ ] Enable HTTP/2
- [ ] Reduce payload sizes (minimal DTOs)
- [ ] Batch API requests when possible

---

## Target Metrics

| Metric | Target | Current |
|--------|--------|---------|
| API p95 latency | < 200ms | ~300ms |
| Lesson generation | < 5s | ~8s |
| Database queries | < 50ms | ~80ms |
| Flutter frame rate | 60 FPS | ~55 FPS |
| Time to interactive | < 2s | ~3.5s |

---

**For detailed profiling, see:** [PROFILING.md](PROFILING.md) (coming soon)
