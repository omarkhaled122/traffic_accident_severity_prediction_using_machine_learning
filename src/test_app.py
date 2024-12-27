import pytest


@pytest.fixture
def app():
    import app
    return app.app
