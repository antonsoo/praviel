from app.ingestion.normalize import accent_fold, nfc


def test_accent_fold_greek():
    folded = accent_fold("Μῆνιν ἄειδε, θεά")
    assert folded == "μηνιν αειδε, θεα"
    assert accent_fold("λόγος") == "λογοσ"
    assert nfc("Μῆνιν") == "Μῆνιν"
