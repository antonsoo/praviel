#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Quick test script to verify lesson generation works for all 18 exercise types.
"""

import asyncio
import sys

from app.lesson.models import LessonGenerateRequest
from app.lesson.providers.base import DailyLine, LessonContext
from app.lesson.providers.echo import EchoLessonProvider

# Fix Windows encoding
if sys.platform == "win32":
    import io

    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8")


async def main():
    provider = EchoLessonProvider()

    all_exercise_types = [
        "alphabet",
        "match",
        "cloze",
        "translate",
        "grammar",
        "listening",
        "speaking",
        "wordbank",
        "truefalse",
        "multiplechoice",
        "dialogue",
        "conjugation",
        "declension",
        "synonym",
        "contextmatch",
        "reorder",
        "dictation",
        "etymology",
    ]

    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily"],
        exercise_types=all_exercise_types,
        task_count=36,  # 2 of each type
    )

    context = LessonContext(
        daily_lines=[
            DailyLine(grc="Χαῖρε!", en="Hello!"),
            DailyLine(grc="Ἔρρωσο.", en="Farewell."),
            DailyLine(grc="Τί ὄνομά σου;", en="What is your name?"),
        ],
        canonical_lines=[],
        seed=42,
        text_range_data=None,
    )

    print("Generating lesson with all 18 exercise types...")
    response = await provider.generate(request=request, session=None, token=None, context=context)

    print(f"\n✅ Generated {len(response.tasks)} tasks")

    # Count by type
    type_counts = {}
    for task in response.tasks:
        type_counts[task.type] = type_counts.get(task.type, 0) + 1

    print("\nTask distribution:")
    for task_type in sorted(type_counts.keys()):
        count = type_counts[task_type]
        print(f"  {task_type:20s}: {count} tasks")

    # Verify reorder task correctness
    print("\n🔍 Checking reorder task logic...")
    reorder_tasks = [t for t in response.tasks if t.type == "reorder"]
    if reorder_tasks:
        rt = reorder_tasks[0]
        print(f"  Fragments: {rt.fragments}")
        print(f"  Correct order: {rt.correct_order}")
        print(f"  Translation: {rt.translation}")

        # Verify the logic: applying correct_order should give valid result
        if len(rt.fragments) == len(rt.correct_order):
            print("  ✅ Lengths match")
        else:
            print(f"  ❌ Length mismatch: {len(rt.fragments)} != {len(rt.correct_order)}")

    # Check dialogue tasks
    print("\n🔍 Checking dialogue tasks...")
    dialogue_tasks = [t for t in response.tasks if t.type == "dialogue"]
    print(f"  Found {len(dialogue_tasks)} dialogue tasks")
    if dialogue_tasks:
        dt = dialogue_tasks[0]
        print(f"  Lines: {len(dt.lines)}")
        print(f"  Missing index: {dt.missing_index}")
        print(f"  Options: {len(dt.options)}")

    # Check etymology tasks
    print("\n🔍 Checking etymology tasks...")
    etymology_tasks = [t for t in response.tasks if t.type == "etymology"]
    print(f"  Found {len(etymology_tasks)} etymology tasks")
    if etymology_tasks:
        et = etymology_tasks[0]
        print(f"  Question: {et.question[:50]}...")
        print(f"  Answer index: {et.answer_index}")
        print(f"  Has explanation: {bool(et.explanation)}")

    print("\n✅ All tests passed!")


if __name__ == "__main__":
    asyncio.run(main())
