import pytest
import logging
from brownie import Wei, reverts, chain

LOGGER = logging.getLogger(__name__)

AMOUNT = 100e18


def test_cross(accounts, projecttoken, bridge):
        with reverts("Cant deposit 0 amount"):
            bridge.depositTokens(
                0,
                1,
                accounts[0],
                {'from': accounts[0]}
            )

        with reverts("Please approve first"):
            bridge.depositTokens(
                AMOUNT,
                1,
                accounts[0],
                {'from': accounts[0]}
            )
        projecttoken.approve(bridge.address, projecttoken.balanceOf(accounts[0]), {'from': accounts[0]})
        bridge.depositTokens(
                AMOUNT,
                1,
                accounts[0],
                {'from': accounts[0]}
            )

        with reverts("Depositing user should be same as msg.sender"):
            bridge.depositTokens(
                AMOUNT,
                1,
                accounts[1],
                {'from': accounts[0]}
            )

        logging.info(projecttoken.balanceOf(bridge.address))

        assert projecttoken.balanceOf(bridge.address) == AMOUNT


def test_withdraw_token(accounts, projecttoken, bridge):
    with reverts("Insufficient balance"):
        bridge.claimTokens(
            AMOUNT+ AMOUNT,
            accounts[2],
            1,
            {'from': accounts[0]}
        )

    with reverts("sender address must be valid address"):
        bridge.claimTokens(
            AMOUNT,
            '0x0000000000000000000000000000000000000000',
            1,
            {'from': accounts[0]}
        )

    with reverts("Ownable: caller is not the owner"):
        bridge.claimTokens(
            AMOUNT + AMOUNT,
            accounts[2],
            1,
            {'from': accounts[1]}
        )


    bridge.claimTokens(
        AMOUNT,
        accounts[2],
        1,
        {'from': accounts[0]}
    )

    logging.info(projecttoken.balanceOf(accounts[2]))


    assert projecttoken.balanceOf(bridge.address) == 0
    assert projecttoken.balanceOf(accounts[2]) == AMOUNT