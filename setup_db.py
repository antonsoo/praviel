#!/usr/bin/env python3
"""Setup database user and database for the Ancient Languages app."""

import asyncio
import getpass
import sys

from sqlalchemy.ext.asyncio import create_async_engine


async def setup_database():
    """Create database user and database if they don't exist."""

    # Get postgres password from user
    print("PostgreSQL Database Setup")
    print("=" * 50)
    postgres_password = getpass.getpass("Enter PostgreSQL 'postgres' user password: ")

    # Connect as postgres superuser
    admin_url = f"postgresql+asyncpg://postgres:{postgres_password}@localhost:5432/postgres"

    print("\nConnecting to PostgreSQL as postgres user...")
    try:
        engine = create_async_engine(admin_url, isolation_level="AUTOCOMMIT", echo=True)

        async with engine.connect() as conn:
            # Check if user exists
            print("\nChecking if user 'app' exists...")
            result = await conn.execute("SELECT 1 FROM pg_user WHERE usename = 'app'")
            user_exists = result.fetchone() is not None

            if not user_exists:
                print("Creating user 'app' with password 'app'...")
                await conn.execute("CREATE USER app WITH PASSWORD 'app'")
                print("✓ User 'app' created")
            else:
                print("✓ User 'app' already exists")

            # Check if database exists
            print("\nChecking if database 'app' exists...")
            result = await conn.execute("SELECT 1 FROM pg_database WHERE datname = 'app'")
            db_exists = result.fetchone() is not None

            if not db_exists:
                print("Creating database 'app'...")
                await conn.execute("CREATE DATABASE app OWNER app")
                print("✓ Database 'app' created")
            else:
                print("✓ Database 'app' already exists")
                # Make sure app user owns it
                await conn.execute("ALTER DATABASE app OWNER TO app")
                print("✓ Ensured 'app' user owns database")

        await engine.dispose()
        print("\n✅ Database setup complete!")
        print("\nYou can now run: uvicorn backend.app.main:app --reload")
        return True

    except Exception as e:
        print(f"\n❌ Error: {e}", file=sys.stderr)
        print("\nPossible solutions:", file=sys.stderr)
        print("1. Make sure PostgreSQL is running", file=sys.stderr)
        print("2. Update the postgres password in this script (line 11)", file=sys.stderr)
        print("3. Or manually create the user and database:", file=sys.stderr)
        print("   CREATE USER app WITH PASSWORD 'app';", file=sys.stderr)
        print("   CREATE DATABASE app OWNER app;", file=sys.stderr)
        return False


if __name__ == "__main__":
    success = asyncio.run(setup_database())
    sys.exit(0 if success else 1)
