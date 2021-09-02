// SPDX-License-Identifier: MIT

import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/access/Ownable.sol";
import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BridgeTypes.sol";

pragma solidity 0.8.2;

library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}
contract Bridge is BridgeTypes, Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;


    address public CON_IERC20;

    // mappings
    mapping(bytes32 => BridgeStorage) private history;
    mapping(address => UserInfo) private userInfo;
    mapping(address => bool)  public trustedSigner;


    // events
    event NewDeposit(address indexed from, bytes32 indexed depositId, uint256 indexed amount);
    event NewWithdraw(address indexed user, bytes32 withdrawId, uint256 indexed amount);

    constructor(
        address _conERC20
    )public {
        CON_IERC20 = _conERC20;
    }

    function depositTokens(
        uint256 _amount,
        bytes32 depositId,
        address user
    )
        external

    {
        require(_amount > 0, "Cant deposit 0 amount");
        require(IERC20(CON_IERC20).allowance(msg.sender, address(this)) >= _amount, "Please approve first");
        require(msg.sender == user, "Depositing user should be same as msg.sender");

        // store amount

        history[depositId] =BridgeStorage({
            user: msg.sender,
            amount: _amount,
            action: Types.DEPOSIT});

        IERC20 token = IERC20(CON_IERC20);
        token.safeTransferFrom(msg.sender, address(this), _amount);

        emit NewDeposit(msg.sender, depositId, _amount);

    }

    function getInfoById(bytes32 _id) external view returns (BridgeStorage memory) {
        return history[_id];
    }

    function getLastBlock(address _user) public view returns(uint256) {
        return userInfo[_user].lastBlock;
    }


    function getMsgForSign(uint256 _amount, uint256 _lastBlockNumber, uint256 _currentBlockNumber, address _to) public pure returns(bytes32) {
        return keccak256(abi.encode(_amount, _lastBlockNumber, _currentBlockNumber, _to));
    }

    ////////////////////////////////////////////////////////////
    /////////// Only Owner           ////////////////////////////
    ////////////////////////////////////////////////////////////

    function claimTokens(
        uint256 _amount,
        bytes32 withdrawId,
        uint256 _lastBlockNumber,
        uint256 _currentBlockNumber,
        bytes32 _msgForSign,
        bytes memory _signature
    )
        public
    {
        require(_currentBlockNumber <= block.number, "currentBlockNumber cannot be larger than the last block");
        require(getLastBlock(msg.sender) == _lastBlockNumber, "lastBlockNumber must be equal to the value in the storage");
        require(_amount <= IERC20(CON_IERC20).balanceOf(address(this)), "Insufficient balance");

        address signedBy = _msgForSign.recover(_signature);
        require(trustedSigner[signedBy] == true, "Signature check failed");

        bytes32 actualMsg = getMsgForSign(
            _amount,
            _lastBlockNumber,
            _currentBlockNumber,
            msg.sender
        );

        require(actualMsg.toEthSignedMessageHash() == _msgForSign, "Integrity check failed");

        userInfo[msg.sender].rewardDebt = userInfo[msg.sender].rewardDebt + _amount;
        userInfo[msg.sender].lastBlock = _currentBlockNumber;
        history[withdrawId] =BridgeStorage({
            user: msg.sender,
            amount: _amount,
            action: Types.WITHDRAW});
        if(_amount > 0) {
             IERC20 token = IERC20(CON_IERC20);
             token.safeTransfer(msg.sender, _amount);
        }
        emit NewWithdraw(msg.sender, withdrawId, _amount);
    }

    function setConTokenAddress(address conun) external onlyOwner {
        require(conun != address(0), "cant set address to zero");

        CON_IERC20 = conun;
    }
    function setTrustedSigner(address _singer, bool _isValid) public onlyOwner {
        trustedSigner[_singer] = _isValid;
    }
}
