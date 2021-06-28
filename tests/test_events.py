import logging
from brownie import Wei, reverts, chain


LOGGER = logging.getLogger(__name__)

AMOUNT = 100e18


def test_deposit_event(accounts, projecttoken, bridge):
    projecttoken.approve(bridge.address, projecttoken.balanceOf(accounts[0]), {'from': accounts[0]})
    tx =  bridge.depositTokens(
        AMOUNT,
        2,
        accounts[0],
        {'from': accounts[0]}
    )

    logging.info(projecttoken.balanceOf(bridge.address))

    assert tx.events["NewDeposit"].values() == (accounts[0], 2, AMOUNT)


def test_withdraw_event(accounts, projecttoken, bridge):

    tx = bridge.claimTokens(
        AMOUNT,
        accounts[1],
        2,
        {'from': accounts[0]}
    )

    assert tx.events["NewWithdraw"].values() == (accounts[1], 2, AMOUNT)
