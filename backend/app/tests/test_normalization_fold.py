from app.ingestion.normalize import accent_fold, nfc


def test_accent_fold_basic():
    s = "ἀείδω"  # has combining marks
    f = accent_fold(s)
    assert f and f != s
    assert "ἀ" not in f  # folded to base alpha


def test_nfc_idempotent():
    s = "ἄνδρα"
    assert nfc(nfc(s)) == nfc(s)
