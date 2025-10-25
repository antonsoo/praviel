from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, Iterator, List, Sequence, Tuple

from app.ingestion.normalize import accent_fold, nfc
from lxml import etree

# TEI default namespace
NS = {"tei": "http://www.tei-c.org/ns/1.0"}


@dataclass(frozen=True)
class PerseusToken:
    """Token extracted from a Perseus-formatted TEI document."""

    surface: str
    surface_nfc: str
    surface_fold: str
    lemma: str | None
    lemma_fold: str | None
    msd: Dict[str, Any]


@dataclass(frozen=True)
class PerseusSegment:
    """A segment (line, section, etc.) with associated tokens."""

    ref: str
    text_raw: str
    text_nfc: str
    text_fold: str
    tokens: List[PerseusToken]
    meta: Dict[str, Any]


def read_tei(path: Path) -> etree._Element:
    """
    Parse a TEI XML file with robust settings (recover from minor errors).
    """
    parser = etree.XMLParser(remove_comments=True, recover=True)
    return etree.parse(str(path), parser).getroot()


def iter_lines_book1(root: etree._Element) -> Iterator[Tuple[str, str, str]]:
    """
    Yield (ref, text_nfc, text_fold) for Book 1 lines in a Perseus TEI.
    We look inside <div type='book' n='1'> for <l> descendants.
    If no explicit book div is found, we fallback to the first 600 <l>.
    """
    # Try the canonical “book 1” path first
    lines = root.xpath("//tei:div[@type='book'][@n='1']//tei:l", namespaces=NS)
    if not lines:
        # Fallback: grab <l> from the whole document; reader v0 only needs a handful.
        lines = root.xpath("//tei:l", namespaces=NS)[:600]

    for i, line_el in enumerate(lines, start=1):
        # ref: prefer @n or xml:id if present; else synthesize
        ref = line_el.get("{http://www.w3.org/XML/1998/namespace}id") or line_el.get("n") or str(i)
        raw = "".join(line_el.itertext()).strip()
        if not raw:
            continue
        tnfc = nfc(raw)
        tfold = accent_fold(tnfc)
        yield ref, tnfc, tfold


def iter_tokens(root: etree._Element) -> Iterator[Tuple[str, str, str | None, str | None, Dict[str, Any]]]:
    """
    Yield token tuples:
      (surface_nfc, surface_fold, lemma_nfc|None, lemma_fold|None, msd_dict)
    Very light TEI handling for v0; we treat @lemma and @ana if present.
    """
    for w in root.xpath("//tei:w", namespaces=NS):
        surface_raw = "".join(w.itertext()).strip()
        if not surface_raw:
            continue
        surface_nfc = nfc(surface_raw)
        surface_fold = accent_fold(surface_nfc)

        lemma = w.get("lemma")
        lemma_nfc = nfc(lemma) if lemma else None
        lemma_fold = accent_fold(lemma_nfc) if lemma_nfc else None

        ana = w.get("ana")  # Perseus sometimes encodes morph tags in @ana
        msd = {"ana": ana} if ana else {}
        yield surface_nfc, surface_fold, lemma_nfc, lemma_fold, msd


def extract_book_line_segments(
    root: etree._Element,
    ref_prefix: str,
    include_books: Sequence[str] | None = None,
) -> Iterator[PerseusSegment]:
    """
    Extract Iliad/Odyssey-style segments (book + line) with token data.

    Args:
        root: Parsed TEI root element.
        ref_prefix: Reference prefix (e.g., "Il", "Od").
        include_books: Optional iterable of book numbers (as strings) to include.
    """
    book_whitelist = set(include_books or [])

    book_divs = root.xpath(
        "//tei:div[@type='book' or @subtype='book' or @subtype='Book']", namespaces=NS
    )
    for book_div in book_divs:
        book_id = book_div.get("n")
        if not book_id:
            continue

        if book_whitelist and book_id not in book_whitelist:
            continue

        for line_el in book_div.xpath(".//tei:l", namespaces=NS):
            line_id = line_el.get("n")
            if not line_id:
                continue

            text_parts = _collect_text_parts(line_el.itertext())
            if not text_parts:
                continue

            tokens = _collect_tokens(line_el)
            segment = _build_segment(
                ref=f"{ref_prefix}.{book_id}.{line_id}",
                text_parts=text_parts,
                tokens=tokens,
                meta={
                    "book": _safe_int(book_id),
                    "line": _safe_int(line_id),
                },
            )

            if segment:
                yield segment


