from __future__ import annotations

import json
import unicodedata
from collections import Counter
from pathlib import Path

import pytest

# CLTK 2.0.0 removed text_normalization module - normalize directly with unicodedata
# from cltk.alphabet.text_normalization import cltk_normalize
from app.core.config import Settings
from app.ingestion.normalize import accent_fold
from app.lesson import service as lesson_service
from app.lesson.models import LessonGenerateRequest
from app.lesson.providers import CanonicalLine, DailyLine, LessonContext
from app.lesson.providers.echo import EchoLessonProvider

_ARTIFACT_DIR = Path("artifacts")
_ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

_CANONICAL_FIXTURES: tuple[CanonicalLine, ...] = (
    CanonicalLine(ref="Il.1.1", text="Μῆνιν ἄειδε, θεά"),
    CanonicalLine(ref="Il.1.2", text="Πηληϊάδεω Ἀχιλῆος"),
    CanonicalLine(ref="Od.1.1", text="Ἄνδρα μοι ἔννεπε"),
)


def _daily_samples() -> tuple[DailyLine, ...]:
    try:
        universe = lesson_service._load_daily_seed()  # type: ignore[attr-defined]
        if universe:
            return universe
    except Exception:  # pragma: no cover - defensive guard
        pass
    return (
        DailyLine(text="χαῖρε!", en="Greetings!", variants=("χαῖρε!", "χαίρετε!")),
        DailyLine(text="τί ὄνομά σου;", en="What is your name?"),
        DailyLine(text="εὐχαριστῶ", en="Thank you."),
        DailyLine(text="σὺ τί λέγεις;", en="What do you say?"),
    )


def _assert_greek(text: str) -> None:
    normalized = unicodedata.normalize("NFC", text)
    assert normalized == text, "text must be NFC normalized"
    folded = accent_fold(normalized)
    assert folded, "accent fold should retain content"
    stripped = "".join(ch for ch in normalized if ch.isalpha())
    assert stripped, "greek text should include letters"
    for ch in stripped:
        name = unicodedata.name(ch, "")
        assert "GREEK" in name, f"unexpected non-Greek character: {ch!r}"
    # CLTK 2.0.0 removed text_normalization - just verify NFC is consistent
    # cltk_view = cltk_normalize(normalized, compatibility=False)
    # assert unicodedata.normalize("NFC", cltk_view) == normalized


@pytest.mark.asyncio
async def test_lesson_quality_harness() -> None:
    provider = EchoLessonProvider()
    daily_pool = _daily_samples()
    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily", "canon"],
        exercise_types=["alphabet", "match", "cloze", "translate"],
        k_canon=2,
    )

    report: list[dict[str, object]] = []
    for seed in range(12):
        context = LessonContext(
            daily_lines=daily_pool,
            canonical_lines=_CANONICAL_FIXTURES,
            seed=seed,
        )
        response = await provider.generate(
            request=request,
            session=None,
            token=None,
            context=context,
        )
        _validate_tasks(response.tasks)
        report.append(
            {
                "seed": seed,
                "tasks": [task.type for task in response.tasks],
                "notes": response.meta.note,
            }
        )

    (_ARTIFACT_DIR / "lesson_qa_report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


@pytest.mark.asyncio
async def test_lesson_openai_missing_token_falls_back(monkeypatch: pytest.MonkeyPatch) -> None:
    context = LessonContext(
        daily_lines=_daily_samples(),
        canonical_lines=_CANONICAL_FIXTURES,
        seed=42,
    )

    async def _fake_build_context(*_, **__):
        return context

    monkeypatch.setattr(lesson_service, "_build_context", _fake_build_context)

    request = LessonGenerateRequest(
        language="grc",
        profile="beginner",
        sources=["daily", "canon"],
        exercise_types=["alphabet", "match"],
        k_canon=1,
        provider="openai",
    )
    response = await lesson_service.generate_lesson(
        request=request,
        session=None,
        settings=Settings(),
        token=None,
    )
    assert response.meta.provider == "echo"
    assert response.meta.note == "byok_missing_fell_back_to_echo"


def _validate_tasks(tasks):
    assert tasks, "expected non-empty task list"
    match_seen: set[tuple[str, str]] = set()
    for task in tasks:
        if task.type == "alphabet":
            assert task.options and task.answer in task.options
        elif task.type == "match":
            pairs = task.pairs
            assert pairs, "match task requires pairs"
            for pair in pairs:
                key = (pair.native.strip(), pair.en.strip())
                assert key not in match_seen, "duplicate match pair"
                match_seen.add(key)
                _assert_greek(pair.native)
                assert pair.en, "English gloss must be present"
        elif task.type == "cloze":
            assert task.ref, "canonical cloze must include a ref"
            _assert_greek(task.text)
            blanks = task.blanks
            assert blanks, "cloze must contain blanks"
            if task.options:
                counts = Counter(task.options)
                for blank in blanks:
                    _assert_greek(blank.surface)
                    assert counts[blank.surface] == 1, "cloze options must contain each correct token once"
        elif task.type == "translate":
            _assert_greek(task.text)
        else:  # pragma: no cover - future proofing
            raise AssertionError(f"unexpected task type {task.type}")
