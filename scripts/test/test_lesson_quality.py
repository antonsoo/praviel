"""Test lesson generation quality across multiple languages.

This script generates lessons for 10+ languages using the Echo provider
and saves results to artifacts/lesson_quality_report.json for review.
"""

import asyncio
import json
from pathlib import Path

import httpx

# Test languages (10 total)
LANGUAGES = [
    ("grc", "Classical Greek"),
    ("lat", "Classical Latin"),
    ("san", "Classical Sanskrit"),
    ("hbo", "Biblical Hebrew"),
    ("akk", "Akkadian"),
    ("sux", "Sumerian"),
    ("egy", "Egyptian"),
    ("non", "Old Norse"),
    ("ang", "Old English"),
    ("grc-koi", "Koine Greek"),
]

BASE_URL = "http://127.0.0.1:8000"


async def generate_lesson(language: str, profile: str = "beginner") -> dict:
    """Generate a lesson for a language using Echo provider."""
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"{BASE_URL}/lesson/generate",
            json={
                "language": language,
                "profile": profile,
                "sources": ["daily"],
                "exercise_types": ["cloze", "translate", "match"],
                "provider": "echo",  # Use Echo (no API key needed)
                "task_count": 8,
            },
        )
        response.raise_for_status()
        return response.json()


async def test_language(language_code: str, language_name: str) -> dict:
    """Test lesson generation for a language."""
    print(f"\n{'=' * 60}")
    print(f"Testing {language_name} ({language_code})")
    print(f"{'=' * 60}")

    try:
        lesson = await generate_lesson(language_code)

        # Extract key info
        result = {
            "language_code": language_code,
            "language_name": language_name,
            "status": "success",
            "task_count": len(lesson.get("tasks", [])),
            "provider": lesson.get("meta", {}).get("provider"),
            "tasks": [],
            "issues": [],
        }

        # Analyze tasks
        for idx, task in enumerate(lesson.get("tasks", []), 1):
            task_type = task.get("type")
            task_info = {
                "index": idx,
                "type": task_type,
            }

            # Check for potential issues
            if task_type == "cloze":
                # Cloze tasks have 'text' (with ____ blanks) and 'blanks' array
                text = task.get("text", "")
                blanks = task.get("blanks", [])

                if not text:
                    result["issues"].append(f"Task {idx}: Empty cloze text")
                if not blanks:
                    result["issues"].append(f"Task {idx}: No cloze blanks")

                task_info["text"] = text[:100] if text else ""
                task_info["blank_count"] = len(blanks)
                task_info["blanks"] = [b.get("surface", "") for b in blanks]

            elif task_type == "translate":
                # Translate tasks have 'text' (source) and 'sampleSolution' (target)
                text = task.get("text", "")
                sample_solution = task.get("sampleSolution", "")

                if not text:
                    result["issues"].append(f"Task {idx}: Empty translation source text")
                if not sample_solution:
                    result["issues"].append(f"Task {idx}: Empty translation sampleSolution")

                task_info["text"] = text[:50] if text else ""
                task_info["sampleSolution"] = sample_solution[:50] if sample_solution else ""

            elif task_type == "match":
                pairs = task.get("pairs", [])
                if len(pairs) < 2:
                    result["issues"].append(f"Task {idx}: Too few match pairs ({len(pairs)})")
                task_info["pair_count"] = len(pairs)

            elif task_type == "alphabet":
                # Alphabet tasks have 'prompt', 'options', and 'answer'
                prompt = task.get("prompt", "")
                options = task.get("options", [])
                answer = task.get("answer", "")

                if not prompt:
                    result["issues"].append(f"Task {idx}: Empty alphabet prompt")
                if len(options) < 2:
                    result["issues"].append(f"Task {idx}: Too few alphabet options ({len(options)})")
                if not answer:
                    result["issues"].append(f"Task {idx}: Empty alphabet answer")

                task_info["prompt"] = prompt[:100] if prompt else ""
                task_info["option_count"] = len(options)

            result["tasks"].append(task_info)

        # Summary
        print(f"[OK] Generated {result['task_count']} tasks")
        print(f"  Task types: {[t['type'] for t in result['tasks']]}")
        if result["issues"]:
            print(f"[WARN] Issues found: {len(result['issues'])}")
            for issue in result["issues"]:
                print(f"    - {issue}")
        else:
            print("[OK] No issues detected")

        return result

    except Exception as e:
        print(f"[FAIL] {e}")
        return {
            "language_code": language_code,
            "language_name": language_name,
            "status": "failed",
            "error": str(e),
        }


async def main():
    """Test all languages and save report."""
    print("Starting lesson quality testing...")
    print(f"Testing {len(LANGUAGES)} languages")

    results = []
    for language_code, language_name in LANGUAGES:
        result = await test_language(language_code, language_name)
        results.append(result)
        # Brief pause between requests
        await asyncio.sleep(1)

    # Save report
    output_dir = Path(__file__).parents[2] / "artifacts"
    output_dir.mkdir(exist_ok=True)
    output_file = output_dir / "lesson_quality_report.json"

    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(
            {
                "summary": {
                    "total_languages": len(LANGUAGES),
                    "successful": sum(1 for r in results if r["status"] == "success"),
                    "failed": sum(1 for r in results if r["status"] == "failed"),
                    "total_issues": sum(len(r.get("issues", [])) for r in results),
                },
                "results": results,
            },
            f,
            indent=2,
            ensure_ascii=False,
        )

    print(f"\n{'=' * 60}")
    print("SUMMARY")
    print(f"{'=' * 60}")
    print(f"Total languages tested: {len(LANGUAGES)}")
    print(f"Successful: {sum(1 for r in results if r['status'] == 'success')}")
    print(f"Failed: {sum(1 for r in results if r['status'] == 'failed')}")
    print(f"Total issues: {sum(len(r.get('issues', [])) for r in results)}")
    print(f"\nReport saved to: {output_file}")


if __name__ == "__main__":
    asyncio.run(main())
