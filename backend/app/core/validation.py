"""Input validation utilities for authentication and user data.

Provides password strength validation, email validation, and username validation
following industry best practices and security standards.
"""

from __future__ import annotations

import re
from typing import NamedTuple

from fastapi import HTTPException, status


class PasswordValidationResult(NamedTuple):
    """Result of password validation check."""

    is_valid: bool
    errors: list[str]
    strength_score: float  # 0.0 to 1.0


# Common weak passwords to reject
COMMON_PASSWORDS = {
    "password",
    "123456",
    "12345678",
    "123456789",
    "1234567890",
    "qwerty",
    "abc123",
    "password123",
    "admin",
    "letmein",
    "welcome",
    "monkey",
    "dragon",
    "master",
    "sunshine",
    "princess",
    "login",
    "starwars",
    "football",
    "baseball",
}


def validate_password(password: str, *, username: str | None = None) -> PasswordValidationResult:
    """Validate password strength and security.

    Requirements:
    - Minimum 8 characters
    - At least one uppercase letter
    - At least one lowercase letter
    - At least one digit
    - At least one special character
    - Not in common password list
    - Not contain username (if provided)

    Args:
        password: The password to validate
        username: Optional username to check password doesn't contain it

    Returns:
        PasswordValidationResult with validation status, errors, and strength score
    """
    errors: list[str] = []
    strength_score = 0.0

    # Length check
    if len(password) < 8:
        errors.append("Password must be at least 8 characters long")
    elif len(password) >= 8:
        strength_score += 0.2
    if len(password) >= 12:
        strength_score += 0.1
    if len(password) >= 16:
        strength_score += 0.1

    # Uppercase letter check
    if not re.search(r"[A-Z]", password):
        errors.append("Password must contain at least one uppercase letter")
    else:
        strength_score += 0.15

    # Lowercase letter check
    if not re.search(r"[a-z]", password):
        errors.append("Password must contain at least one lowercase letter")
    else:
        strength_score += 0.15

    # Digit check
    if not re.search(r"\d", password):
        errors.append("Password must contain at least one digit")
    else:
        strength_score += 0.15

    # Special character check
    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        errors.append("Password must contain at least one special character (!@#$%^&* etc.)")
    else:
        strength_score += 0.15

    # Common password check
    if password.lower() in COMMON_PASSWORDS:
        errors.append("This password is too common. Please choose a stronger password")
        strength_score = min(strength_score, 0.3)  # Cap score for common passwords

    # Username check
    if username and username.lower() in password.lower():
        errors.append("Password must not contain your username")
        strength_score = min(strength_score, 0.4)

    # Check for repeated characters (e.g., "aaaa", "1111")
    if re.search(r"(.)\1{3,}", password):
        errors.append("Password contains too many repeated characters")
        strength_score -= 0.1

    # Bonus for mixed case and symbols
    has_mixed_case = re.search(r"[A-Z]", password) and re.search(r"[a-z]", password)
    has_symbols_and_numbers = re.search(r"\d", password) and re.search(r'[!@#$%^&*(),.?":{}|<>]', password)
    if has_mixed_case and has_symbols_and_numbers and len(password) >= 12:
        strength_score += 0.05

    strength_score = max(0.0, min(1.0, strength_score))  # Clamp to [0, 1]

    return PasswordValidationResult(
        is_valid=len(errors) == 0,
        errors=errors,
        strength_score=strength_score,
    )


def validate_password_or_raise(password: str, *, username: str | None = None) -> None:
    """Validate password and raise HTTPException if invalid.

    Args:
        password: The password to validate
        username: Optional username to check password doesn't contain it

    Raises:
        HTTPException: If password is invalid, with detailed error messages
    """
    result = validate_password(password, username=username)

    if not result.is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "message": "Password does not meet security requirements",
                "errors": result.errors,
                "strength_score": result.strength_score,
            },
        )


def validate_email(email: str) -> bool:
    """Validate email format using RFC 5322 simplified regex.

    Args:
        email: The email address to validate

    Returns:
        True if email format is valid, False otherwise
    """
    # RFC 5322 simplified email regex
    email_pattern = re.compile(
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}"
        r"[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
    )

    if not email or len(email) > 320:  # RFC 5321 max length
        return False

    if not email_pattern.match(email):
        return False

    # Additional checks
    local_part, _, domain = email.rpartition("@")

    # Local part (before @) must be <= 64 chars (RFC 5321)
    if len(local_part) > 64:
        return False

    # Domain must have at least one dot
    if "." not in domain:
        return False

    # Domain parts must not start or end with hyphen
    domain_parts = domain.split(".")
    for part in domain_parts:
        if not part or part.startswith("-") or part.endswith("-"):
            return False

    return True


def validate_email_or_raise(email: str) -> None:
    """Validate email and raise HTTPException if invalid.

    Args:
        email: The email address to validate

    Raises:
        HTTPException: If email format is invalid
    """
    if not validate_email(email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email address format",
        )


def validate_username(username: str) -> bool:
    """Validate username format.

    Requirements:
    - 3-30 characters
    - Alphanumeric, underscore, and hyphen only
    - Must start with letter or digit
    - Cannot end with hyphen or underscore

    Args:
        username: The username to validate

    Returns:
        True if username format is valid, False otherwise
    """
    if not username or len(username) < 3 or len(username) > 30:
        return False

    # Must match pattern: start with alphanumeric, contain alphanumeric/underscore/hyphen
    username_pattern = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9_-]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$")

    return bool(username_pattern.match(username))


def validate_username_or_raise(username: str) -> None:
    """Validate username and raise HTTPException if invalid.

    Args:
        username: The username to validate

    Raises:
        HTTPException: If username format is invalid
    """
    if not validate_username(username):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username must be 3-30 characters, start with a letter or digit, "
            "and contain only letters, digits, underscores, and hyphens",
        )


__all__ = [
    "validate_password",
    "validate_password_or_raise",
    "validate_email",
    "validate_email_or_raise",
    "validate_username",
    "validate_username_or_raise",
    "PasswordValidationResult",
]
