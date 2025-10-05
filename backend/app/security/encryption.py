"""Encryption utilities for sensitive data like API keys.

Uses Fernet symmetric encryption (built on AES) for encrypting user API keys.
Encryption key should be stored in environment variables, separate from JWT secret.
"""

from __future__ import annotations

import base64
import os

from cryptography.fernet import Fernet

from app.core.config import settings


def _get_encryption_key() -> bytes:
    """Get or generate encryption key for Fernet.

    The encryption key should be a 32-byte URL-safe base64-encoded string.
    In production, this MUST be set via environment variable.
    """
    # Check if encryption key is set in environment
    key_str = getattr(settings, "ENCRYPTION_KEY", None) or os.getenv("ENCRYPTION_KEY")

    if key_str:
        # Validate it's proper format
        try:
            key_bytes = key_str.encode() if isinstance(key_str, str) else key_str
            # Test that it's valid by creating a Fernet instance
            Fernet(key_bytes)
            return key_bytes
        except Exception as e:
            raise ValueError(
                f"Invalid ENCRYPTION_KEY format. Must be a valid Fernet key. "
                f"Generate one with: python -c 'from cryptography.fernet import Fernet; "
                f"print(Fernet.generate_key().decode())'. "
                f"Error: {e}"
            )

    # Development fallback (NOT SECURE - for local dev only)
    import logging

    logging.warning(
        "SECURITY WARNING: ENCRYPTION_KEY not set. Using insecure default. "
        "Generate a key with: python -c 'from cryptography.fernet import Fernet; "
        "print(Fernet.generate_key().decode())' and set it in your .env file."
    )
    # This is a deterministic key for dev - DO NOT USE IN PRODUCTION
    # Fernet requires exactly 32 bytes, base64-encoded
    import hashlib

    fixed_key = hashlib.sha256(b"INSECURE_DEV_KEY_CHANGE_ME").digest()
    return base64.urlsafe_b64encode(fixed_key)


# Initialize Fernet cipher
_cipher = Fernet(_get_encryption_key())


def encrypt_api_key(plaintext_key: str) -> str:
    """Encrypt an API key for storage in the database.

    Args:
        plaintext_key: The raw API key to encrypt

    Returns:
        Base64-encoded encrypted string
    """
    if not plaintext_key:
        raise ValueError("Cannot encrypt empty API key")

    plaintext_bytes = plaintext_key.encode()
    encrypted_bytes = _cipher.encrypt(plaintext_bytes)
    return encrypted_bytes.decode()


def decrypt_api_key(encrypted_key: str) -> str:
    """Decrypt an API key retrieved from the database.

    Args:
        encrypted_key: The encrypted API key from database

    Returns:
        Decrypted plaintext API key

    Raises:
        ValueError: If decryption fails (wrong key, corrupted data)
    """
    if not encrypted_key:
        raise ValueError("Cannot decrypt empty encrypted key")

    try:
        encrypted_bytes = encrypted_key.encode()
        decrypted_bytes = _cipher.decrypt(encrypted_bytes)
        return decrypted_bytes.decode()
    except Exception as e:
        raise ValueError(f"Failed to decrypt API key: {e}")


def rotate_encryption(old_encrypted_key: str, old_cipher_key: bytes, new_cipher_key: bytes) -> str:
    """Rotate encryption key by re-encrypting with new key.

    Used when changing ENCRYPTION_KEY environment variable.

    Args:
        old_encrypted_key: Currently encrypted API key
        old_cipher_key: Previous encryption key
        new_cipher_key: New encryption key

    Returns:
        Re-encrypted API key with new key
    """
    old_cipher = Fernet(old_cipher_key)
    new_cipher = Fernet(new_cipher_key)

    # Decrypt with old key
    encrypted_bytes = old_encrypted_key.encode()
    plaintext_bytes = old_cipher.decrypt(encrypted_bytes)

    # Re-encrypt with new key
    new_encrypted_bytes = new_cipher.encrypt(plaintext_bytes)
    return new_encrypted_bytes.decode()


__all__ = [
    "encrypt_api_key",
    "decrypt_api_key",
    "rotate_encryption",
]
