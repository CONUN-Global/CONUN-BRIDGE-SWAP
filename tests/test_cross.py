import pytest
import logging
from brownie import Wei, reverts, chain

LOGGER = logging.getLogger(__name__)

LOCKED_AMOUNT = 100e18


def test_cross(accounts, projecttoken, locker):
        with reverts("Please approve first"):
            locker.lockTokens(
                projecttoken.address,
                LOCKED_AMOUNT,
                chain.time() + 100,
                accounts[0],
                {'from': accounts[0]}
            )
        logging.info(accounts[1])
        projecttoken.approve(locker.address, projecttoken.balanceOf(accounts[0]), {'from': accounts[0]})
        locker.lockTokens(
                projecttoken.address,
                LOCKED_AMOUNT,
                chain.time() + 100,
                accounts[1],
                {'from': accounts[0]}
            )


        # with reverts("Please approve first"):
        #     bettoken.burn(accounts[0], 1, {"from":accounts[1]})
        logging.info(projecttoken.balanceOf(locker.address))
        assert projecttoken.balanceOf(locker.address) == LOCKED_AMOUNT




def test_claim(accounts, projecttoken, locker):
    with reverts("You are not allowed to take this token"):
        locker.claimTokens(0, {'from': accounts[0]})



