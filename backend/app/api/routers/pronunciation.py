"""Pronunciation scoring API for speaking exercises.

Uses basic text similarity (Levenshtein distance) to score pronunciation accuracy.
Future: Can be enhanced with Whisper API or specialized pronunciation APIs like Speechace.
"""

import logging

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from pydantic import BaseModel, Field

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/pronunciation", tags=["Pronunciation"])


class PronunciationScoreResponse(BaseModel):
    """Pronunciation scoring response."""

    accuracy_score: float = Field(ge=0.0, le=1.0, description="Pronunciation accuracy (0.0-1.0)")
    transcription: str = Field(description="What the user said (transcribed)")
    target_text: str = Field(description="What they should have said")
    feedback: str = Field(description="Human-readable feedback")
    is_correct: bool = Field(description="Whether pronunciation is acceptable (>= 0.7)")


@router.post("/score-text", response_model=PronunciationScoreResponse)
async def score_pronunciation_text(
    transcription: str = Form(..., description="User's transcribed speech"),
    target_text: str = Form(..., description="Expected text"),
    language: str = Form(default="grc", description="Language code (grc, lat, etc.)"),
) -> PronunciationScoreResponse:
    """Score pronunciation based on text transcription.

    This endpoint accepts a text transcription (from client-side speech-to-text)
    and compares it to the target text to provide a pronunciation score.

    Args:
        transcription: What the user actually said (transcribed by client)
        target_text: What they should have said
        language: Language code for language-specific scoring

    Returns:
        PronunciationScoreResponse with accuracy score and feedback

    Example:
        POST /api/v1/pronunciation/score-text
        transcription="χρυσός"
        target_text="χρυσός"
        language="grc"
        -> Returns: {accuracy_score: 1.0, is_correct: true, feedback: "Perfect!"}
    """
    if not transcription or not target_text:
        raise HTTPException(status_code=400, detail="Both transcription and target_text are required")

    # Normalize texts (lowercase, strip whitespace)
    transcription_norm = transcription.strip().lower()
    target_norm = target_text.strip().lower()

    # Calculate accuracy using Levenshtein distance
    accuracy = _calculate_pronunciation_accuracy(transcription_norm, target_norm)

    # Generate feedback based on accuracy
    feedback = _generate_feedback(accuracy, transcription_norm, target_norm)

    return PronunciationScoreResponse(
        accuracy_score=accuracy,
        transcription=transcription,
        target_text=target_text,
        feedback=feedback,
        is_correct=accuracy >= 0.7,  # 70% threshold for "correct"
    )


@router.post("/score-audio", response_model=PronunciationScoreResponse)
async def score_pronunciation_audio(
    audio: UploadFile = File(..., description="Audio file (WAV, MP3, M4A, etc.)"),
    target_text: str = Form(..., description="Expected text"),
    language: str = Form(default="grc", description="Language code (grc, lat, etc.)"),
) -> PronunciationScoreResponse:
    """Score pronunciation from audio file.

    NOTE: This endpoint is a placeholder for future Whisper API integration.
    Currently returns a mock response. To use real pronunciation scoring,
    use /score-text with client-side speech-to-text.

    Future implementation will:
    1. Accept audio file upload
    2. Transcribe using OpenAI Whisper API
    3. Score pronunciation accuracy using GOP algorithm
    4. Return detailed phoneme-level feedback

    Args:
        audio: Audio file from user's microphone recording
        target_text: What they should have said
        language: Language code for language-specific scoring

    Returns:
        PronunciationScoreResponse with accuracy score and feedback
    """
    # TODO: Implement Whisper API integration
    # For now, return a placeholder response
    logger.warning(
        f"Audio pronunciation scoring not yet implemented. "
        f"Received audio: {audio.filename}, target: {target_text}, language: {language}"
    )

    return PronunciationScoreResponse(
        accuracy_score=0.85,  # Mock score
        transcription="[Audio transcription not yet implemented]",
        target_text=target_text,
        feedback="Great effort! Audio-based pronunciation scoring coming soon. "
        "For now, we're marking this as correct to encourage practice.",
        is_correct=True,
    )


def _calculate_pronunciation_accuracy(transcription: str, target: str) -> float:
    """Calculate pronunciation accuracy using Levenshtein distance.

    Returns a score between 0.0 and 1.0 where:
    - 1.0 = perfect match
    - 0.0 = completely different

    Uses normalized Levenshtein distance: 1 - (distance / max_length)
    """
    if transcription == target:
        return 1.0

    # Calculate Levenshtein distance
    distance = _levenshtein_distance(transcription, target)

    # Normalize by maximum possible distance (longer string length)
    max_length = max(len(transcription), len(target))
    if max_length == 0:
        return 1.0

    # Convert distance to similarity score (0.0 - 1.0)
    similarity = 1.0 - (distance / max_length)

    # Clamp to [0.0, 1.0]
    return max(0.0, min(1.0, similarity))


def _levenshtein_distance(s1: str, s2: str) -> int:
    """Calculate Levenshtein distance between two strings.

    Dynamic programming implementation with O(n*m) time complexity.
    """
    if len(s1) < len(s2):
        return _levenshtein_distance(s2, s1)

    if len(s2) == 0:
        return len(s1)

    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            # Cost of insertions, deletions, or substitutions
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row

    return previous_row[-1]


def _generate_feedback(accuracy: float, transcription: str, target: str) -> str:
    """Generate human-readable feedback based on pronunciation accuracy."""
    if accuracy >= 0.95:
        return "Perfect pronunciation! Excellent work! 🎉"
    elif accuracy >= 0.85:
        return "Great pronunciation! Just a tiny bit more practice and you'll be perfect."
    elif accuracy >= 0.7:
        return "Good effort! Your pronunciation is understandable. Keep practicing!"
    elif accuracy >= 0.5:
        return "Not quite there yet. Try listening to the audio again and repeat carefully."
    else:
        # Very low score - might be completely wrong word or language
        return (
            f"That doesn't sound right. You said '{transcription}' but the target is '{target}'. "
            f"Listen carefully and try again!"
        )
