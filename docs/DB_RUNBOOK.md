# DB Runbook (local)

- Start Postgres:
  ```bash
  docker compose up -d db
  ```
- Apply migrations to head:
  ```bash
  alembic upgrade head
  ```
- Verify extensions:
  ```bash
  docker compose exec -T db psql -U postgres -d postgres -c "SELECT extname FROM pg_extension ORDER BY 1;"
  ```
- Reset (destructive):
  ```bash
  docker compose down -v && docker compose up -d db && alembic upgrade head
  ```
