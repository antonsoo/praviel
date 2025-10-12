from __future__ import annotations

from typing import Any

import pytest

from app.api import search as search_module


class _DummyResult:
    def mappings(self):
        return self

    def all(self):
        return []


class _DummySession:
    async def execute(self, *args, **kwargs):
        return _DummyResult()


class _RowResult:
    def __init__(self, rows):
        self._rows = rows

    def mappings(self):
        return self

    def all(self):
        return self._rows


class _SessionWithRows:
    def __init__(self, rows, recorder=None):
        self._rows = rows
        self.recorder = recorder

    async def execute(self, query, params=None):
        if self.recorder is not None:
            self.recorder.append((query, params))
        if isinstance(query, str):
            return _RowResult(self._rows)
        return _RowResult(self._rows)


async def _invoke_search(**kwargs):
    params = {
        "language": None,
        "types": None,
        "limit": 20,
        "threshold": 0.1,
        "legacy_lang": None,
        "legacy_limit": None,
        "legacy_threshold": None,
    }
    params.update(kwargs)
    return await search_module.search_endpoint(**params)


@pytest.mark.asyncio
async def test_search_endpoint_returns_structured_payload(monkeypatch):
    lex_result = search_module.LexiconResult(
        id=1,
        lemma="μῆνις",
        language="grc",
        part_of_speech="noun",
        short_definition="wrath",
        full_definition="Wrath, anger, especially of the gods",
        forms=["μῆνιν"],
        relevance_score=0.92,
    )
    grammar_result = search_module.GrammarResult(
        id=11,
        title="Accusative of Respect",
        category="syntax",
        language="grc",
        summary="The accusative expresses respect.",
        content="The accusative expresses respect in which the statement is true.",
        tags=["case", "syntax"],
        relevance_score=0.76,
    )
    text_result = search_module.TextResult(
        id=101,
        work_id=7,
        work_title="Iliad",
        author="Homer",
        passage="Μῆνιν ἄειδε θεά Πηληϊάδεω Ἀχιλῆος",
        translation=None,
        line_number=1,
        book="1",
        chapter=None,
        relevance_score=0.88,
    )

    async def fake_search_lexicon(*args, **kwargs):
        return [lex_result]

    async def fake_search_grammar(*args, **kwargs):
        return [grammar_result]

    async def fake_search_text(*args, **kwargs):
        return [text_result]

    monkeypatch.setattr(search_module, "_search_lexicon", fake_search_lexicon)
    monkeypatch.setattr(search_module, "_search_grammar", fake_search_grammar)
    monkeypatch.setattr(search_module, "_search_text_segments", fake_search_text)

    response = await _invoke_search(q="μῆνιν", session=_DummySession())

    assert response.total_results == 3
    assert response.lexicon_results and response.lexicon_results[0].lemma == lex_result.lemma
    assert response.grammar_results and response.grammar_results[0].title == grammar_result.title
    assert response.text_results and response.text_results[0].passage == text_result.passage


@pytest.mark.asyncio
async def test_search_endpoint_skips_unrequested_types(monkeypatch):
    calls = {"lexicon": 0, "grammar": 0, "text": 0}

    async def fake_search_lexicon(*args, **kwargs):
        calls["lexicon"] += 1
        return []

    async def fake_search_grammar(*args, **kwargs):
        calls["grammar"] += 1
        return []

    async def fake_search_text(*args, **kwargs):
        calls["text"] += 1
        return []

    monkeypatch.setattr(search_module, "_search_lexicon", fake_search_lexicon)
    monkeypatch.setattr(search_module, "_search_grammar", fake_search_grammar)
    monkeypatch.setattr(search_module, "_search_text_segments", fake_search_text)

    await _invoke_search(q="λόγος", types="text", session=_DummySession())

    assert calls == {"lexicon": 0, "grammar": 0, "text": 1}


@pytest.mark.asyncio
async def test_search_endpoint_rejects_invalid_type():
    with pytest.raises(search_module.HTTPException) as excinfo:
        await _invoke_search(q="ἀνήρ", types="invalid", session=_DummySession())

    assert excinfo.value.status_code == 400
    assert "Invalid search type" in excinfo.value.detail


@pytest.mark.asyncio
async def test_search_text_segments_includes_translation_and_meta():
    rows = [
        {
            "id": 42,
            "work_id": 7,
            "work_title": "Odyssey",
            "author": "Homer",
            "text_nfc": "ἄνδρα μοι ἔννεπε, Μοῦσα, πολύτροπον",
            "translation": "Tell me, Muse, of the man of many turns",
            "book_meta": "1",
            "chapter_meta": None,
            "line_meta": "line 1",
            "score": 0.91,
            "ref": "1.1",
        }
    ]
    recorder: list[tuple[Any, dict[str, Any] | None]] = []
    session = _SessionWithRows(rows, recorder=recorder)

    results = await search_module._search_text_segments(
        session,
        query_fold="foo",
        language="grc",
        limit=5,
        work_id=77,
    )

    assert len(results) == 1
    entry = results[0]
    assert entry.translation == "Tell me, Muse, of the man of many turns"
    assert entry.book == "1"
    assert entry.chapter is None
    assert entry.line_number == 1
    assert entry.relevance_score == pytest.approx(0.91)
    assert recorder
    _, params = recorder[0]
    assert params is not None
    assert params["work_id"] == 77


@pytest.mark.asyncio
async def test_fetch_works_returns_entries(monkeypatch):
    rows = [
        {"id": 1, "title": "Iliad", "author": "Homer", "language": "grc"},
        {"id": 2, "title": "Odyssey", "author": "Homer", "language": "grc"},
    ]
    session = _SessionWithRows(rows)

    works = await search_module._fetch_works(session=session, language="grc", limit=10)

    assert len(works) == 2
    assert works[0].title == "Iliad"
    assert works[0].language == "grc"


@pytest.mark.asyncio
async def test_search_works_endpoint_uses_helper(monkeypatch):
    async def fake_fetch(session, *, language, limit):
        assert language == "grc"
        assert limit == 5
        return [search_module.WorkResult(id=1, title="Iliad", author="Homer", language="grc")]

    monkeypatch.setattr(search_module, "_fetch_works", fake_fetch)

    result = await search_module.search_works(language="grc", limit=5, session=_DummySession())

    assert len(result) == 1
    assert result[0].author == "Homer"


def test_parse_text_reference_fallback_line_when_ref_missing():
    book, chapter, line_no = search_module._parse_text_reference(
        None,
        fallback_line="line 23",
    )
    assert book is None
    assert chapter is None
    assert line_no == 23
