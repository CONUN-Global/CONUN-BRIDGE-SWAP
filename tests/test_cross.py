import pytest
import logging
from brownie import Wei, reverts, chain

LOGGER = logging.getLogger(__name__)

AMOUNT = 100e18


def test_cross(accounts, projecttoken, bridge):
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



        logging.info(projecttoken.balanceOf(bridge.address))
        # assert projecttoken.balanceOf(locker.address) == AMOUNT




# def test_claim(accounts, projecttoken, locker):
#     with reverts("You are not allowed to take this token"):
#         locker.claimTokens(0, {'from': accounts[0]})
#


