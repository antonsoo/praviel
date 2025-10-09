# Database Migration Best Practices

**Ancient Languages Platform — Alembic Migration Guide**

---

## Table of Contents

1. [Creating Migrations](#creating-migrations)
2. [Migration Safety](#migration-safety)
3. [Common Patterns](#common-patterns)
4. [Rollback Strategy](#rollback-strategy)
5. [Production Deployment](#production-deployment)

---

## Creating Migrations

### 1. Auto-Generate Migration

```bash
# Activate conda environment
conda activate ancient-languages-py312

# Auto-generate migration based on model changes
python -m alembic -c alembic.ini revision --autogenerate -m "add user_quests table"
```

**Alembic detects:**
- ✅ New tables
- ✅ New columns
- ✅ Column type changes
- ✅ Foreign key relationships

**Alembic DOES NOT detect:**
- ❌ Renamed columns (appears as drop + add)
- ❌ Renamed tables
- ❌ Check constraints
- ❌ Partial indexes

### 2. Manual Migration

```bash
# Create empty migration
python -m alembic -c alembic.ini revision -m "add partial index for active users"
```

**Edit generated file:**

```python
"""add partial index for active users

Revision ID: abc123def456
Revises: previous_revision_id
Create Date: 2025-10-09 12:00:00.000000

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision = 'abc123def456'
down_revision = 'previous_revision_id'
branch_labels = None
depends_on = None

def upgrade() -> None:
    # Create partial index (only active users)
    op.create_index(
        'idx_active_users',
        'users',
        ['id'],
        postgresql_where=sa.text('deleted_at IS NULL'),
    )

def downgrade() -> None:
    op.drop_index('idx_active_users', table_name='users')
```

---

## Migration Safety

### 1. Never Break Production

**❌ UNSAFE: Dropping columns**
```python
def upgrade():
    op.drop_column('users', 'old_field')  # Data loss!
```

**✅ SAFE: Deprecate → Migrate → Drop**
```python
# Migration 1: Add new column
def upgrade():
    op.add_column('users', sa.Column('new_field', sa.String(255), nullable=True))

# Migration 2 (days later): Backfill data
def upgrade():
    op.execute("UPDATE users SET new_field = old_field WHERE new_field IS NULL")

# Migration 3 (weeks later): Make non-nullable
def upgrade():
    op.alter_column('users', 'new_field', nullable=False)

# Migration 4 (months later): Drop old column
def upgrade():
    op.drop_column('users', 'old_field')
```

### 2. Avoid Long-Running Locks

**❌ UNSAFE: Adding NOT NULL column**
```python
def upgrade():
    # Locks table during backfill on large tables!
    op.add_column('learning_events', sa.Column('new_field', sa.String(255), nullable=False, server_default='default'))
```

**✅ SAFE: Multi-step approach**
```python
# Step 1: Add nullable column with default
def upgrade():
    op.add_column('learning_events', sa.Column('new_field', sa.String(255), nullable=True, server_default='default'))

# Step 2 (separate migration): Backfill in batches
def upgrade():
    op.execute("""
        UPDATE learning_events
        SET new_field = 'default'
        WHERE new_field IS NULL
        AND id IN (SELECT id FROM learning_events WHERE new_field IS NULL LIMIT 10000)
    """)
    # Run multiple times until complete

# Step 3: Make non-nullable
def upgrade():
    op.alter_column('learning_events', 'new_field', nullable=False)
```

### 3. Use Indexes Concurrently

**❌ UNSAFE: Blocking index creation**
```python
def upgrade():
    op.create_index('idx_user_progress', 'user_progress', ['user_id'])  # Locks table!
```

**✅ SAFE: Concurrent index**
```python
from alembic import op

def upgrade():
    op.create_index(
        'idx_user_progress',
        'user_progress',
        ['user_id'],
        postgresql_concurrently=True,
    )

# IMPORTANT: Must be run outside transaction
# Set this flag at top of migration file:
# revision = 'abc123'
# down_revision = 'def456'
# branch_labels = None
# depends_on = None

# AFTER imports, add:
# from alembic import context
# context.config.attributes['connection_args'] = {'isolation_level': 'AUTOCOMMIT'}
```

### 4. Test Rollback

```bash
# Apply migration
python -m alembic -c alembic.ini upgrade head

# Test rollback
python -m alembic -c alembic.ini downgrade -1

# Re-apply
python -m alembic -c alembic.ini upgrade head
```

**✅ Every migration MUST have a working `downgrade()` function.**

---

## Common Patterns

### 1. Adding a Table

```python
def upgrade():
    op.create_table(
        'user_quests',
        sa.Column('id', sa.Integer(), primary_key=True),
        sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('quest_type', sa.String(50), nullable=False),
        sa.Column('target_value', sa.Integer(), nullable=False),
        sa.Column('current_value', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('is_completed', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(), nullable=False, server_default=sa.text('NOW()')),
        sa.Column('completed_at', sa.DateTime(), nullable=True),
    )

    # Add indexes
    op.create_index('idx_user_quests_user_id', 'user_quests', ['user_id'])
    op.create_index('idx_user_quests_completed', 'user_quests', ['is_completed'], postgresql_where=sa.text('is_completed = false'))

def downgrade():
    op.drop_index('idx_user_quests_completed', table_name='user_quests')
    op.drop_index('idx_user_quests_user_id', table_name='user_quests')
    op.drop_table('user_quests')
```

### 2. Adding a Column

```python
def upgrade():
    op.add_column('users', sa.Column('display_name', sa.String(255), nullable=True))

def downgrade():
    op.drop_column('users', 'display_name')
```

### 3. Changing Column Type

```python
def upgrade():
    # Change VARCHAR(100) to TEXT
    op.alter_column('users', 'bio', type_=sa.Text())

def downgrade():
    op.alter_column('users', 'bio', type_=sa.String(100))
```

### 4. Adding Foreign Key

```python
def upgrade():
    op.create_foreign_key(
        'fk_user_progress_user',
        'user_progress',
        'users',
        ['user_id'],
        ['id'],
        ondelete='CASCADE',
    )

def downgrade():
    op.drop_constraint('fk_user_progress_user', 'user_progress', type_='foreignkey')
```

### 5. Data Migration

```python
def upgrade():
    # Migrate old format to new format
    connection = op.get_bind()
    connection.execute(sa.text("""
        UPDATE user_preferences
        SET llm_config = jsonb_build_object(
            'default_provider', llm_config->>'provider',
            'default_model', llm_config->>'model'
        )
        WHERE llm_config ? 'provider'
    """))

def downgrade():
    connection = op.get_bind()
    connection.execute(sa.text("""
        UPDATE user_preferences
        SET llm_config = jsonb_build_object(
            'provider', llm_config->>'default_provider',
            'model', llm_config->>'default_model'
        )
        WHERE llm_config ? 'default_provider'
    """))
```

---

## Rollback Strategy

### 1. Forward-Compatible Changes

**Prefer additive changes:**
- ✅ Add new columns (nullable)
- ✅ Add new tables
- ✅ Add new indexes
- ❌ Drop columns
- ❌ Drop tables
- ❌ Change column types (breaking)

### 2. Multi-Phase Deployments

**For breaking changes:**

1. **Phase 1:** Add new schema, keep old
2. **Phase 2:** Dual-write to both schemas
3. **Phase 3:** Backfill data
4. **Phase 4:** Read from new schema
5. **Phase 5:** Drop old schema

**Example: Rename `user.name` → `user.display_name`**

```python
# Migration 1: Add new column
def upgrade():
    op.add_column('users', sa.Column('display_name', sa.String(255), nullable=True))

# Application code (dual-write):
user.name = "Alice"
user.display_name = "Alice"  # Also write to new field

# Migration 2: Backfill
def upgrade():
    op.execute("UPDATE users SET display_name = name WHERE display_name IS NULL")

# Migration 3: Make non-nullable
def upgrade():
    op.alter_column('users', 'display_name', nullable=False)

# Application code: Switch reads to display_name

# Migration 4: Drop old column
def upgrade():
    op.drop_column('users', 'name')
```

### 3. Emergency Rollback

```bash
# Rollback last migration
python -m alembic -c alembic.ini downgrade -1

# Rollback to specific version
python -m alembic -c alembic.ini downgrade abc123def456

# Rollback all migrations
python -m alembic -c alembic.ini downgrade base
```

---

## Production Deployment

### 1. Pre-Deployment Checklist

- [ ] Migration tested locally
- [ ] Rollback tested locally
- [ ] No long-running locks (use concurrent indexes)
- [ ] No data loss (additive changes only)
- [ ] Backup database before deployment
- [ ] Dry-run on staging environment

### 2. Deployment Process

```bash
# 1. Backup database
pg_dump -h localhost -U postgres -d ancient_languages > backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Apply migrations
python -m alembic -c alembic.ini upgrade head

# 3. Verify schema
python -m alembic -c alembic.ini current

# 4. Smoke test application
curl http://localhost:8000/health
```

### 3. Monitoring

**Check migration status:**

```sql
-- View current Alembic version
SELECT * FROM alembic_version;

-- Check table sizes (detect unexpected growth)
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check for missing indexes
SELECT
    schemaname,
    tablename,
    attname,
    null_frac,
    avg_width,
    n_distinct
FROM pg_stats
WHERE schemaname = 'public'
AND null_frac < 0.1  -- Mostly non-null
AND n_distinct > 100  -- High cardinality
ORDER BY tablename, attname;
```

### 4. Rollback Plan

**Before deployment, document rollback steps:**

```markdown
## Rollback Plan for Migration abc123def456

**If deployment fails:**

1. Stop application
2. Rollback migration: `alembic downgrade -1`
3. Restart application
4. Verify: `curl http://localhost:8000/health`

**Data loss risk:** None (additive change only)
**Downtime:** ~30 seconds
```

---

## Troubleshooting

### Migration Conflicts

```bash
# Error: Multiple head revisions
alembic heads

# Merge heads
python -m alembic -c alembic.ini merge -m "merge conflict" head1 head2
```

### Stuck Migrations

```sql
-- Check for long-running queries
SELECT pid, usename, query, state, now() - query_start AS runtime
FROM pg_stat_activity
WHERE state = 'active'
ORDER BY runtime DESC;

-- Kill stuck migration
SELECT pg_terminate_backend(12345);  -- Replace with actual PID
```

### Schema Drift

```bash
# Compare database schema to models
python -m alembic -c alembic.ini check

# Auto-generate migration to fix drift
python -m alembic -c alembic.ini revision --autogenerate -m "fix schema drift"
```

---

## Best Practices Summary

### ✅ DO

- ✅ Test migrations locally before production
- ✅ Write reversible `downgrade()` functions
- ✅ Use concurrent indexes for large tables
- ✅ Add columns as nullable first, then backfill
- ✅ Backup database before deployment
- ✅ Document rollback plans

### ❌ DON'T

- ❌ Drop columns without multi-phase approach
- ❌ Add NOT NULL columns directly (causes locks)
- ❌ Change column types without testing
- ❌ Forget to test rollback
- ❌ Skip backups
- ❌ Run migrations without testing on staging

---

## Resources

- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [PostgreSQL Lock Monitoring](https://wiki.postgresql.org/wiki/Lock_Monitoring)
- [Zero-Downtime Migrations](https://stripe.com/blog/online-migrations)

---

**For project-specific migrations, see:** `backend/migrations/versions/`
