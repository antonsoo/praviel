import hashlib


def deterministic_chunk_id(source_slug: str, kind: str, anchor: str, text_nfc: str) -> str:
    # Stable ID from canonical identifiers + normalized content
    h = hashlib.sha1()
    h.update(f"{source_slug}\x00{kind}\x00{anchor}\x00".encode("utf-8"))
    h.update(text_nfc.encode("utf-8"))
    return h.hexdigest()  # store in meta
