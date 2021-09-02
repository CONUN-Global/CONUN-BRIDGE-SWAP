import pytest
import logging
from brownie import Wei, reverts, chain
from web3.auto import w3
from web3 import Web3
from eth_abi import encode_single
from eth_account.messages import encode_defunct

LOGGER = logging.getLogger(__name__)

AMOUNT = 10000000000
PRIVKEY10 = '0x2cdbeadae3122f6b30a67733fd4f0fb6c27ccd85c3c68de97c8ff534c87603c8'



def test_cross(accounts, projecttoken, bridge):
        with reverts("Cant deposit 0 amount"):
            bridge.depositTokens(
                0,
                '1',
                accounts[0],
                {'from': accounts[0]}
            )

        with reverts("Please approve first"):
            bridge.depositTokens(
                AMOUNT,
                '1',
                accounts[0],
                {'from': accounts[0]}
            )
        projecttoken.approve(bridge.address, projecttoken.balanceOf(accounts[0]), {'from': accounts[0]})
        bridge.depositTokens(
                AMOUNT,
                '1',
                accounts[0],
                {'from': accounts[0]}
            )

        with reverts("Depositing user should be same as msg.sender"):
            bridge.depositTokens(
                AMOUNT,
                '1',
                accounts[1],
                {'from': accounts[0]}
            )

        logging.info(projecttoken.balanceOf(bridge.address))

        assert projecttoken.balanceOf(bridge.address) == AMOUNT


def test_withdraw_token(accounts, projecttoken, bridge):
    accounts.add(PRIVKEY10)
    bridge.setTrustedSigner(accounts[10], True, {'from': accounts[0]})
    CHAIN_NO = chain.height
    signed_message = create_signature(AMOUNT, bridge.getLastBlock(accounts[2]), CHAIN_NO, accounts[2].address, PRIVKEY10)
    # signed_message = create_signature(AMOUNT, 0, CHAIN_NO, accounts[2], 'x112', PRIVKEY10)
    # with reverts("Insufficient balance"):
    #     bridge.claimTokens(
    #         AMOUNT + AMOUNT,
    #         accounts[2],
    #         '1',
    #         {'from': accounts[0]}
    #     )
    #
    # with reverts("sender address must be valid address"):
    #     bridge.claimTokens(
    #         AMOUNT,
    #         '0x0000000000000000000000000000000000000000',
    #         '1',
    #         {'from': accounts[0]}
    #     )
    #
    # with reverts("Ownable: caller is not the owner"):
    #     bridge.claimTokens(
    #         AMOUNT + AMOUNT,
    #         accounts[2],
    #         '1',
    #         {'from': accounts[1]}
    #     )
    #

    bridge.claimTokens(
        AMOUNT,
        bytes('0x11', 'utf-8'),
        bridge.getLastBlock(accounts[2]),
        CHAIN_NO,
        signed_message.messageHash,
        signed_message.signature,
        {'from': accounts[2]}
    )

    logging.info(projecttoken.balanceOf(accounts[2]))
    #
    # assert projecttoken.balanceOf(bridge.address) == 0
    #
    # assert projecttoken.balanceOf(accounts[2]) == AMOUNT



def create_signature(balance, lastblock, currentblock, address,privatekey):
    # base_msg = Web3.solidityKeccak(['uint256','uint256', 'uint256', 'uint256', 'address'],
    #                                 [pid, balance, lastblock, currentblock, Web3.toChecksumAddress(address)])

    encoded_msg = encode_single('(uint256,uint256,uint256,address)', (balance, lastblock, currentblock, Web3.toChecksumAddress(address)))
    base_msg = Web3.solidityKeccak(['bytes32'],
                                   [encoded_msg])
    message = encode_defunct(primitive=base_msg)
    signed_message = w3.eth.account.sign_message(message, private_key=privatekey)

    return signed_message
