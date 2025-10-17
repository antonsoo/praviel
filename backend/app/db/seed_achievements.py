"""Seed achievements into the database.

This module defines 50+ achievements that users can unlock through various activities.
Achievements are categorized by type: streak, lesson, xp, skill, quest, etc.

Usage:
    python -m app.db.seed_achievements
"""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.user_models import UserAchievement


@dataclass
class AchievementDefinition:
    """Definition of an achievement."""

    achievement_type: str  # badge, milestone, collection
    achievement_id: str  # unique identifier
    title: str
    description: str
    icon: str  # emoji or icon name
    tier: int = 1  # 1=bronze, 2=silver, 3=gold, 4=platinum
    xp_reward: int = 0
    coin_reward: int = 0
    unlock_criteria: dict | None = None  # JSON metadata for unlock logic


# ---------------------------------------------------------------------
# Achievement Definitions (50+ achievements)
# ---------------------------------------------------------------------

ACHIEVEMENTS: list[AchievementDefinition] = [
    # --- FIRST TIME ACHIEVEMENTS (Onboarding) ---
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="first_lesson",
        title="First Steps",
        description="Complete your very first lesson",
        icon="🎓",
        tier=1,
        xp_reward=25,
        coin_reward=10,
        unlock_criteria={"lessons_completed": 1},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="first_perfect",
        title="Flawless Victory",
        description="Complete a lesson with 100% accuracy",
        icon="💯",
        tier=1,
        xp_reward=50,
        coin_reward=20,
        unlock_criteria={"perfect_lessons": 1},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="first_streak",
        title="Building Momentum",
        description="Complete lessons 2 days in a row",
        icon="🔥",
        tier=1,
        xp_reward=30,
        coin_reward=15,
        unlock_criteria={"streak_days": 2},
    ),
    # --- STREAK ACHIEVEMENTS ---
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="streak_3",
        title="3-Day Warrior",
        description="Maintain a 3-day learning streak",
        icon="🔥",
        tier=1,
        xp_reward=50,
        coin_reward=25,
        unlock_criteria={"streak_days": 3},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="streak_7",
        title="Week Warrior",
        description="Maintain a 7-day learning streak",
        icon="🔥",
        tier=2,
        xp_reward=150,
        coin_reward=75,
        unlock_criteria={"streak_days": 7},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="streak_14",
        title="Two-Week Titan",
        description="Maintain a 14-day learning streak",
        icon="🔥",
        tier=2,
        xp_reward=300,
        coin_reward=150,
        unlock_criteria={"streak_days": 14},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="streak_30",
        title="Month Master",
        description="Maintain a 30-day learning streak",
        icon="🔥",
        tier=3,
        xp_reward=750,
        coin_reward=400,
        unlock_criteria={"streak_days": 30},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="streak_60",
        title="Two-Month Legend",
        description="Maintain a 60-day learning streak",
        icon="🔥",
        tier=3,
        xp_reward=1500,
        coin_reward=800,
        unlock_criteria={"streak_days": 60},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="streak_100",
        title="Centurion of Learning",
        description="Maintain a 100-day learning streak",
        icon="🏆",
        tier=4,
        xp_reward=3000,
        coin_reward=2000,
        unlock_criteria={"streak_days": 100},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="streak_365",
        title="Year-Long Scholar",
        description="Maintain a 365-day learning streak",
        icon="👑",
        tier=4,
        xp_reward=10000,
        coin_reward=5000,
        unlock_criteria={"streak_days": 365},
    ),
    # --- LESSON COUNT ACHIEVEMENTS ---
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="lessons_10",
        title="Novice Learner",
        description="Complete 10 lessons",
        icon="📚",
        tier=1,
        xp_reward=100,
        coin_reward=50,
        unlock_criteria={"lessons_completed": 10},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="lessons_25",
        title="Dedicated Student",
        description="Complete 25 lessons",
        icon="📚",
        tier=2,
        xp_reward=250,
        coin_reward=125,
        unlock_criteria={"lessons_completed": 25},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="lessons_50",
        title="Scholarly Pursuer",
        description="Complete 50 lessons",
        icon="📚",
        tier=2,
        xp_reward=500,
        coin_reward=250,
        unlock_criteria={"lessons_completed": 50},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="lessons_100",
        title="Hundred Lessons Strong",
        description="Complete 100 lessons",
        icon="📚",
        tier=3,
        xp_reward=1000,
        coin_reward=500,
        unlock_criteria={"lessons_completed": 100},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="lessons_250",
        title="Academic Excellence",
        description="Complete 250 lessons",
        icon="🎓",
        tier=3,
        xp_reward=2500,
        coin_reward=1250,
        unlock_criteria={"lessons_completed": 250},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="lessons_500",
        title="Master Scholar",
        description="Complete 500 lessons",
        icon="🏛️",
        tier=4,
        xp_reward=5000,
        coin_reward=2500,
        unlock_criteria={"lessons_completed": 500},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="lessons_1000",
        title="Grand Luminary",
        description="Complete 1000 lessons - true dedication!",
        icon="👑",
        tier=4,
        xp_reward=10000,
        coin_reward=5000,
        unlock_criteria={"lessons_completed": 1000},
    ),
    # --- XP MILESTONES ---
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="xp_100",
        title="First Century",
        description="Earn 100 XP",
        icon="⭐",
        tier=1,
        coin_reward=10,
        unlock_criteria={"xp_total": 100},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="xp_500",
        title="Five Hundred Strong",
        description="Earn 500 XP",
        icon="⭐",
        tier=1,
        coin_reward=50,
        unlock_criteria={"xp_total": 500},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="xp_1000",
        title="Thousand Points",
        description="Earn 1,000 XP",
        icon="⭐",
        tier=2,
        coin_reward=100,
        unlock_criteria={"xp_total": 1000},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="xp_5000",
        title="Five Thousand Milestone",
        description="Earn 5,000 XP",
        icon="🌟",
        tier=2,
        coin_reward=500,
        unlock_criteria={"xp_total": 5000},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="xp_10000",
        title="Ten Thousand Strong",
        description="Earn 10,000 XP",
        icon="🌟",
        tier=3,
        coin_reward=1000,
        unlock_criteria={"xp_total": 10000},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="xp_25000",
        title="Quarter Million",
        description="Earn 25,000 XP - a true scholar!",
        icon="✨",
        tier=3,
        coin_reward=2500,
        unlock_criteria={"xp_total": 25000},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="xp_50000",
        title="Half Century of Excellence",
        description="Earn 50,000 XP",
        icon="✨",
        tier=4,
        coin_reward=5000,
        unlock_criteria={"xp_total": 50000},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="xp_100000",
        title="Hundred Thousand Legend",
        description="Earn 100,000 XP - legendary dedication!",
        icon="👑",
        tier=4,
        coin_reward=10000,
        unlock_criteria={"xp_total": 100000},
    ),
    # --- LEVEL MILESTONES ---
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="level_5",
        title="Level 5 Reached",
        description="Reach level 5",
        icon="🎖️",
        tier=1,
        xp_reward=50,
        coin_reward=25,
        unlock_criteria={"level": 5},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="level_10",
        title="Level 10 Reached",
        description="Reach level 10",
        icon="🎖️",
        tier=2,
        xp_reward=150,
        coin_reward=75,
        unlock_criteria={"level": 10},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="level_20",
        title="Level 20 Reached",
        description="Reach level 20 - impressive!",
        icon="🏅",
        tier=2,
        xp_reward=300,
        coin_reward=150,
        unlock_criteria={"level": 20},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="level_30",
        title="Level 30 Reached",
        description="Reach level 30 - elite status",
        icon="🏅",
        tier=3,
        xp_reward=750,
        coin_reward=400,
        unlock_criteria={"level": 30},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="level_50",
        title="Half Century Level",
        description="Reach level 50 - master tier!",
        icon="🏆",
        tier=4,
        xp_reward=2000,
        coin_reward=1000,
        unlock_criteria={"level": 50},
    ),
    # --- PERFECT LESSON ACHIEVEMENTS ---
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="perfect_5",
        title="Five Perfects",
        description="Complete 5 lessons with 100% accuracy",
        icon="💯",
        tier=1,
        xp_reward=150,
        coin_reward=75,
        unlock_criteria={"perfect_lessons": 5},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="perfect_10",
        title="Ten Perfects",
        description="Complete 10 lessons with 100% accuracy",
        icon="💯",
        tier=2,
        xp_reward=300,
        coin_reward=150,
        unlock_criteria={"perfect_lessons": 10},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="perfect_25",
        title="Perfectionist",
        description="Complete 25 lessons with 100% accuracy",
        icon="💯",
        tier=3,
        xp_reward=750,
        coin_reward=400,
        unlock_criteria={"perfect_lessons": 25},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="perfect_50",
        title="Master of Precision",
        description="Complete 50 lessons with 100% accuracy",
        icon="💎",
        tier=4,
        xp_reward=2000,
        coin_reward=1000,
        unlock_criteria={"perfect_lessons": 50},
    ),
    # --- TIME-BASED ACHIEVEMENTS ---
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="early_bird",
        title="Early Bird",
        description="Complete a lesson before 7 AM",
        icon="🌅",
        tier=1,
        xp_reward=50,
        coin_reward=25,
        unlock_criteria={"special": "early_morning"},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="night_owl",
        title="Night Owl",
        description="Complete a lesson after 11 PM",
        icon="🌙",
        tier=1,
        xp_reward=50,
        coin_reward=25,
        unlock_criteria={"special": "late_night"},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="weekend_warrior",
        title="Weekend Warrior",
        description="Complete lessons on both Saturday and Sunday",
        icon="🛡️",
        tier=2,
        xp_reward=100,
        coin_reward=50,
        unlock_criteria={"special": "weekend"},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="holiday_scholar",
        title="Holiday Scholar",
        description="Complete a lesson on a major holiday",
        icon="🎄",
        tier=2,
        xp_reward=150,
        coin_reward=75,
        unlock_criteria={"special": "holiday"},
    ),
    # --- LANGUAGE-SPECIFIC ACHIEVEMENTS ---
    AchievementDefinition(
        achievement_type="collection",
        achievement_id="greek_beginner",
        title="Greek Beginner",
        description="Complete 10 Ancient Greek lessons",
        icon="🇬🇷",
        tier=1,
        xp_reward=100,
        coin_reward=50,
        unlock_criteria={"language": "grc", "lessons": 10},
    ),
    AchievementDefinition(
        achievement_type="collection",
        achievement_id="greek_intermediate",
        title="Greek Intermediate",
        description="Complete 50 Ancient Greek lessons",
        icon="🇬🇷",
        tier=2,
        xp_reward=500,
        coin_reward=250,
        unlock_criteria={"language": "grc", "lessons": 50},
    ),
    AchievementDefinition(
        achievement_type="collection",
        achievement_id="greek_advanced",
        title="Greek Scholar",
        description="Complete 100 Ancient Greek lessons",
        icon="🏛️",
        tier=3,
        xp_reward=1000,
        coin_reward=500,
        unlock_criteria={"language": "grc", "lessons": 100},
    ),
    AchievementDefinition(
        achievement_type="collection",
        achievement_id="latin_beginner",
        title="Latin Beginner",
        description="Complete 10 Latin lessons",
        icon="🏛️",
        tier=1,
        xp_reward=100,
        coin_reward=50,
        unlock_criteria={"language": "lat", "lessons": 10},
    ),
    AchievementDefinition(
        achievement_type="collection",
        achievement_id="latin_intermediate",
        title="Latin Intermediate",
        description="Complete 50 Latin lessons",
        icon="🏛️",
        tier=2,
        xp_reward=500,
        coin_reward=250,
        unlock_criteria={"language": "lat", "lessons": 50},
    ),
    AchievementDefinition(
        achievement_type="collection",
        achievement_id="latin_advanced",
        title="Latin Scholar",
        description="Complete 100 Latin lessons",
        icon="🏛️",
        tier=3,
        xp_reward=1000,
        coin_reward=500,
        unlock_criteria={"language": "lat", "lessons": 100},
    ),
    AchievementDefinition(
        achievement_type="collection",
        achievement_id="hebrew_beginner",
        title="Hebrew Beginner",
        description="Complete 10 Biblical Hebrew lessons",
        icon="✡️",
        tier=1,
        xp_reward=100,
        coin_reward=50,
        unlock_criteria={"language": "hbo", "lessons": 10},
    ),
    AchievementDefinition(
        achievement_type="collection",
        achievement_id="sanskrit_beginner",
        title="Sanskrit Beginner",
        description="Complete 10 Sanskrit lessons",
        icon="🕉️",
        tier=1,
        xp_reward=100,
        coin_reward=50,
        unlock_criteria={"language": "san", "lessons": 10},
    ),
    # --- POLYGLOT ACHIEVEMENTS ---
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="polyglot_2",
        title="Polyglot (2 Languages)",
        description="Complete lessons in 2 different languages",
        icon="🌍",
        tier=2,
        xp_reward=200,
        coin_reward=100,
        unlock_criteria={"languages_count": 2},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="polyglot_3",
        title="Polyglot (3 Languages)",
        description="Complete lessons in 3 different languages",
        icon="🌍",
        tier=3,
        xp_reward=500,
        coin_reward=250,
        unlock_criteria={"languages_count": 3},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="polyglot_4",
        title="Master Polyglot",
        description="Complete lessons in all 4 ancient languages",
        icon="🌎",
        tier=4,
        xp_reward=1000,
        coin_reward=500,
        unlock_criteria={"languages_count": 4},
    ),
    # --- SPEED ACHIEVEMENTS ---
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="speed_demon",
        title="Speed Demon",
        description="Complete a lesson in under 2 minutes",
        icon="⚡",
        tier=2,
        xp_reward=100,
        coin_reward=50,
        unlock_criteria={"completion_time_seconds": 120},
    ),
    AchievementDefinition(
        achievement_type="badge",
        achievement_id="lightning_fast",
        title="Lightning Fast",
        description="Complete a lesson in under 1 minute",
        icon="⚡",
        tier=3,
        xp_reward=250,
        coin_reward=125,
        unlock_criteria={"completion_time_seconds": 60},
    ),
    # --- COIN ACHIEVEMENTS ---
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="coins_1000",
        title="First Thousand Coins",
        description="Accumulate 1,000 coins",
        icon="🪙",
        tier=2,
        xp_reward=100,
        unlock_criteria={"coins": 1000},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="coins_5000",
        title="Coin Collector",
        description="Accumulate 5,000 coins",
        icon="💰",
        tier=3,
        xp_reward=500,
        unlock_criteria={"coins": 5000},
    ),
    AchievementDefinition(
        achievement_type="milestone",
        achievement_id="coins_10000",
        title="Treasure Hoard",
        description="Accumulate 10,000 coins",
        icon="💎",
        tier=4,
        xp_reward=1000,
        unlock_criteria={"coins": 10000},
    ),
]


