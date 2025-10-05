"""Integration tests for MVP features: text-range extraction and register modes."""

import httpx
import pytest


@pytest.mark.asyncio
async def test_text_range_extraction_returns_greek_vocabulary_from_specific_lines() -> None:
    """Verify text-range endpoint returns vocabulary from specified Iliad lines."""
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000", timeout=30.0) as client:
        response = await client.post(
            "/lesson/generate",
            json={
                "language": "grc",
                "text_range": {"ref_start": "Il.1.20", "ref_end": "Il.1.30"},
                "exercise_types": ["match", "cloze"],
                "provider": "echo",
            },
        )

        assert response.status_code == 200, f"Expected 200 OK, got {response.status_code}: {response.text}"

        data = response.json()
        assert "tasks" in data, "Response should contain tasks array"
        assert len(data["tasks"]) > 0, "Should generate at least one task"

        # Verify contains Greek text (Unicode range 0x0370-0x03FF)
        task_json = response.text
        has_greek = any(0x0370 <= ord(c) <= 0x03FF for c in task_json)
        assert has_greek, "Tasks should contain Greek characters"

        # Verify specific phrases from Iliad 1.20-1.30 are present
        expected_phrases = [
            "ἀλλʼ οὐκ Ἀτρεΐδῃ",  # from line 1.24
            "ἔνθʼ ἄλλοι μὲν",  # from line 1.22
            "ἁζόμενοι",  # from line 1.21
        ]

        found_count = sum(1 for phrase in expected_phrases if phrase in task_json)
        assert found_count > 0, (
            f"Should contain at least one phrase from Iliad 1.20-1.30. "
            f"Expected any of {expected_phrases}, got: {task_json[:500]}"
        )


@pytest.mark.asyncio
async def test_register_modes_produce_different_vocabulary() -> None:
    """Verify literary and colloquial registers generate different vocabulary."""
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000", timeout=30.0) as client:
        # Generate literary lesson
        literary_response = await client.post(
            "/lesson/generate",
            json={
                "language": "grc",
                "register": "literary",
                "exercise_types": ["match"],
                "provider": "echo",
                "sources": ["daily"],
            },
        )

        # Generate colloquial lesson
        colloquial_response = await client.post(
            "/lesson/generate",
            json={
                "language": "grc",
                "register": "colloquial",
                "exercise_types": ["match"],
                "provider": "echo",
                "sources": ["daily"],
            },
        )

        assert literary_response.status_code == 200, f"Literary failed: {literary_response.text}"
        assert colloquial_response.status_code == 200, f"Colloquial failed: {colloquial_response.text}"

        literary_data = literary_response.json()
        colloquial_data = colloquial_response.json()

        assert len(literary_data["tasks"]) > 0, "Literary tasks should not be empty"
        assert len(colloquial_data["tasks"]) > 0, "Colloquial tasks should not be empty"

        # Vocabularies should be different
        literary_json = literary_response.text
        colloquial_json = colloquial_response.text

        assert literary_json != colloquial_json, (
            "Literary and colloquial registers should produce different vocabulary"
        )

        # Check for expected literary vocabulary
        literary_indicators = ["εὖ ἔχω", "δέκα", "χαῖρε"]
        has_literary = any(phrase in literary_json for phrase in literary_indicators)
        assert has_literary, f"Literary should contain formal vocabulary. Got: {literary_json[:500]}"

        # Check for expected colloquial vocabulary
        colloquial_indicators = ["πωλεῖς", "θέλω", "οἶνον", "φίλε"]
        has_colloquial = any(phrase in colloquial_json for phrase in colloquial_indicators)
        assert has_colloquial, f"Colloquial should contain everyday vocabulary. Got: {colloquial_json[:500]}"


@pytest.mark.asyncio
async def test_health_endpoint_confirms_lessons_enabled() -> None:
    """Verify lessons feature is enabled in health check."""
    async with httpx.AsyncClient(base_url="http://127.0.0.1:8000", timeout=10.0) as client:
        response = await client.get("/health")

        assert response.status_code == 200, f"Health check failed: {response.text}"

        data = response.json()
        assert data["status"] == "ok", "Server status should be ok"
        assert "features" in data, "Features object should exist"
        assert data["features"]["lessons"] is True, "Lessons feature should be enabled"
