#!/usr/bin/env python3
"""Test Pydantic schema for quest creation."""

import sys

# Fix Windows encoding
if sys.platform == "win32":
    import io

    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

from app.api.routers.quests import QuestCreate

# Test 1: Without quest_id (should work)
print("Test 1: Create quest without quest_id...")
try:
    quest = QuestCreate(
        quest_type="lesson_count",
        target_value=5,
        duration_days=7,
        title="Lesson Master",
    )
    print(f"✅ Success: {quest.model_dump()}")
except Exception as e:
    print(f"❌ Error: {e}")

# Test 2: With quest_id (should work)
print("\nTest 2: Create quest with quest_id...")
try:
    quest = QuestCreate(
        quest_type="lesson_count",
        target_value=5,
        duration_days=7,
        title="Lesson Master",
        quest_id="custom-quest-123",
    )
    print(f"✅ Success: {quest.model_dump()}")
except Exception as e:
    print(f"❌ Error: {e}")
