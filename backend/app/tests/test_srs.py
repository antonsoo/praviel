"""Tests for SRS (Spaced Repetition System) API endpoints."""

from datetime import datetime, timedelta

import pytest
from sqlalchemy import select

from app.db.user_models import UserProgress, UserSRSCard

# Import fixtures from conftest_auth
pytest_plugins = ["app.tests.conftest_auth"]


@pytest.mark.asyncio
async def test_create_srs_card(client, auth_headers, db_session):
    """Test creating a new SRS flashcard."""
    response = await client.post(
        "/api/v1/srs/cards",
        json={
            "front": "What is μῆνις?",
            "back": "wrath, anger (especially of gods)",
            "deck": "iliad_vocab",
            "tags": ["homer", "noun", "book1"],
        },
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()

    # Verify response structure
    assert data["front"] == "What is μῆνις?"
    assert data["back"] == "wrath, anger (especially of gods)"
    assert data["deck"] == "iliad_vocab"
    assert data["tags"] == ["homer", "noun", "book1"]
    assert data["state"] == "new"
    assert data["reps"] == 0
    assert data["lapses"] == 0
    assert data["stability"] == 0.0
    assert data["difficulty"] == 0.0

    # Verify database record
    card = await db_session.execute(select(UserSRSCard).where(UserSRSCard.id == data["id"]))
    card = card.scalar_one()
    assert card.front == "What is μῆνις?"
    assert card.user_id == 1  # Test user ID


@pytest.mark.asyncio
async def test_get_due_cards_empty(client, auth_headers):
    """Test getting due cards when none exist."""
    response = await client.get("/api/v1/srs/cards/due", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data == []


@pytest.mark.asyncio
async def test_get_due_cards(client, auth_headers, db_session):
    """Test getting due cards."""
    # Create test cards
    now = datetime.utcnow()
    user_id = 1  # Test user

    cards = [
        UserSRSCard(
            user_id=user_id,
            front="Card 1 (new)",
            back="Answer 1",
            deck="test",
            state="new",
            due_date=now,  # Due now
            stability=0.0,
            difficulty=0.0,
            elapsed_days=0,
            scheduled_days=0,
            reps=0,
            lapses=0,
        ),
        UserSRSCard(
            user_id=user_id,
            front="Card 2 (learning)",
            back="Answer 2",
            deck="test",
            state="learning",
            due_date=now - timedelta(hours=1),  # Overdue
            stability=1.0,
            difficulty=3.0,
            elapsed_days=0,
            scheduled_days=1,
            reps=1,
            lapses=0,
        ),
        UserSRSCard(
            user_id=user_id,
            front="Card 3 (not due)",
            back="Answer 3",
            deck="test",
            state="review",
            due_date=now + timedelta(days=7),  # Not due yet
            stability=10.0,
            difficulty=2.0,
            elapsed_days=3,
            scheduled_days=7,
            reps=5,
            lapses=0,
        ),
    ]

    for card in cards:
        db_session.add(card)
    await db_session.commit()

    # Get due cards
    response = await client.get("/api/v1/srs/cards/due", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()

    # Should return 2 cards (new and learning), not the review card
    assert len(data) == 2

    # Verify ordering: new cards first, then learning
    assert data[0]["state"] == "new"
    assert data[1]["state"] == "learning"


@pytest.mark.asyncio
async def test_review_srs_card_quality_1(client, auth_headers, db_session):
    """Test reviewing a card with quality 1 (Again)."""
    # Create a new card
    now = datetime.utcnow()
    card = UserSRSCard(
        user_id=1,
        front="Test card",
        back="Test answer",
        deck="test",
        state="new",
        due_date=now,
        stability=0.0,
        difficulty=0.0,
        elapsed_days=0,
        scheduled_days=0,
        reps=0,
        lapses=0,
    )
    db_session.add(card)
    await db_session.commit()
    await db_session.refresh(card)

    # Review with quality 1 (Again)
    response = await client.post(
        f"/api/v1/srs/cards/{card.id}/review",
        json={"card_id": card.id, "quality": 1},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()

    # Verify state transition: new → learning
    assert data["new_state"] == "learning"
    assert data["days_until_next_review"] == 0  # Review again soon

    # Verify lapses tracked
    await db_session.refresh(card)
    assert card.lapses == 1
    assert card.reps == 1
    assert card.state == "learning"


@pytest.mark.asyncio
async def test_review_srs_card_quality_3(client, auth_headers, db_session):
    """Test reviewing a card with quality 3 (Good)."""
    now = datetime.utcnow()
    card = UserSRSCard(
        user_id=1,
        front="Test card",
        back="Test answer",
        deck="test",
        state="new",
        due_date=now,
        stability=0.0,
        difficulty=0.0,
        elapsed_days=0,
        scheduled_days=0,
        reps=0,
        lapses=0,
    )
    db_session.add(card)
    await db_session.commit()
    await db_session.refresh(card)

    # Review with quality 3 (Good)
    response = await client.post(
        f"/api/v1/srs/cards/{card.id}/review",
        json={"card_id": card.id, "quality": 3},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()

    # Verify state transition: new → learning
    assert data["new_state"] == "learning"
    assert data["days_until_next_review"] >= 1

    # Verify no lapses
    await db_session.refresh(card)
    assert card.lapses == 0
    assert card.reps == 1
    assert card.stability > 0


@pytest.mark.asyncio
async def test_review_srs_card_quality_4(client, auth_headers, db_session):
    """Test reviewing a card with quality 4 (Easy) - should skip to review state."""
    now = datetime.utcnow()
    card = UserSRSCard(
        user_id=1,
        front="Test card",
        back="Test answer",
        deck="test",
        state="new",
        due_date=now,
        stability=0.0,
        difficulty=0.0,
        elapsed_days=0,
        scheduled_days=0,
        reps=0,
        lapses=0,
    )
    db_session.add(card)
    await db_session.commit()
    await db_session.refresh(card)

    # Review with quality 4 (Easy)
    response = await client.post(
        f"/api/v1/srs/cards/{card.id}/review",
        json={"card_id": card.id, "quality": 4},
        headers=auth_headers,
    )

    assert response.status_code == 200
    data = response.json()

    # Verify state transition: new → review (skip learning)
    assert data["new_state"] == "review"
    assert data["days_until_next_review"] >= 4

    await db_session.refresh(card)
    assert card.state == "review"
    assert card.difficulty < 0  # Easy cards have lower difficulty


@pytest.mark.asyncio
async def test_review_grants_xp(client, auth_headers, db_session):
    """Test that reviewing a card grants XP."""
    # Get initial XP
    progress = await db_session.execute(select(UserProgress).where(UserProgress.user_id == 1))
    progress = progress.scalar_one_or_none()
    initial_xp = progress.xp_total if progress else 0

    # Create and review a card
    now = datetime.utcnow()
    card = UserSRSCard(
        user_id=1,
        front="Test",
        back="Answer",
        deck="test",
        state="new",
        due_date=now,
        stability=0.0,
        difficulty=0.0,
        elapsed_days=0,
        scheduled_days=0,
        reps=0,
        lapses=0,
    )
    db_session.add(card)
    await db_session.commit()
    await db_session.refresh(card)

    # Review with quality 3 (Good) = 12 XP
    await client.post(
        f"/api/v1/srs/cards/{card.id}/review",
        json={"card_id": card.id, "quality": 3},
        headers=auth_headers,
    )

    # Verify XP granted
    await db_session.refresh(progress)
    assert progress.xp_total == initial_xp + 12


@pytest.mark.asyncio
async def test_get_srs_stats(client, auth_headers, db_session):
    """Test getting SRS statistics."""
    now = datetime.utcnow()
    user_id = 1

    # Create cards in different states
    cards = [
        UserSRSCard(
            user_id=user_id,
            front=f"Card {i}",
            back=f"Answer {i}",
            deck="deck_a",
            state=state,
            due_date=due,
            stability=1.0,
            difficulty=2.0,
            elapsed_days=0,
            scheduled_days=1,
            reps=0,
            lapses=0,
        )
        for i, (state, due) in enumerate(
            [
                ("new", now),
                ("new", now),
                ("learning", now),
                ("review", now + timedelta(days=7)),
                ("review", now),
            ]
        )
    ]

    for card in cards:
        db_session.add(card)
    await db_session.commit()

    response = await client.get("/api/v1/srs/stats", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()

    assert len(data) == 1  # One deck
    deck_stats = data[0]
    assert deck_stats["deck"] == "deck_a"
    assert deck_stats["total_cards"] == 5
    assert deck_stats["new_cards"] == 2
    assert deck_stats["learning_cards"] == 1
    assert deck_stats["review_cards"] == 2
    assert deck_stats["due_today"] == 4  # All except the future review card


@pytest.mark.asyncio
async def test_delete_srs_card(client, auth_headers, db_session):
    """Test deleting an SRS card."""
    card = UserSRSCard(
        user_id=1,
        front="Delete me",
        back="Answer",
        deck="test",
        state="new",
        due_date=datetime.utcnow(),
        stability=0.0,
        difficulty=0.0,
        elapsed_days=0,
        scheduled_days=0,
        reps=0,
        lapses=0,
    )
    db_session.add(card)
    await db_session.commit()
    await db_session.refresh(card)

    # Delete card
    response = await client.delete(f"/api/v1/srs/cards/{card.id}", headers=auth_headers)

    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Card deleted successfully"

    # Verify card is gone
    deleted_card = await db_session.execute(select(UserSRSCard).where(UserSRSCard.id == card.id))
    assert deleted_card.scalar_one_or_none() is None


@pytest.mark.asyncio
async def test_review_nonexistent_card(client, auth_headers):
    """Test reviewing a card that doesn't exist."""
    response = await client.post(
        "/api/v1/srs/cards/99999/review",
        json={"card_id": 99999, "quality": 3},
        headers=auth_headers,
    )

    assert response.status_code == 404


@pytest.mark.asyncio
async def test_review_invalid_quality(client, auth_headers, db_session):
    """Test reviewing with invalid quality rating."""
    card = UserSRSCard(
        user_id=1,
        front="Test",
        back="Answer",
        deck="test",
        state="new",
        due_date=datetime.utcnow(),
        stability=0.0,
        difficulty=0.0,
        elapsed_days=0,
        scheduled_days=0,
        reps=0,
        lapses=0,
    )
    db_session.add(card)
    await db_session.commit()
    await db_session.refresh(card)

    # Try quality 5 (invalid, must be 1-4)
    response = await client.post(
        f"/api/v1/srs/cards/{card.id}/review",
        json={"card_id": card.id, "quality": 5},
        headers=auth_headers,
    )

    assert response.status_code == 422  # Validation error


@pytest.mark.asyncio
async def test_fsrs_algorithm_progression(client, auth_headers, db_session):
    """Test FSRS algorithm schedules cards correctly over multiple reviews."""
    now = datetime.utcnow()
    card = UserSRSCard(
        user_id=1,
        front="Progressive test",
        back="Answer",
        deck="test",
        state="new",
        due_date=now,
        stability=0.0,
        difficulty=0.0,
        elapsed_days=0,
        scheduled_days=0,
        reps=0,
        lapses=0,
    )
    db_session.add(card)
    await db_session.commit()
    await db_session.refresh(card)

    # Review 1: Good (quality 3) - new → learning
    response1 = await client.post(
        f"/api/v1/srs/cards/{card.id}/review",
        json={"card_id": card.id, "quality": 3},
        headers=auth_headers,
    )
    data1 = response1.json()
    assert data1["new_state"] == "learning"
    first_interval = data1["days_until_next_review"]

    # Review 2: Good (quality 3) - learning → review
    await db_session.refresh(card)
    response2 = await client.post(
        f"/api/v1/srs/cards/{card.id}/review",
        json={"card_id": card.id, "quality": 3},
        headers=auth_headers,
    )
    data2 = response2.json()
    assert data2["new_state"] == "review"
    second_interval = data2["days_until_next_review"]

    # Verify intervals are increasing (spaced repetition)
    assert second_interval > first_interval

    # Review 3: Good (quality 3) - review → review (longer interval)
    await db_session.refresh(card)
    response3 = await client.post(
        f"/api/v1/srs/cards/{card.id}/review",
        json={"card_id": card.id, "quality": 3},
        headers=auth_headers,
    )
    data3 = response3.json()
    assert data3["new_state"] == "review"
    third_interval = data3["days_until_next_review"]

    # Verify intervals keep increasing
    assert third_interval >= second_interval

    # Verify final card state
    await db_session.refresh(card)
    assert card.reps == 3
    assert card.lapses == 0
    assert card.state == "review"
