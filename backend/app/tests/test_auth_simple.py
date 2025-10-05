"""Simple authentication tests that actually work.

These tests validate the core authentication logic without requiring a full database.
"""

from __future__ import annotations

import pytest

from app.security.auth import (
    create_access_token,
    create_refresh_token,
    create_token_pair,
    decode_token,
    hash_password,
    verify_password,
)


class TestPasswordHashing:
    """Test password hashing utilities."""

    def test_hash_password_creates_different_hashes(self):
        """Test that hashing same password twice produces different hashes (due to salt)."""
        password = "TestPassword123"
        hash1 = hash_password(password)
        hash2 = hash_password(password)

        assert hash1 != hash2, "Hashes should be different due to salt"
        assert len(hash1) > 0
        assert len(hash2) > 0

    def test_verify_password_correct(self):
        """Test password verification with correct password."""
        password = "SecurePassword456"
        hashed = hash_password(password)

        assert verify_password(password, hashed) is True

    def test_verify_password_incorrect(self):
        """Test password verification with incorrect password."""
        password = "CorrectPassword789"
        wrong_password = "WrongPassword000"
        hashed = hash_password(password)

        assert verify_password(wrong_password, hashed) is False

    def test_verify_password_case_sensitive(self):
        """Test that password verification is case-sensitive."""
        password = "CaseSensitive123"
        hashed = hash_password(password)

        assert verify_password("casesensitive123", hashed) is False
        assert verify_password("CASESENSITIVE123", hashed) is False


class TestJWTTokens:
    """Test JWT token generation and validation."""

    def test_create_access_token(self):
        """Test creating an access token."""
        user_id = 42
        token = create_access_token(user_id)

        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    def test_create_refresh_token(self):
        """Test creating a refresh token."""
        user_id = 42
        token = create_refresh_token(user_id)

        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    def test_access_and_refresh_tokens_different(self):
        """Test that access and refresh tokens are different."""
        user_id = 42
        access = create_access_token(user_id)
        refresh = create_refresh_token(user_id)

        assert access != refresh

    def test_create_token_pair(self):
        """Test creating both access and refresh tokens."""
        user_id = 123
        tokens = create_token_pair(user_id)

        assert tokens.access_token
        assert tokens.refresh_token
        assert tokens.token_type == "bearer"
        assert tokens.access_token != tokens.refresh_token

    def test_decode_access_token(self):
        """Test decoding an access token."""
        user_id = 999
        token = create_access_token(user_id)

        payload = decode_token(token)

        assert payload.user_id == user_id  # Use user_id property which converts to int
        assert payload.token_type == "access"
        assert payload.exp is not None
        assert payload.iat is not None

    def test_decode_refresh_token(self):
        """Test decoding a refresh token."""
        user_id = 777
        token = create_refresh_token(user_id)

        payload = decode_token(token)

        assert payload.user_id == user_id  # Use user_id property which converts to int
        assert payload.token_type == "refresh"
        assert payload.exp is not None
        assert payload.iat is not None

    def test_decode_invalid_token_raises_error(self):
        """Test that decoding an invalid token raises HTTPException."""
        from fastapi import HTTPException

        invalid_token = "this.is.invalid"

        with pytest.raises(HTTPException) as exc_info:
            decode_token(invalid_token)

        assert exc_info.value.status_code == 401

    def test_token_contains_expiration(self):
        """Test that tokens contain expiration timestamp."""
        user_id = 555
        access_token = create_access_token(user_id)
        refresh_token = create_refresh_token(user_id)

        access_payload = decode_token(access_token)
        refresh_payload = decode_token(refresh_token)

        # Refresh token should expire later than access token
        assert refresh_payload.exp > access_payload.exp


class TestPasswordValidation:
    """Test password validation logic."""

    def test_password_validation_import(self):
        """Test that password validation schema can be imported."""
        from app.api.schemas.user_schemas import UserRegisterRequest

        assert UserRegisterRequest is not None

    def test_valid_password(self):
        """Test that valid password passes validation."""
        from app.api.schemas.user_schemas import UserRegisterRequest

        # Should not raise
        request = UserRegisterRequest(
            username="testuser",
            email="test@example.com",
            password="ValidPassword123",
        )

        assert request.password == "ValidPassword123"

    def test_password_too_short(self):
        """Test that short password fails validation."""
        from pydantic import ValidationError

        from app.api.schemas.user_schemas import UserRegisterRequest

        with pytest.raises(ValidationError) as exc_info:
            UserRegisterRequest(
                username="testuser",
                email="test@example.com",
                password="Short1",  # Only 6 characters
            )

        errors = exc_info.value.errors()
        assert any("at least 8 characters" in str(e) for e in errors)

    def test_password_no_uppercase(self):
        """Test that password without uppercase fails validation."""
        from pydantic import ValidationError

        from app.api.schemas.user_schemas import UserRegisterRequest

        with pytest.raises(ValidationError) as exc_info:
            UserRegisterRequest(
                username="testuser",
                email="test@example.com",
                password="nouppercase123",  # No uppercase letter
            )

        errors = exc_info.value.errors()
        assert any("uppercase" in str(e).lower() for e in errors)

    def test_password_no_lowercase(self):
        """Test that password without lowercase fails validation."""
        from pydantic import ValidationError

        from app.api.schemas.user_schemas import UserRegisterRequest

        with pytest.raises(ValidationError) as exc_info:
            UserRegisterRequest(
                username="testuser",
                email="test@example.com",
                password="NOLOWERCASE123",  # No lowercase letter
            )

        errors = exc_info.value.errors()
        assert any("lowercase" in str(e).lower() for e in errors)

    def test_password_no_digit(self):
        """Test that password without digit fails validation."""
        from pydantic import ValidationError

        from app.api.schemas.user_schemas import UserRegisterRequest

        with pytest.raises(ValidationError) as exc_info:
            UserRegisterRequest(
                username="testuser",
                email="test@example.com",
                password="NoDigitsHere",  # No digit
            )

        errors = exc_info.value.errors()
        assert any("digit" in str(e).lower() for e in errors)


class TestEncryption:
    """Test API key encryption."""

    def test_encrypt_decrypt_roundtrip(self):
        """Test encrypting and decrypting API key."""
        from app.security.encryption import decrypt_api_key, encrypt_api_key

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
        from app.security.encryption import encrypt_api_key

        with pytest.raises(ValueError, match="Cannot encrypt empty"):
            encrypt_api_key("")

    def test_decrypt_invalid_data_fails(self):
        """Test that decrypting invalid data raises error."""
        from app.security.encryption import decrypt_api_key

        with pytest.raises(ValueError, match="Failed to decrypt"):
            decrypt_api_key("invalid_encrypted_data_here")

    def test_different_encryptions_same_plaintext(self):
        """Test that encrypting same key twice produces different ciphertext."""
        from app.security.encryption import decrypt_api_key, encrypt_api_key

        key = "sk-test-api-key"

        encrypted1 = encrypt_api_key(key)
        encrypted2 = encrypt_api_key(key)

        # Ciphertext should be different (Fernet uses random nonce)
        assert encrypted1 != encrypted2

        # But both decrypt to same value
        assert decrypt_api_key(encrypted1) == key
        assert decrypt_api_key(encrypted2) == key


if __name__ == "__main__":
    # Allow running tests directly
    pytest.main([__file__, "-v"])
