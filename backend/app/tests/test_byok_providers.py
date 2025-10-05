"""Integration tests for BYOK provider functionality"""

import os

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_anthropic_provider_with_server_key():
    """Test Anthropic provider returns non-echo response when server key is set"""
    # Only run if API key is set
    if not os.getenv("ANTHROPIC_API_KEY"):
        pytest.skip("ANTHROPIC_API_KEY not set")

    response = client.post(
        "/lesson/generate",
        json={
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match"],
            "provider": "anthropic",
            "model": "claude-3-5-sonnet-20241022",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["meta"]["provider"] == "anthropic", "Should not fall back to echo"
    assert "claude" in data["meta"]["model"].lower()
    assert len(data["tasks"]) > 0


def test_google_provider_with_server_key():
    """Test Google/Gemini provider returns non-echo response when server key is set"""
    # Only run if API key is set
    if not os.getenv("GOOGLE_API_KEY"):
        pytest.skip("GOOGLE_API_KEY not set")

    response = client.post(
        "/lesson/generate",
        json={
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match"],
            "provider": "google",
            "model": "gemini-2.5-flash",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["meta"]["provider"] == "google", "Should not fall back to echo"
    assert "gemini" in data["meta"]["model"].lower()
    assert len(data["tasks"]) > 0


def test_openai_provider_rate_limit():
    """Test OpenAI provider returns 503 error on rate limit (not silent echo)"""
    # Only run if API key is set
    if not os.getenv("OPENAI_API_KEY"):
        pytest.skip("OPENAI_API_KEY not set")

    response = client.post(
        "/lesson/generate",
        json={
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match"],
            "provider": "openai",
            "model": "gpt-4o-mini",
        },
    )

    # Could be 200 (success) or 503 (rate limit/quota error)
    # But should NEVER be 200 with provider="echo"
    if response.status_code == 200:
        data = response.json()
        assert data["meta"]["provider"] == "openai", "Should not fall back to echo on success"
    elif response.status_code == 503:
        # Expected for rate-limited/quota-exceeded accounts
        data = response.json()
        assert "openai" in data["detail"].lower()
        assert "429" in data["detail"] or "quota" in data["detail"].lower()
    else:
        pytest.fail(f"Unexpected status code: {response.status_code}")


def test_provider_health_endpoint():
    """Test health endpoint returns provider statuses"""
    response = client.get("/health/providers")

    assert response.status_code == 200
    data = response.json()

    # Check structure
    assert "anthropic" in data
    assert "google" in data
    assert "openai" in data
    assert "timestamp" in data

    # Each provider should have ok/status/error fields
    for provider in ["anthropic", "google", "openai"]:
        assert "ok" in data[provider]
        assert "status" in data[provider]
        assert "error" in data[provider]


def test_provider_without_key_fails_when_fallback_disabled():
    """Test that missing API key causes 503 when ECHO_FALLBACK_ENABLED=false"""
    # This test assumes ECHO_FALLBACK_ENABLED=false in test environment
    # and that we can clear API keys for the test

    # Create a test client that will use settings without API keys
    # (This is a conceptual test - actual implementation would need env mocking)

    # Skip for now since we have keys in .env
    pytest.skip("Requires environment mocking to test missing keys")


def test_echo_provider_always_works():
    """Test that echo provider works without API keys"""
    response = client.post(
        "/lesson/generate",
        json={
            "language": "grc",
            "profile": "beginner",
            "sources": ["daily"],
            "exercise_types": ["match"],
            "provider": "echo",
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["meta"]["provider"] == "echo"
    assert len(data["tasks"]) > 0
