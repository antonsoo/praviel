import logging

from app.core.logging import setup_logging

# Note: We call setup_logging() at the start of each test function
# to ensure the configuration is applied idempotently within the test context.


def test_sensitive_filter_masks_keys_json(caplog):
    setup_logging()
    logger = logging.getLogger("test_security_json")
    with caplog.at_level(logging.INFO):
        logger.info('payload={"openai_api_key":"sk-live-XYZ", "other_data": 123}')

    assert "sk-live-XYZ" not in caplog.text
    # Check for the JSON formatted replacement
    assert '"openai_api_key":"***"' in caplog.text


def test_sensitive_filter_masks_keys_variable(caplog):
    setup_logging()
    logger = logging.getLogger("test_security_var")
    with caplog.at_level(logging.INFO):
        api_key_value = "sk-test-ABC"
        # Test using f-string (direct logging)
        logger.info(f"Attempting connection with anthropic_api_key={api_key_value}")

    assert "sk-test-ABC" not in caplog.text
    # Check for the key=value formatted replacement
    assert 'anthropic_api_key="***"' in caplog.text


def test_sensitive_filter_masks_keys_in_qs(caplog):
    setup_logging()
    logger = logging.getLogger("test_security_qs")
    with caplog.at_level(logging.INFO):
        logger.info("GET /api/resource?foo=1&openai_api_key=sk-123-qs&bar=2")

    assert "sk-123-qs" not in caplog.text
    assert 'openai_api_key="***"' in caplog.text


def test_parameterized_logging(caplog):
    setup_logging()
    logger = logging.getLogger("test_security_param")
    with caplog.at_level(logging.INFO):
        # Test traditional %-style formatting where the key is in the arguments
        # The factory scrubs the arguments before formatting
        logger.info("User %s submitted key: %s", "Alice", "my_api_key=sk-param-123")

    assert "sk-param-123" not in caplog.text
    assert 'my_api_key="***"' in caplog.text
