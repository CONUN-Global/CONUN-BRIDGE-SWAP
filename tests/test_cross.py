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




