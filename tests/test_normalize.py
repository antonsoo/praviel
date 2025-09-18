from app.ingestion.normalize import accent_fold, nfc


def test_accent_fold_greek():
    assert accent_fold("Μῆνιν") == "Μηνιν"
    assert nfc("Μῆνιν") == "Μῆνιν"
