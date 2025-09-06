from pathlib import Path

from app.core.config import settings


def test_settings_data_paths_are_absolute():
    assert Path(settings.DATA_VENDOR_ROOT).is_absolute()
    assert Path(settings.DATA_DERIVED_ROOT).is_absolute()
