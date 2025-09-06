from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, Iterator, Tuple

from app.ingestion.normalize import accent_fold, nfc
from lxml import etree

# TEI default namespace
NS = {"tei": "http://www.tei-c.org/ns/1.0"}


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
