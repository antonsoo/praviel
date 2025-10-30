from __future__ import annotations

from app.retrieval.hybrid import hybrid_search


async def build_context(question: str, *, k: int = 3) -> tuple[list[str], str]:
    query = (question or "").strip()
    if not query:
        return [], ""

    hits = await hybrid_search(query, language="grc-cls", k=max(1, k))
    citations: list[str] = []
    lines: list[str] = []
    for idx, hit in enumerate(hits, start=1):
        ref = hit.get("work_ref") or ""
        text = (hit.get("text_nfc") or hit.get("text_raw") or "").strip()
        if ref:
            citations.append(ref)
            label = f"[{idx}] {ref}: {text}" if text else f"[{idx}] {ref}"
        else:
            label = f"[{idx}] {text}" if text else f"[{idx}]"
        lines.append(label.strip())
    context = "\n".join(line for line in lines if line).strip()
    return citations, context
