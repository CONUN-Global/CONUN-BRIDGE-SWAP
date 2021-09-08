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
    signed_message = create_signature(AMOUNT, accounts[2].address, PRIVKEY10)
    bridge.claimTokens(
        AMOUNT,
       '0x2d6bf9d05afa7391c859feecc34188b18aeda2f69d496a2005840262597c6159',
        signed_message.messageHash,
        signed_message.signature,
        bytes('73287e3bfe781ca90c1b922c5a6b46c0d31e75d20edd9b68631617f35308871c', 'utf-8'),
        {'from': accounts[2]}
    )
    logging.info(projecttoken.balanceOf(accounts[2]))


def test_sha256_enhancity(accounts, bridge):

    KEY = '73287e3bfe781ca90c1b922c5a6b46c0d31e75d20edd9b68631617f35308871c'

    encoded = bridge.getLock(bytes(KEY, 'utf-8'), {'from': accounts[0]})

    logging.info(encoded)
    logging.info(KEY)


def create_signature(balance,address,privatekey):

    encoded_msg = encode_single('(uint256,address)', (balance, Web3.toChecksumAddress(address)))
    base_msg = Web3.solidityKeccak(['bytes32'],
                                   [encoded_msg])
    message = encode_defunct(primitive=base_msg)
    signed_message = w3.eth.account.sign_message(message, private_key=privatekey)

    return signed_message



