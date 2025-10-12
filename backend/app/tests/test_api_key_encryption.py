"""Tests for API key encryption and BYOK functionality."""

from __future__ import annotations

import os

import pytest
from cryptography.fernet import Fernet
from fastapi import status
from httpx import AsyncClient

from app.security.encryption import decrypt_api_key, encrypt_api_key, rotate_encryption

RUN_DB_TESTS = os.getenv("RUN_DB_TESTS") == "1"


class TestEncryption:
    """Test API key encryption/decryption."""

    def test_encrypt_decrypt_roundtrip(self):
        """Test encrypting and decrypting API key."""
        original_key = "sk-test1234567890abcdefghij"

        # Encrypt
        encrypted = encrypt_api_key(original_key)
        assert encrypted != original_key
        assert len(encrypted) > 0

        # Decrypt
        decrypted = decrypt_api_key(encrypted)
        assert decrypted == original_key

    def test_encrypt_empty_key_fails(self):
        """Test that encrypting empty key raises error."""
        with pytest.raises(ValueError, match="Cannot encrypt empty"):
            encrypt_api_key("")

    def test_decrypt_empty_key_fails(self):
        """Test that decrypting empty key raises error."""
        with pytest.raises(ValueError, match="Cannot decrypt empty"):
            decrypt_api_key("")

    def test_decrypt_invalid_data_fails(self):
        """Test that decrypting invalid data raises error."""
        with pytest.raises(ValueError, match="Failed to decrypt"):
            decrypt_api_key("invalid_encrypted_data")

    def test_different_encryptions_produce_different_ciphertext(self):
        """Test that encrypting same key twice produces different ciphertext."""
        key = "sk-test-key"

        encrypted1 = encrypt_api_key(key)
        encrypted2 = encrypt_api_key(key)

        # Due to Fernet's nonce, ciphertext should be different
        assert encrypted1 != encrypted2

        # But both decrypt to same value
        assert decrypt_api_key(encrypted1) == key
        assert decrypt_api_key(encrypted2) == key

    def test_encryption_rotation(self):
        """Test rotating encryption key."""
        # Generate two different encryption keys
        old_key = Fernet.generate_key()
        new_key = Fernet.generate_key()

        # Encrypt with old key
        from cryptography.fernet import Fernet as FernetCipher

        old_cipher = FernetCipher(old_key)
        api_key = "sk-original-api-key"
        old_encrypted = old_cipher.encrypt(api_key.encode()).decode()

        # Rotate to new key
        new_encrypted = rotate_encryption(old_encrypted, old_key, new_key)

        # Verify decryption with new key
        new_cipher = FernetCipher(new_key)
        decrypted = new_cipher.decrypt(new_encrypted.encode()).decode()
        assert decrypted == api_key


@pytest.mark.asyncio
@pytest.mark.skipif(not RUN_DB_TESTS, reason="Requires database (RUN_DB_TESTS=1)")
class TestAPIKeyEndpoints:
    """Test API key management endpoints."""

    async def test_create_api_key(self, client: AsyncClient):
        """Test creating an API key."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "apikeyuser",
                "email": "apikey@example.com",
                "password": "ApiKey123",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "apikeyuser",
                "password": "ApiKey123",
            },
        )

        token = login_response.json()["access_token"]

        # Create API key
        response = await client.post(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "provider": "openai",
                "api_key": "sk-test1234567890",
            },
        )

        assert response.status_code == status.HTTP_201_CREATED
        data = response.json()
        assert data["provider"] == "openai"
        assert "api_key" not in data  # Should not return the actual key
        assert "encrypted_api_key" not in data  # Should not return encrypted key

    async def test_list_api_keys(self, client: AsyncClient):
        """Test listing configured API keys."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "listkeys",
                "email": "listkeys@example.com",
                "password": "ListKeys123",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "listkeys",
                "password": "ListKeys123",
            },
        )

        token = login_response.json()["access_token"]

        # Create multiple API keys
        await client.post(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
            json={"provider": "openai", "api_key": "sk-openai-key"},
        )

        await client.post(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
            json={"provider": "anthropic", "api_key": "sk-ant-key"},
        )

        # List keys
        response = await client.get(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert len(data) == 2
        providers = {item["provider"] for item in data}
        assert providers == {"openai", "anthropic"}

    async def test_update_api_key(self, client: AsyncClient):
        """Test updating an existing API key."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "updatekey",
                "email": "updatekey@example.com",
                "password": "UpdateKey123",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "updatekey",
                "password": "UpdateKey123",
            },
        )

        token = login_response.json()["access_token"]

        # Create initial key
        await client.post(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
            json={"provider": "openai", "api_key": "sk-old-key"},
        )

        # Update with new key
        response = await client.post(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
            json={"provider": "openai", "api_key": "sk-new-key"},
        )

        assert response.status_code == status.HTTP_201_CREATED

        # Verify only one key exists
        list_response = await client.get(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = list_response.json()
        openai_keys = [item for item in data if item["provider"] == "openai"]
        assert len(openai_keys) == 1

    async def test_delete_api_key(self, client: AsyncClient):
        """Test deleting an API key."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "deletekey",
                "email": "deletekey@example.com",
                "password": "DeleteKey123",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "deletekey",
                "password": "DeleteKey123",
            },
        )

        token = login_response.json()["access_token"]

        # Create key
        await client.post(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
            json={"provider": "openai", "api_key": "sk-delete-me"},
        )

        # Delete key
        response = await client.delete(
            "/api/v1/api-keys/openai",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == status.HTTP_204_NO_CONTENT

        # Verify it's deleted
        list_response = await client.get(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
        )

        data = list_response.json()
        assert len(data) == 0

    async def test_delete_nonexistent_key(self, client: AsyncClient):
        """Test deleting a non-existent key returns 404."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "nokey",
                "email": "nokey@example.com",
                "password": "NoKey123",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "nokey",
                "password": "NoKey123",
            },
        )

        token = login_response.json()["access_token"]

        # Try to delete non-existent key
        response = await client.delete(
            "/api/v1/api-keys/nonexistent",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == status.HTTP_404_NOT_FOUND

    async def test_test_api_key_endpoint(self, client: AsyncClient):
        """Test the API key test endpoint."""
        # Register and login
        await client.post(
            "/api/v1/auth/register",
            json={
                "username": "testkey",
                "email": "testkey@example.com",
                "password": "TestKey123",
            },
        )

        login_response = await client.post(
            "/api/v1/auth/login",
            json={
                "username_or_email": "testkey",
                "password": "TestKey123",
            },
        )

        token = login_response.json()["access_token"]

        # Create key
        await client.post(
            "/api/v1/api-keys/",
            headers={"Authorization": f"Bearer {token}"},
            json={"provider": "openai", "api_key": "sk-proj-1234567890abcdefghijklmnop"},
        )

        # Test key (get masked version)
        response = await client.get(
            "/api/v1/api-keys/openai/test",
            headers={"Authorization": f"Bearer {token}"},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["provider"] == "openai"
        assert data["configured"] is True
        assert "masked_key" in data
        # Verify key is actually masked
        assert "sk-proj-1" in data["masked_key"]
        assert "..." in data["masked_key"]
