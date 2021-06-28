import pytest


@pytest.fixture(scope="module")
def projecttoken(accounts, TokenMock):
    token = accounts[0].deploy(TokenMock, "Dummy Token", "DMT")
    yield token

@pytest.fixture(scope="module")
def bridge(accounts, Bridge, projecttoken):
    bridge = accounts[0].deploy(Bridge)
    bridge.setConTokenAddress(projecttoken.address)
    yield bridge


