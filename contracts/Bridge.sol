
import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/access/Ownable.sol";
import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/token/ERC20/IERC20.sol";
import "OpenZeppelin/openzeppelin-contracts@4.1.0/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BridgeTypes.sol";

pragma solidity ^0.8.2;

contract Bridge is BridgeTypes, Ownable {
    using SafeERC20 for IERC20;

    LockStorageRecord[] lockerStorage;

    address public CON_IERC20;

    // public variables
    uint256 totalBalance;


    // mappings
    mapping(uint256 => mapping(address => uint256)) public withdrawals;
    mapping(uint256 => mapping(address => uint256)) public deposits;

    // events
    event NewDeposit(address indexed user, uint256 indexed amount);
    event NewWithdraw(address indexed user, uint256 indexed amount, uint256 withdrawId);

    function depositTokens(
        uint256 _amount,
        uint256 depositId,
        address user

    )
        external

    {
        require(_amount > 0, "Cant deposit 0 amount");
        require(IERC20(CON_IERC20).allowance(msg.sender, address(this)) >= _amount, "Please approve first");
        require(msg.sender == user, "Depositing user should be same as msg.sender");





        IERC20 token = IERC20(CON_IERC20);
        token.safeTransferFrom(msg.sender, address(this), _amount);

    }




    function getLockRecordByIndex(uint256 _index) external view returns (LockStorageRecord memory){
        return _getLockRecordByIndex(_index);
    }

    function getLockCount() external view returns (uint256) {
        return lockerStorage.length;
    }



    ////////////////////////////////////////////////////////////
    /////////// Only Owner           ////////////////////////////
    ////////////////////////////////////////////////////////////

    function claimTokens(uint256 _amount) external onlyOwner {
        //Lets get our lockRecord by index

        require(_amount <= totalBalance, "Insufficient balance");



        //send tokens
        CON_IERC20.safeTransfer(msg.sender, lock.amount);
    }



    function setConTokenAddress(address conun) external onlyOwner {
        require(conun != address(0), "cant set address to zero");

        CON_IERC20 = conun;
    }



    ////////////////////////////////////////////////////////////
    /////////// Internals           ////////////////////////////
    ////////////////////////////////////////////////////////////



    function _getLockRecordByIndex(uint256 _index) internal view returns (LockStorageRecord memory){
        return lockerStorage[_index];
    }

}