async def seed_achievement_templates(session: AsyncSession) -> None:
    """Seed achievement templates (not user-specific).

    This function would typically insert into an `achievements` template table.
    For now, achievements are defined in code and checked dynamically.
    """
    print(f"✓ Loaded {len(ACHIEVEMENTS)} achievement definitions")
    for achievement in ACHIEVEMENTS:
        print(f"  - [{achievement.tier}★] {achievement.title}: {achievement.description}")


async def check_and_unlock_achievements(
    session: AsyncSession,
    user_id: int,
    progress_data: dict,
) -> list[UserAchievement]:
    """Check user progress and unlock any earned achievements.

    Args:
        session: Database session
        user_id: User ID to check
        progress_data: Current user progress (xp, level, streak, etc.)
            Expected keys:
            - total_lessons: Total lessons completed
            - perfect_lessons: Lessons with 100% accuracy
            - streak_days: Current streak
            - xp_total: Total XP earned
            - level: Current level
            - coins: Current coin balance
            - language: (Optional) Current lesson language code
            - completion_time_seconds: (Optional) Last lesson completion time
            - lesson_timestamp: (Optional) Timestamp of lesson completion

    Returns:
        List of newly unlocked achievements
    """
    # Get already unlocked achievements
    result = await session.execute(select(UserAchievement).where(UserAchievement.user_id == user_id))
    unlocked = {f"{a.achievement_type}/{a.achievement_id}" for a in result.scalars().all()}

    # Get language-specific lesson counts and unique languages from learning events
    from app.db.user_models import LearningEvent

    # Count lessons per language
    language_counts = {}
    unique_languages = set()
    try:
        events_result = await session.execute(
            select(LearningEvent.data).where(
                LearningEvent.user_id == user_id,
                LearningEvent.event_type == "lesson_complete",
            )
        )
        for (event_data,) in events_result:
            if event_data and "language" in event_data:
                lang = event_data["language"]
                language_counts[lang] = language_counts.get(lang, 0) + 1
                unique_languages.add(lang)
    except Exception as e:
        print(f"[WARNING] Could not fetch language-specific data: {e}")

    newly_unlocked: list[UserAchievement] = []

    for achievement in ACHIEVEMENTS:
        key = f"{achievement.achievement_type}/{achievement.achievement_id}"
        if key in unlocked:
            continue

        # Check unlock criteria - ALL criteria must be met if present
        criteria = achievement.unlock_criteria or {}
        if not criteria:
            continue

        # Check each criterion - only unlock if ALL present criteria are met
        should_unlock = True

        if "lessons_completed" in criteria:
            if progress_data.get("total_lessons", 0) < criteria["lessons_completed"]:
                should_unlock = False

        if "streak_days" in criteria and should_unlock:
            if progress_data.get("streak_days", 0) < criteria["streak_days"]:
                should_unlock = False

        if "xp_total" in criteria and should_unlock:
            if progress_data.get("xp_total", 0) < criteria["xp_total"]:
                should_unlock = False

        if "level" in criteria and should_unlock:
            if progress_data.get("level", 0) < criteria["level"]:
                should_unlock = False

        if "perfect_lessons" in criteria and should_unlock:
            if progress_data.get("perfect_lessons", 0) < criteria["perfect_lessons"]:
                should_unlock = False

        if "coins" in criteria and should_unlock:
            if progress_data.get("coins", 0) < criteria["coins"]:
                should_unlock = False

        # Language-specific achievements (e.g., "Complete 10 Greek lessons")
        if "language" in criteria and should_unlock:
            required_lang = criteria["language"]
            required_lessons = criteria.get("lessons", 1)
            actual_lessons = language_counts.get(required_lang, 0)
            if actual_lessons < required_lessons:
                should_unlock = False

        # Polyglot achievements (practice multiple languages)
        if "languages_count" in criteria and should_unlock:
            required_count = criteria["languages_count"]
            if len(unique_languages) < required_count:
                should_unlock = False

        # Completion time achievements (speed-based)
        if "completion_time_seconds" in criteria and should_unlock:
            max_time = criteria["completion_time_seconds"]
            actual_time = progress_data.get("completion_time_seconds")
            if actual_time is None or actual_time > max_time:
                should_unlock = False

        # Special time-based achievements (early bird, night owl, weekend, etc.)
        if "special" in criteria and should_unlock:
            special_type = criteria["special"]
            timestamp = progress_data.get("lesson_timestamp")

            if timestamp is None:
                should_unlock = False
            else:
                from datetime import datetime

                if isinstance(timestamp, str):
                    timestamp = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
                elif not isinstance(timestamp, datetime):
                    should_unlock = False
                else:
                    hour = timestamp.hour
                    weekday = timestamp.weekday()  # Monday=0, Sunday=6

                    if special_type == "early_morning":
                        # Before 7 AM
                        if hour >= 7:
                            should_unlock = False
                    elif special_type == "late_night":
                        # After 11 PM
                        if hour < 23:
                            should_unlock = False
                    elif special_type == "weekend":
                        # Saturday (5) or Sunday (6)
                        if weekday not in (5, 6):
                            should_unlock = False
                    elif special_type == "holiday":
                        # Check for major holidays (simplified - just December 25 and January 1)
                        month = timestamp.month
                        day = timestamp.day
                        major_holidays = [
                            (12, 25),
                            (1, 1),
                            (7, 4),
                            (11, 11),
                        ]  # Christmas, New Year, July 4, Veterans
                        if (month, day) not in major_holidays:
                            should_unlock = False

        if should_unlock:
            new_achievement = UserAchievement(
                user_id=user_id,
                achievement_type=achievement.achievement_type,
                achievement_id=achievement.achievement_id,
                meta={
                    "title": achievement.title,
                    "description": achievement.description,
                    "icon": achievement.icon,
                    "tier": achievement.tier,
                    "xp_reward": achievement.xp_reward,
                    "coin_reward": achievement.coin_reward,
                },
            )
            session.add(new_achievement)
            newly_unlocked.append(new_achievement)

    return newly_unlocked


# CLI main removed - use check_and_unlock_achievements directly from routers
