// SPDX-License-Identifier: MIT

import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/access/Ownable.sol";
import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/token/ERC20/utils/SafeERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/utils/cryptography/ECDSA.sol";
import "./BridgeTypes.sol";

pragma solidity 0.8.2;

contract Bridge is BridgeTypes, Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;



    address public CON_IERC20;

    // mappings
    mapping(bytes32 => BridgeStorage) private history;
    mapping(address => UserInfo) private userInfo;
    mapping(bytes32 => uint256) private IdState;
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


    function getMsgForSign(uint256 _amount, address _to) public pure returns(bytes32) {
        return keccak256(abi.encode(_amount, _to));
    }

    function getLock(bytes memory _key) public pure returns(bytes32) {
        return sha256(_key);
    }

    ////////////////////////////////////////////////////////////
    /////////// Only Owner           ////////////////////////////
    ////////////////////////////////////////////////////////////

    function claimTokens(
        uint256 _amount,
        bytes32  withdrawId,
        bytes32 _msgForSign,
        bytes memory _signature,
        bytes memory _key
    )
        public
    {
        require(_amount <= IERC20(CON_IERC20).balanceOf(address(this)), "Insufficient balance");
        require(IdState[withdrawId] == 0, "Id already exists!");
        address signedBy = _msgForSign.recover(_signature);
        require(trustedSigner[signedBy] == true, "Signature check failed");
        require(withdrawId == getLock(_key), "Key check failed!");
        bytes32 actualMsg = getMsgForSign(
            _amount,
            msg.sender
        );

        require(actualMsg.toEthSignedMessageHash() == _msgForSign, "Integrity check failed");

        history[withdrawId] =BridgeStorage({
            user: msg.sender,
            amount: _amount,
            action: Types.WITHDRAW});
        IdState[withdrawId] = 1;
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

    function withdraw(uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(CON_IERC20);
        token.transfer(owner(), _amount);
    }
}