def extract_stephanus_segments(root: etree._Element, prefix: str) -> Iterator[PerseusSegment]:
    """
    Extract Plato-style segments keyed by Stephanus pagination markers.

    Args:
        root: Parsed TEI root element.
        prefix: Reference prefix (e.g., "Apol", "Symp", "Rep").
    """
    milestone_tag = f"{{{NS['tei']}}}milestone"
    word_tag = f"{{{NS['tei']}}}w"
    punct_tag = f"{{{NS['tei']}}}pc"

    for div in root.xpath(".//tei:div[@subtype='section']", namespaces=NS):
        for p_elem in div.xpath(".//tei:p", namespaces=NS):
            current_ref: str | None = None
            text_parts: List[str] = []
            tokens: List[PerseusToken] = []

            for node in p_elem.iter():
                if node.tag == milestone_tag and node.get("unit") == "section" and node.get("resp") == "Stephanus":
                    # Flush previous segment before starting a new one
                    if current_ref and text_parts:
                        segment = _build_segment(
                            ref=f"{prefix}.{current_ref}",
                            text_parts=text_parts,
                            tokens=tokens,
                            meta={"page": current_ref},
                        )
                        if segment:
                            yield segment
                    current_ref = node.get("n")
                    text_parts = []
                    tokens = []
                    continue

                if not current_ref:
                    continue

                if node.tag == word_tag:
                    token = _token_from_word(node)
                    if token:
                        tokens.append(token)
                    word_text = "".join(node.itertext()).strip()
                    if word_text:
                        text_parts.append(word_text)
                elif node.tag == punct_tag:
                    punct = "".join(node.itertext()).strip()
                    if punct:
                        text_parts.append(punct)
                else:
                    if node.text:
                        cleaned = node.text.strip()
                        if cleaned:
                            text_parts.append(cleaned)

                if node.tail:
                    tail = node.tail.strip()
                    if tail:
                        text_parts.append(tail)

            if current_ref and text_parts:
                segment = _build_segment(
                    ref=f"{prefix}.{current_ref}",
                    text_parts=text_parts,
                    tokens=tokens,
                    meta={"page": current_ref},
                )
                if segment:
                    yield segment


def _collect_text_parts(chunks: Iterable[str]) -> List[str]:
    parts: List[str] = []
    for chunk in chunks:
        cleaned = chunk.strip()
        if cleaned:
            parts.append(cleaned)
    return parts


def _collect_tokens(parent: etree._Element) -> List[PerseusToken]:
    tokens: List[PerseusToken] = []
    for word_el in parent.xpath(".//tei:w", namespaces=NS):
        token = _token_from_word(word_el)
        if token:
            tokens.append(token)
    return tokens


def _token_from_word(word_el: etree._Element) -> PerseusToken | None:
    surface_raw = "".join(word_el.itertext()).strip()
    if not surface_raw:
        return None

    surface_nfc = nfc(surface_raw)
    surface_fold = accent_fold(surface_nfc)

    lemma_raw = word_el.get("lemma")
    lemma_nfc = nfc(lemma_raw) if lemma_raw else None
    lemma_fold = accent_fold(lemma_nfc) if lemma_nfc else None

    msd: Dict[str, Any] = {}

    for attr_name, attr_value in word_el.attrib.items():
        key = _short_attr(attr_name)
        if key in {"lemma", "lang"} or attr_value is None:
            continue
        if attr_value:
            msd[key] = attr_value

    ana = word_el.get("ana")
    if ana:
        msd.setdefault("perseus_tag", ana)

    xml_id = word_el.get("{http://www.w3.org/XML/1998/namespace}id")
    if xml_id:
        msd["xml_id"] = xml_id

    return PerseusToken(
        surface=surface_raw,
        surface_nfc=surface_nfc,
        surface_fold=surface_fold,
        lemma=lemma_nfc,
        lemma_fold=lemma_fold,
        msd=msd,
    )


def _build_segment(
    ref: str,
    text_parts: Sequence[str],
    tokens: Sequence[PerseusToken],
    meta: Dict[str, Any] | None = None,
) -> PerseusSegment | None:
    if not text_parts:
        return None

    text_raw = " ".join(text_parts).strip()
    if not text_raw:
        return None

    text_nfc = nfc(text_raw)
    text_fold = accent_fold(text_nfc)

    return PerseusSegment(
        ref=ref,
        text_raw=text_raw,
        text_nfc=text_nfc,
        text_fold=text_fold,
        tokens=list(tokens),
        meta=dict(meta or {}),
    )


def _short_attr(attr: str) -> str:
    if "}" in attr:
        return attr.split("}", 1)[1]
    return attr


def _safe_int(value: str | None) -> int | str | None:
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        return value


__all__ = [
    "PerseusSegment",
    "PerseusToken",
    "extract_book_line_segments",
    "extract_stephanus_segments",
    "iter_lines_book1",
    "iter_tokens",
    "read_tei",
]
