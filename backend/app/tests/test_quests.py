"""Tests for Quests API endpoints."""

from datetime import datetime, timedelta

import pytest
from sqlalchemy import select

from app.db.user_models import UserProgress, UserQuest

# Import fixtures from conftest_auth
pytest_plugins = ["app.tests.conftest_auth"]


@pytest.mark.asyncio
async def test_create_quest(client, auth_headers, db_session):
    """Test creating a new quest."""
    response = await client.post(
        "/api/v1/quests/",
        json={
            "quest_type": "lesson_count",
            "target_value": 10,
            "duration_days": 7,
        },
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()

    # Verify response structure
    assert data["quest_type"] == "lesson_count"
    assert data["target_value"] == 10
    assert data["current_progress"] == 0
    assert not data["is_completed"]
    assert not data["is_failed"]
    assert "title" in data
    assert "description" in data
    assert data["xp_reward"] > 0
    assert data["coin_reward"] > 0

    # Verify database record
    quest = await db_session.execute(select(UserQuest).where(UserQuest.id == data["id"]))
    quest = quest.scalar_one()
    assert quest.user_id == 1
    assert quest.target_value == 10


@pytest.mark.asyncio
async def test_create_quest_with_custom_title(client, auth_headers):
    """Test creating a quest with custom title and description."""
    response = await client.post(
        "/api/v1/quests/",
        json={
            "quest_type": "daily_streak",
            "target_value": 30,
            "duration_days": 30,
            "title": "My Custom Quest",
            "description": "My custom description",
        },
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "My Custom Quest"
    assert data["description"] == "My custom description"


@pytest.mark.asyncio
async def test_list_quests_empty(client, auth_headers):
    """Test listing quests when none exist."""
    response = await client.get("/api/v1/quests/", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data == []


@pytest.mark.asyncio
async def test_list_active_quests(client, auth_headers, db_session):
    """Test listing only active quests (excludes completed/failed)."""
    now = datetime.utcnow()
    user_id = 1

    quests = [
        UserQuest(
            user_id=user_id,
            quest_type="lesson_count",
            target_value=10,
            current_progress=5,
            title="Active Quest",
            description="In progress",
            xp_reward=1000,
            coin_reward=500,
            is_completed=False,
            is_failed=False,
            started_at=now,
            expires_at=now + timedelta(days=7),
        ),
        UserQuest(
            user_id=user_id,
            quest_type="xp_milestone",
            target_value=1000,
            current_progress=1000,
            title="Completed Quest",
            description="Done",
            xp_reward=500,
            coin_reward=250,
            is_completed=True,
            is_failed=False,
            started_at=now - timedelta(days=7),
            expires_at=now,
            completed_at=now,
        ),
        UserQuest(
            user_id=user_id,
            quest_type="daily_streak",
            target_value=7,
            current_progress=3,
            title="Failed Quest",
            description="Expired",
            xp_reward=700,
            coin_reward=350,
            is_completed=False,
            is_failed=True,
            started_at=now - timedelta(days=10),
            expires_at=now - timedelta(days=3),
        ),
    ]

    for quest in quests:
        db_session.add(quest)
    await db_session.commit()

    # List active quests only
    response = await client.get("/api/v1/quests/", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()

    # Should return only the active quest
    assert len(data) == 1
    assert data[0]["title"] == "Active Quest"
    assert data[0]["progress_percentage"] == 50.0


@pytest.mark.asyncio
async def test_list_all_quests_including_completed(client, auth_headers, db_session):
    """Test listing all quests including completed."""
    now = datetime.utcnow()
    user_id = 1

    quests = [
        UserQuest(
            user_id=user_id,
            quest_type="lesson_count",
            target_value=10,
            current_progress=5,
            title="Active",
            description="In progress",
            xp_reward=1000,
            coin_reward=500,
            is_completed=False,
            is_failed=False,
            started_at=now,
            expires_at=now + timedelta(days=7),
        ),
        UserQuest(
            user_id=user_id,
            quest_type="xp_milestone",
            target_value=1000,
            current_progress=1000,
            title="Completed",
            description="Done",
            xp_reward=500,
            coin_reward=250,
            is_completed=True,
            is_failed=False,
            started_at=now - timedelta(days=7),
            expires_at=now,
            completed_at=now,
        ),
    ]

    for quest in quests:
        db_session.add(quest)
    await db_session.commit()

    # List all quests
    response = await client.get("/api/v1/quests/?include_completed=true", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()

    assert len(data) == 2


@pytest.mark.asyncio
async def test_get_specific_quest(client, auth_headers, db_session):
    """Test getting a specific quest by ID."""
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="skill_mastery",
        target_value=5,
        current_progress=2,
        title="Test Quest",
        description="Test description",
        xp_reward=2000,
        coin_reward=1000,
        is_completed=False,
        is_failed=False,
        started_at=now,
        expires_at=now + timedelta(days=30),
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    response = await client.get(f"/api/v1/quests/{quest.id}", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data["id"] == quest.id
    assert data["quest_type"] == "skill_mastery"
    assert data["current_progress"] == 2
    assert data["target_value"] == 5
    assert data["progress_percentage"] == 40.0


@pytest.mark.asyncio
async def test_get_nonexistent_quest(client, auth_headers):
    """Test getting a quest that doesn't exist."""
    response = await client.get("/api/v1/quests/99999", headers=auth_headers)

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_update_quest_progress(client, auth_headers, db_session):
    """Test updating progress on a quest."""
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="lesson_count",
        target_value=10,
        current_progress=5,
        title="Progress Test",
        description="Testing progress",
        xp_reward=1000,
        coin_reward=500,
        is_completed=False,
        is_failed=False,
        started_at=now,
        expires_at=now + timedelta(days=7),
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    # Update progress
    response = await client.put(
        f"/api/v1/quests/{quest.id}",
        json={"increment": 3},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["current_progress"] == 8
    assert data["progress_percentage"] == 80.0

    # Verify database
    await db_session.refresh(quest)
    assert quest.current_progress == 8


@pytest.mark.asyncio
async def test_update_quest_progress_capped_at_target(client, auth_headers, db_session):
    """Test that progress is capped at target value."""
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="lesson_count",
        target_value=10,
        current_progress=8,
        title="Cap Test",
        description="Testing cap",
        xp_reward=1000,
        coin_reward=500,
        is_completed=False,
        is_failed=False,
        started_at=now,
        expires_at=now + timedelta(days=7),
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    # Try to add 5, but should cap at 10
    response = await client.put(
        f"/api/v1/quests/{quest.id}",
        json={"increment": 5},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()
    assert data["current_progress"] == 10
    assert data["progress_percentage"] == 100.0


@pytest.mark.asyncio
async def test_complete_quest(client, auth_headers, db_session):
    """Test completing a quest and receiving rewards."""
    # Get initial XP/coins
    progress = await db_session.execute(select(UserProgress).where(UserProgress.user_id == 1))
    progress = progress.scalar_one_or_none()
    initial_xp = progress.xp_total if progress else 0
    initial_coins = progress.coins if progress else 0

    # Create quest at completion threshold
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="lesson_count",
        target_value=10,
        current_progress=10,  # Already at target
        title="Complete Me",
        description="Ready to complete",
        xp_reward=1000,
        coin_reward=500,
        is_completed=False,
        is_failed=False,
        started_at=now,
        expires_at=now + timedelta(days=7),
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    # Complete quest
    response = await client.post(f"/api/v1/quests/{quest.id}/complete", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Quest completed!"
    assert data["rewards_granted"]
    assert data["xp_earned"] == 1000
    assert data["coins_earned"] == 500
    assert data["total_xp"] == initial_xp + 1000
    assert data["total_coins"] == initial_coins + 500

    # Verify quest marked as completed
    await db_session.refresh(quest)
    assert quest.is_completed
    assert quest.completed_at is not None


@pytest.mark.asyncio
async def test_complete_quest_insufficient_progress(client, auth_headers, db_session):
    """Test that quest cannot be completed without meeting target."""
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="lesson_count",
        target_value=10,
        current_progress=5,  # Not enough
        title="Not Ready",
        description="Not done yet",
        xp_reward=1000,
        coin_reward=500,
        is_completed=False,
        is_failed=False,
        started_at=now,
        expires_at=now + timedelta(days=7),
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    # Try to complete
    response = await client.post(f"/api/v1/quests/{quest.id}/complete", headers=auth_headers)

    assert response.status_code == 400
    assert "not complete" in response.json()["detail"].lower()


@pytest.mark.asyncio
async def test_complete_already_completed_quest(client, auth_headers, db_session):
    """Test that completing an already-completed quest is idempotent."""
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="lesson_count",
        target_value=10,
        current_progress=10,
        title="Already Done",
        description="Completed",
        xp_reward=1000,
        coin_reward=500,
        is_completed=True,
        is_failed=False,
        started_at=now - timedelta(days=7),
        expires_at=now,
        completed_at=now - timedelta(days=1),
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    response = await client.post(f"/api/v1/quests/{quest.id}/complete", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert not data["rewards_granted"]


@pytest.mark.asyncio
async def test_abandon_quest(client, auth_headers, db_session):
    """Test abandoning a quest."""
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="daily_streak",
        target_value=30,
        current_progress=10,
        title="Abandon Me",
        description="Too hard",
        xp_reward=3000,
        coin_reward=1500,
        is_completed=False,
        is_failed=False,
        started_at=now,
        expires_at=now + timedelta(days=30),
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    # Abandon quest
    response = await client.delete(f"/api/v1/quests/{quest.id}", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Quest abandoned"

    # Verify marked as failed
    await db_session.refresh(quest)
    assert quest.is_failed


@pytest.mark.asyncio
async def test_cannot_abandon_completed_quest(client, auth_headers, db_session):
    """Test that completed quests cannot be abandoned."""
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="lesson_count",
        target_value=10,
        current_progress=10,
        title="Completed",
        description="Done",
        xp_reward=1000,
        coin_reward=500,
        is_completed=True,
        is_failed=False,
        started_at=now - timedelta(days=7),
        expires_at=now,
        completed_at=now,
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    response = await client.delete(f"/api/v1/quests/{quest.id}", headers=auth_headers)

    assert response.status_code == 400


@pytest.mark.asyncio
async def test_expired_quest_marked_as_failed(client, auth_headers, db_session):
    """Test that expired quests are automatically marked as failed."""
    now = datetime.utcnow()
    quest = UserQuest(
        user_id=1,
        quest_type="lesson_count",
        target_value=10,
        current_progress=5,
        title="Expired",
        description="Ran out of time",
        xp_reward=1000,
        coin_reward=500,
        is_completed=False,
        is_failed=False,
        started_at=now - timedelta(days=10),
        expires_at=now - timedelta(days=1),  # Expired yesterday
    )
    db_session.add(quest)
    await db_session.commit()
    await db_session.refresh(quest)

    # List quests (should trigger expiration check)
    response = await client.get("/api/v1/quests/?include_completed=true", headers=auth_headers)

    assert response.status_code == 200

    # Verify quest marked as failed
    await db_session.refresh(quest)
    assert quest.is_failed


@pytest.mark.asyncio
async def test_quest_reward_scaling(client, auth_headers):
    """Test that quest rewards scale with difficulty and duration."""
    # Short easy quest
    response1 = await client.post(
        "/api/v1/quests/",
        json={
            "quest_type": "lesson_count",
            "target_value": 5,
            "duration_days": 7,
        },
        headers=auth_headers,
    )
    data1 = response1.json()

    # Long hard quest
    response2 = await client.post(
        "/api/v1/quests/",
        json={
            "quest_type": "lesson_count",
            "target_value": 50,
            "duration_days": 60,
        },
        headers=auth_headers,
    )
    data2 = response2.json()

    # Verify rewards scale
    assert data2["xp_reward"] > data1["xp_reward"]
    assert data2["coin_reward"] > data1["coin_reward"]


@pytest.mark.asyncio
async def test_quest_types_generate_appropriate_text(client, auth_headers):
    """Test that different quest types generate appropriate titles/descriptions."""
    quest_types = ["daily_streak", "xp_milestone", "lesson_count", "skill_mastery"]

    for quest_type in quest_types:
        response = await client.post(
            "/api/v1/quests/",
            json={
                "quest_type": quest_type,
                "target_value": 10,
                "duration_days": 30,
            },
            headers=auth_headers,
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["title"]) > 0
        assert len(data["description"]) > 0
        assert (
            quest_type.replace("_", " ") in data["title"].lower()
            or quest_type.replace("_", " ") in data["description"].lower()
        )
